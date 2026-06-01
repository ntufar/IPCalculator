plugins {
    id("com.android.application")
}

android {
    namespace = "com.tufar.IPCalculator"
    compileSdk = 36

    signingConfigs {
        create("release") {
            storeFile = rootProject.file("release.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "CHlfF4YIoQSHzvnz4IEzI1ZO"
            keyAlias = System.getenv("KEY_ALIAS") ?: "stasi-upload"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "CHlfF4YIoQSHzvnz4IEzI1ZO"
        }
    }

    defaultConfig {
        applicationId = "com.tufar.IPCalculator.V2"
        minSdk = 21
        targetSdk = 36
        versionCode = 5
        versionName = "1.1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt")
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-ktx:1.9.3")
}
