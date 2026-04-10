plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.projek_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    aaptOptions {
        noCompress("tflite")
        noCompress("lite")
    }

    compileOptions {
        // Mendukung fitur Java 8 untuk library notifikasi terbaru
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.projek_mobile"
        // MinSdk 26 sudah bagus, cocok untuk alarm exact di Android baru
        minSdk = 26 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Mencegah limit method saat menambahkan banyak library (seperti Notif + AI)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Menggunakan debug config untuk sementara agar bisa di-run ke HP
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Bagian ini sangat penting untuk mendukung fungsi notifikasi di Android lama/baru
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}