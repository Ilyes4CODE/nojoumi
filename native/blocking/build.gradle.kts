plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "dz.lunio.blocking"
    compileSdk = 36

    defaultConfig {
        // Android 10, per Art. 13's low-resource device.
        minSdk = 29
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    testOptions {
        unitTests {
            // `BlockDecision` is pure Kotlin with no Android types, so its tests
            // run on the JVM with no device and no Robolectric. That is the whole
            // point of AD-7 keeping the decision separate from the service.
            isReturnDefaultValues = true
        }
    }
}

dependencies {
    testImplementation("junit:junit:4.13.2")
}
