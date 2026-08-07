plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.miproduction.loncengunman"
    // Explicit SDK versions — pinned rather than inherited from Flutter defaults
    // so version bumps are intentional and reviewable.
    //   compileSdk 37: Flutter default (latest platform APIs)
    //   targetSdk 34: Google Play requires 34+ for new apps/updates (Aug 2024);
    //                  35 required by Aug 2025 — bump when ready.
    //   minSdk 21:    Flutter minimum; flutter_local_notifications also requires 21+
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required for flutter_local_notifications (core library desugaring)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.miproduction.loncengunman"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Required for flutter_local_notifications (core library desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
