import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The release keystore, read from `android/key.properties`.
//
// **Neither file is in the repository** and neither ever may be: a leaked upload
// key cannot be rotated on Google Play, and losing it means the app can never be
// updated again under the same listing. Article 15.4 and Article 19 make a
// signed build a deliverable, so the keystore is handed to the client directly.
//
// Absent, the build falls back to the debug keys and says so — a developer
// without the keystore can still build and run, they simply cannot produce
// something installable by anyone else.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
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

    signingConfigs {
        create("release") {
            val storeFileName = keystoreProperties.getProperty("storeFile")
            if (storeFileName != null) {
                storeFile = rootProject.file(storeFileName)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")

                // **All three schemes.** v2 alone is enough for our minSdk of 29
                // and is what the build produced before — and a build signed
                // that way was refused by an Android 14 phone with nothing but
                // "App not installed" (2026-09-09). v1 costs a few kilobytes and
                // removes a whole class of installer disagreement; v3 is what
                // allows the key to be rotated later without breaking updates.
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                // Loud rather than silent: a release build signed with debug keys
                // installs on the machine that made it and is refused or
                // distrusted almost everywhere else.
                logger.warn("WARNING: android/key.properties is missing — signing the release with DEBUG keys")
                signingConfigs.getByName("debug")
            }
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
