plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val fcbAndroidAbiFilter = findProperty("fcbAndroidAbiFilter") as String?
    ?: System.getenv("FCB_ANDROID_ABI_FILTER")
val fcbAndroidAbis = fcbAndroidAbiFilter
    ?.split(",")
    ?.map { it.trim() }
    ?.filter { it.isNotEmpty() }
    ?: emptyList()

android {
    namespace = "com.example.fcb_counter_app"
    compileSdk = flutter.compileSdkVersion
    buildToolsVersion = "36.1.0"
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.fcb_counter_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        if (fcbAndroidAbis.isNotEmpty()) {
            ndk {
                abiFilters.addAll(fcbAndroidAbis)
            }
        }
    }

    if (fcbAndroidAbis.isNotEmpty()) {
        packaging {
            jniLibs {
                val allAndroidAbis = listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
                excludes.addAll(
                    allAndroidAbis
                        .filter { it !in fcbAndroidAbis }
                        .map { "lib/$it/**" },
                )
            }
        }
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

flutter {
    source = "../.."
}
