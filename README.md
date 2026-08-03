# GodotGoogleSignIn

[![Godot](https://img.shields.io/badge/Godot%20Engine-4.2+-blue.svg)](https://github.com/godotengine/godot/)
[![SwiftGodot](https://img.shields.io/badge/SwiftGodot-0.79.0-blue.svg)](https://github.com/migueldeicaza/SwiftGodot/)
![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20Android-333333.svg?style=flat)
![iOS](https://img.shields.io/badge/iOS-17+-green.svg?style=flat)
![macOS](https://img.shields.io/badge/macOS-14+-green.svg?style=flat)
![Android](https://img.shields.io/badge/Android-arm64--v8a-green.svg?style=flat)
[![Swift](https://img.shields.io/badge/Swift-6-blue.svg)](https://www.swift.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)

Native direct Google Sign-In plugin for Godot 4 on iOS, macOS, and Android, built as a v2 GDExtension (Swift + [SwiftGodotRuntime](https://github.com/migueldeicaza/SwiftGodot) on Apple platforms, Kotlin + a native C++ shim on Android). iOS/macOS use the [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) SDK; Android uses Credential Manager / Google Identity Services (`GetSignInWithGoogleOption`) — no deprecated Google Sign-In SDK involved on either platform.

> **Official docs:** [Sign in with Google for iOS](https://developers.google.com/identity/sign-in/ios) · [Sign in with Google for Android (Credential Manager)](https://developer.android.com/identity/sign-in/credential-manager-siwg)

---

## Requirements

- iOS 17.0 / macOS 14.0 / Android 7.0+ (API 24, `arm64-v8a` only)
- Godot 4.2+
- [GodotApplePlugins](https://github.com/zt-pawer/GodotApplePlugins) installed — provides the shared `SwiftGodotRuntime` the plugin links against on iOS/macOS
- Android exports require **`gradle_build/use_gradle_build = true`** in the export preset — required for any `.aar`-based Godot Android plugin to load
- An OAuth 2.0 **web client ID** (for the Android `serverClientId` and Firebase `GoogleAuthProvider` verification) and an **iOS client ID**, both from the same Firebase/Google Cloud project — see [Firebase Console → Authentication → Sign-in method → Google](https://console.firebase.google.com/)

The plugin also ships empty stubs for Linux and Windows so your project compiles on those platforms without errors.

---

## Installation

1. Download the latest release zip from [Releases](https://github.com/zt-pawer/GodotGoogleSignIn/releases)
2. Unzip and copy `addons/GodotGoogleSignIn/` into your Godot project's `addons/`
3. Ensure `addons/GodotApplePluginsRuntime/` is also present (from [GodotApplePlugins](https://github.com/zt-pawer/GodotApplePlugins))
4. Add your iOS client's reversed client ID as a URL scheme to your iOS `Info.plist` (via your export preset's `application/additional_plist_content`):
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</string>
       </array>
     </dict>
   </array>
   ```
5. Forward incoming URLs to the plugin so the sign-in flow can complete — call `handleOpenURL(url)` from wherever your project already handles custom URL schemes (e.g. Firebase Dynamic Links, deep links)

---

## API

`GodotGoogleSignIn` is reached differently per platform: on **Android** it's an Engine singleton (`Engine.get_singleton("GodotGoogleSignIn")`, the standard v2 Kotlin `GodotPlugin` mechanism); on **iOS/macOS** it's a `RefCounted` class registered via `SwiftGodotRuntime` (`ClassDB.instantiate("GodotGoogleSignIn")`).

### `GodotGoogleSignIn`

#### Quick start

```gdscript
extends Node

var _google_signin: Object

func _ready() -> void:
    if OS.get_name() == "Android":
        if not Engine.has_singleton("GodotGoogleSignIn"):
            return
        _google_signin = Engine.get_singleton("GodotGoogleSignIn")
    elif ClassDB.class_exists("GodotGoogleSignIn"):
        _google_signin = ClassDB.instantiate("GodotGoogleSignIn")
    else:
        return

    _google_signin.google_sign_in_success.connect(_on_success)
    _google_signin.google_sign_in_failed.connect(_on_failed)
    _google_signin.google_sign_in_cancelled.connect(_on_cancelled)

    var client_id := "YOUR_SERVER_CLIENT_ID" if OS.get_name() == "Android" else "YOUR_IOS_CLIENT_ID"
    _google_signin.configure(client_id)

func _on_sign_in_pressed() -> void:
    _google_signin.signIn()

func _on_success(id_token: String, access_token: String) -> void:
    print("Signed in. idToken: ", id_token)
    # access_token is empty on Android — Credential Manager only yields an ID token.

func _on_failed(error: String) -> void:
    print("Sign-in failed: ", error)

func _on_cancelled() -> void:
    print("Sign-in cancelled by user")
```

---

#### Signals

| Signal | Arguments | Description |
|--------|-----------|-------------|
| `google_sign_in_success` | `idToken: String, accessToken: String` | Sign-in succeeded. `accessToken` is always empty on Android |
| `google_sign_in_failed` | `error: String` | Sign-in failed (not a user cancellation) |
| `google_sign_in_cancelled` | — | User dismissed the sign-in sheet |

---

#### Methods

| Method | Description |
|--------|-------------|
| `configure(clientId: String)` | Must be called before `signIn()`. iOS: your OAuth **iOS** client ID. Android: your OAuth **web** client ID (the `serverClientId` Credential Manager verifies against) |
| `signIn()` | Present the platform's Google sign-in UI |
| `signOut()` | Clear the local sign-in state |
| `handleOpenURL(urlString: String)` | iOS only — forward incoming URLs so the sign-in flow can complete. No-op on Android |

---

## Building from Source

### iOS / macOS

Requires Xcode on macOS. Before building, open the package in Xcode and share the scheme (**Product → Manage Schemes → Shared**) so `xcodebuild` can find it.

```bash
make build
make dist
```

`make build` compiles xcframeworks for iOS, iOS Simulator, and macOS. `make dist` assembles the `addons/` folder ready to drop into your Godot project.

### Android

Requires the Android SDK (`ANDROID_HOME` set), NDK `28.0.12674087`, CMake `3.31.1`, and the `godot-cpp` submodule (`git submodule update --init godot-cpp`).

```bash
make android
```

This builds `godot-cpp` for `arm64-v8a` (debug + release) via scons, builds the native shim + Kotlin `GodotPlugin` via Gradle/CMake (`android/`), and copies the resulting `.aar`/`.so` files into both `addons/GodotGoogleSignIn/bin/android/` and `demo/addons/GodotGoogleSignIn/bin/android/`.

---

## Demo

See [`demo/README.md`](demo/README.md) for how to build and run the test project (iOS/macOS/Android).

---

## SwiftGodot Version

This plugin is pinned to SwiftGodot `0.79.0`.

---

## Contributing

Have a bug fix or feature request? Contributions are welcome!

[How to contribute](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project)

---

## Donate and support

[![Buy me a coffee](.github/bmc-button.png)](https://buymeacoffee.com/ztpawer)

[![Become a patreon](.github/patreon-button.png)](https://patreon.com/ztpawer)

---

## Games using it

[![Pang in Time](.github/pit.webp)](https://apps.apple.com/us/app/pang-in-time/id6499503406)

[![Jupiter Escape](.github/je.webp)](https://apps.apple.com/us/app/jupiter-escape/id6476010007)

---

## License

MIT — see [LICENSE](LICENSE)
