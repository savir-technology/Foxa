import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { input ->
        localProperties.load(input)
    }
}

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use { input ->
        signingProperties.load(input)
    }
}

val mapboxAccessToken = (
    localProperties.getProperty("MAPBOX_ACCESS_TOKEN")
        ?: System.getenv("MAPBOX_ACCESS_TOKEN")
        ?: localProperties.getProperty("mapbox_access_token")
        ?: ""
    ).trim()

android {
    namespace = "com.alepoo.eats"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.alepoo.eats"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPBOX_ACCESS_TOKEN"] = mapboxAccessToken
    }

    signingConfigs {
        create("release") {
            val storePath = signingProperties.getProperty("storeFile")
            if (!storePath.isNullOrBlank()) {
                storeFile = rootProject.file(storePath)
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core:1.13.1")
    implementation("com.google.firebase:firebase-messaging:23.2.2")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
