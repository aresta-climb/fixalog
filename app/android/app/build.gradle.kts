import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.arestaclimb.fixalog"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.arestaclimb.fixalog"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val signKeyAlias = System.getenv("KEY_ALIAS") ?: keystoreProperties["keyAlias"] as String?
            val signKeyPassword = System.getenv("KEY_PASSWORD") ?: keystoreProperties["keyPassword"] as String?
            val signStoreFile = System.getenv("STORE_FILE")?.let { file(it) } ?: keystoreProperties["storeFile"]?.let { rootProject.file(it as String) }
            val signStorePassword = System.getenv("STORE_PASSWORD") ?: keystoreProperties["storePassword"] as String?

            keyAlias = signKeyAlias
            keyPassword = signKeyPassword
            storeFile = signStoreFile
            storePassword = signStorePassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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

