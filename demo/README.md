# GodotGoogleSignIn Demo

Minimal test project with Sign In / Sign Out buttons wired to `GodotGoogleSignIn`'s three signals. Requires your own OAuth client IDs (no public test client exists for Sign in with Google) — see [Prerequisites](#prerequisites).

## Prerequisites

Build the addon first (from the repo root):

```sh
make build    # iOS/macOS (Sources/GodotGoogleSignIn)
make android  # Android (android/)
```

This copies the built binaries into `demo/addons/GodotGoogleSignIn/bin/`. See the root [README](../README.md#building-from-source) for toolchain requirements.

Then set your own OAuth client IDs in [`main.gd`](main.gd) (`IOS_CLIENT_ID`, `ANDROID_SERVER_CLIENT_ID`) — both come from the same Firebase/Google Cloud project, see [Firebase Console → Authentication → Sign-in method → Google](https://console.firebase.google.com/).

## Run it

`export_presets.cfg` isn't included (it holds your personal Team ID/bundle ID). Copy the template and fill in your own values:

```sh
cp demo/export_presets.cfg.example demo/export_presets.cfg
```

Then in that file:

- **iOS preset:** set `application/app_store_team_id` (your Apple Developer Team ID) and `application/bundle_identifier`. Add your iOS client's reversed client ID as a `CFBundleURLTypes` entry in `application/additional_plist_content` (see the root [README](../README.md#installation)).
- **Android preset:** set `package/unique_name` to your own package ID. `gradle_build/use_gradle_build=true` is already set — required for any `.aar`-based Godot Android plugin to load.

- **macOS (fastest loop):** open `demo/project.godot` in Godot 4.2+ and run the main scene directly from the editor — no export preset needed.
- **iOS:** export/run via the `iOS` preset on a device or simulator through Xcode.
- **Android:** export a debug APK via the `Android` preset and install it (`adb install`).

## What to expect

On launch, the status label shows "GodotGoogleSignIn Initialized" once the plugin resolves (`Engine.get_singleton` on Android, `ClassDB.instantiate` on iOS/macOS) and `configure()` is called. Tap **Sign In** to trigger the platform's Google sign-in UI; the status label reflects success (with a truncated ID token), failure, or cancellation.

If the status label reads "GodotGoogleSignIn not found", the addon didn't build/export correctly for that platform — recheck the prerequisites step.
