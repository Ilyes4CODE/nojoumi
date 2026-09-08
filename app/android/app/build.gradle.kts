plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dz.lunio"
    // Play requires new submissions to target API 36 (verified 2026-08-14, see
    // docs/android-behaviour-notes.md V1).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications, which uses java.time APIs that
        // do not exist below API 26 — our floor is 29, but the plugin's own
        // dependencies reach lower and the AAR metadata check enforces it.
        // Verified 2026-08-21 against the plugin's README, which specifies
        // desugar_jdk_libs 2.1.4 and AGP 8.11.1 as the minimum; settings.gradle.kts
        // pins AGP at exactly 8.11.1.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Permanent from the first Play upload onward — a different id is a
        // different app, with no installs and no reviews (decisions.md D-36).
        applicationId = "dz.lunio"
        // Android 10, per Art. 13's low-resource test device (2 GB RAM).
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Still the debug keys. Article 15.4 and Article 19 make a **signed**
            // AAB a deliverable, and the keystore is handed to the client
            // directly — it is never committed, and a leaked upload key cannot be
            // rotated on Play. Replace this before the first release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(project(":blocking"))
}

flutter {
    source = "../.."
}
