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
        // Patrol: use the Patrol instrumentation runner for E2E UI tests.
        // See https://patrol.leancode.co/getting-started
        // Note: we intentionally do NOT pass clearPackageData=true because it
        // would wipe the user's logged-in Hive cache, forcing re-login each run.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Patrol E2E UI testing requires Android Test Orchestrator for test
    // discovery (the runner talks to the orchestrator to enumerate Dart tests).
    // See https://patrol.leancode.co/getting-started
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
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
    // Required by Patrol's ANDROIDX_TEST_ORCHESTRATOR execution
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

flutter {
    source = "../.."
}
