plugins {
    id("com.android.library") version "8.7.3"
    id("org.jetbrains.kotlin.android") version "2.2.0"
}

// The Android exporter strips any .gdextension config declaring
// android_aar_plugin = true from the main project PCK (it expects the AAR
// itself to carry it). Copy the canonical demo copy into this module's own
// assets so it ends up bundled in the .aar and merged into the final APK.
val pluginAssetsDir = layout.buildDirectory.dir("generated/assets/godotGoogleSignInPlugin")

tasks.register<Copy>("copyGdextensionConfigToAssets") {
    from(layout.projectDirectory.file("../demo/addons/GodotGoogleSignIn/godot_google_sign_in.gdextension"))
    into(pluginAssetsDir.map { it.dir("addons/GodotGoogleSignIn") })
}

android {
    namespace = "org.godotengine.plugin.godotgooglesignin"
    compileSdk = 34
    ndkVersion = "28.0.12674087"

    defaultConfig {
        minSdk = 24
        targetSdk = 34

        ndk {
            abiFilters.add("arm64-v8a")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("CMakeLists.txt")
            version = "3.31.1"
        }
    }

    buildTypes {
        debug {
        }
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main") {
            assets.srcDir(pluginAssetsDir)
        }
    }
}

tasks.named("preBuild") {
    dependsOn("copyGdextensionConfigToAssets")
}

dependencies {
    compileOnly("org.godotengine:godot:4.7.1.stable")
    implementation("androidx.credentials:credentials:1.5.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.5.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}

// Copies build outputs into the demo's addon bin/ dir, matching the paths
// referenced by godot_google_sign_in.gdextension and GodotGoogleSignInExportPlugin.gd.
val demoAddonBinDir = layout.projectDirectory.dir("../demo/addons/GodotGoogleSignIn/bin/android")

listOf("debug", "release").forEach { variant ->
    val variantCapitalized = variant.replaceFirstChar { it.uppercase() }

    tasks.register<Copy>("copy${variantCapitalized}AARToDemoAddons") {
        dependsOn("assemble$variantCapitalized")
        from(layout.buildDirectory.file("outputs/aar/GodotGoogleSignIn-$variant.aar"))
        into(demoAddonBinDir.dir(variant))
    }

    tasks.register<Copy>("copy${variantCapitalized}SharedLibs") {
        dependsOn("merge${variantCapitalized}NativeLibs")
        from(layout.buildDirectory.dir("intermediates/merged_native_libs/$variant/merge${variantCapitalized}NativeLibs/out/lib/arm64-v8a")) {
            include("libGodotGoogleSignIn.so")
        }
        into(demoAddonBinDir.dir("$variant/arm64-v8a"))
    }
}

tasks.register("copyToDemoAddons") {
    dependsOn(
        "copyDebugAARToDemoAddons",
        "copyReleaseAARToDemoAddons",
        "copyDebugSharedLibs",
        "copyReleaseSharedLibs",
    )
}
