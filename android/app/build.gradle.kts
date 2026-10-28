import java.io.FileInputStream
import java.io.InputStreamReader
import java.io.Reader
import java.nio.charset.StandardCharsets
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val customKeyProps = System.getenv("KEY_PROPERTIES_PATH")
val keystorePropertiesFile = when {
    !customKeyProps.isNullOrBlank() -> file(customKeyProps)
    rootProject.file("key.properties").exists() -> rootProject.file("key.properties")
    file("key.properties").exists() -> file("key.properties")
    else -> rootProject.file("key.properties")
}
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    InputStreamReader(FileInputStream(keystorePropertiesFile), StandardCharsets.UTF_8).use { r: Reader ->
        keystoreProperties.load(r)
    }
}

fun getKeystoreProperty(name: String): String? {
    return keystoreProperties.getProperty(name)
        ?: keystoreProperties.getProperty("\uFEFF$name")
        ?: keystoreProperties.entries.firstOrNull { entry ->
            (entry.key as? String)?.trim()?.removePrefix("\uFEFF") == name
        }?.value as? String
}

val envKeystore = System.getenv("KEYSTORE_PATH")
val envStorePassword = System.getenv("KEYSTORE_PASSWORD")
val envKeyAlias = System.getenv("KEY_ALIAS")
val envKeyPassword = System.getenv("KEY_PASSWORD")

val storeFileProp = getKeystoreProperty("storeFile") ?: envKeystore
val storePasswordProp = getKeystoreProperty("storePassword") ?: envStorePassword
val keyAliasProp = getKeystoreProperty("keyAlias") ?: envKeyAlias
val keyPasswordProp = getKeystoreProperty("keyPassword") ?: envKeyPassword

val isReleaseSigningConfigured = !storeFileProp.isNullOrBlank() &&
    !storePasswordProp.isNullOrBlank() &&
    !keyAliasProp.isNullOrBlank() &&
    !keyPasswordProp.isNullOrBlank()

android {
    namespace = "com.talibilm.app"
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

    signingConfigs {
        getByName("debug") {
            enableV1Signing = true
            enableV2Signing = true
        }
        create("release") {
            if (isReleaseSigningConfigured) {
                val rawFile = file(storeFileProp!!)
                val resolvedFile = when {
                    rawFile.isAbsolute -> rawFile
                    file(storeFileProp).exists() -> file(storeFileProp).absoluteFile
                    rootProject.file(storeFileProp).exists() -> rootProject.file(storeFileProp).absoluteFile
                    else -> rootProject.file(storeFileProp).absoluteFile
                }
                storeFile = resolvedFile
                storePassword = storePasswordProp
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    defaultConfig {
        applicationId = "com.talibilm.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            if (isReleaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Refuse silent fallback to debug signing in release mode
                signingConfig = null
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val isReleaseTaskRequested = allTasks.any { task ->
        val name = task.name.lowercase()
        (name.contains("release") || name.contains("bundle") || name.contains("assemble")) &&
            !name.contains("debug") &&
            !name.contains("test") &&
            !name.contains("lint")
    }
    if (isReleaseTaskRequested && !isReleaseSigningConfigured) {
        throw GradleException(
            "Release build rejected: release signing is not configured.\n" +
            "Release builds must NOT be signed with the Android debug certificate for Google Play submission.\n" +
            "Please configure android/key.properties or set KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD.\n" +
            "See android/key.properties.example for setup instructions."
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
