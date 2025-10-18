plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.omeeowash"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true // ✅ enable desugaring
    }

    kotlinOptions { jvmTarget = "17" }

    defaultConfig {
        applicationId = "com.omeeowash"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release { signingConfig = signingConfigs.getByName("debug") }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ use newer version (2.1.4 or higher)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
