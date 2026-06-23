import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // El plugin de Google Services debe ir después de los de Android/Kotlin.
    id("com.google.gms.google-services")
    // El plugin de Flutter debe aplicarse al final (también aplica Kotlin).
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciales de firma release (fuera del repo). Si no existe key.properties,
// se firma con la debug key para que `flutter run --release` funcione localmente.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tramites1cero1.centralizacion"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requerido por flutter_local_notifications (APIs de java.time).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Igual al de la app Android actual, para conservar la ficha de Play Store.
        applicationId = "com.tramites1cero1.centralizacion"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // AGP 9 desactiva resValues por defecto; se requiere para `resValue(...)`.
    buildFeatures {
        resValues = true
    }

    flavorDimensions += "app"
    productFlavors {
        create("municipios") {
            dimension = "app"
            applicationId = "com.tramites1cero1.centralizacion"
            resValue("string", "app_name", "Trami App Municipios")
        }
        create("manizales") {
            dimension = "app"
            // ⚠️ Sugerido (confirmar). No desarrollar hasta terminar Centralización.
            applicationId = "com.tramitesapp.manizales"
            resValue("string", "app_name", "Trami App Manizales")
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
