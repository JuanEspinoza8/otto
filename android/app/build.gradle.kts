import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release: android/key.properties (fuera de git) apunta al keystore.
// Ver "Firma del APK" en el README.
val archivoFirma = rootProject.file("key.properties")
val firma = Properties().apply {
    if (archivoFirma.exists()) FileInputStream(archivoFirma).use { load(it) }
}

android {
    namespace = "io.github.juanespinoza8.otto"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "io.github.juanespinoza8.otto"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (archivoFirma.exists()) {
                keyAlias = firma.getProperty("keyAlias")
                keyPassword = firma.getProperty("keyPassword")
                storeFile = file(firma.getProperty("storeFile"))
                storePassword = firma.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Un release firmado con la clave debug no se puede actualizar desde otra
// PC: si falta el keystore, el build de release falla en vez de firmar mal.
tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }.configureEach {
    doFirst {
        if (!archivoFirma.exists()) {
            throw GradleException("Falta android/key.properties para firmar el release (ver README).")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
