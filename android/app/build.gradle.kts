import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.tasks.Copy

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
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
        ndk {
            abiFilters.add("arm64-v8a")
        }
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

android.applicationVariants.all {
    val variantName = name
    val variantTaskName = "package${variantName.replaceFirstChar { it.uppercase() }}"
    val flutterProjectRoot = rootProject.projectDir.parentFile
    val variantFlavor = flavorName
    val variantBuildType = buildType.name
    val sourceFileName = if (variantFlavor.isNullOrEmpty()) {
        "app-${variantBuildType}.apk"
    } else {
        "app-${variantFlavor}-${variantBuildType}.apk"
    }
    val sourceFile = File(projectDir, "build/outputs/apk/${if (variantFlavor.isNullOrEmpty()) "" else "$variantFlavor/"}${variantBuildType}/${sourceFileName}")
    val targetDir = File(flutterProjectRoot, "build/app/outputs/flutter-apk")

    tasks.register<Copy>("copy${variantName.replaceFirstChar { it.uppercase() }}FlutterApk") {
        dependsOn(variantTaskName)
        from(sourceFile)
        into(targetDir)
        rename { sourceFileName }
        doFirst {
            if (!sourceFile.exists()) {
                throw GradleException("No se encontró el APK generado en ${sourceFile}")
            }
        }
    }

    tasks.named(variantTaskName) {
        finalizedBy("copy${variantName.replaceFirstChar { it.uppercase() }}FlutterApk")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

googleServices {
    missingGoogleServicesStrategy = com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy.IGNORE
}
