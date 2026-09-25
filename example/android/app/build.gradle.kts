plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val sdkVersion = 37
val javaVersion = JavaVersion.VERSION_17

android {
    namespace = "com.f2fk.geofence_foreground_service_example"
    compileSdk = sdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = javaVersion
        targetCompatibility = javaVersion
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.f2fk.geofence_foreground_service_example"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = 29
        targetSdk = sdkVersion
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

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    implementation("androidx.multidex:multidex:2.0.1")
}
