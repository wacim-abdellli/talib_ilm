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

fun findPropOrEnv(name: String, envName: String): String? {
    val propVal = (project.findProperty(name) as? String) ?: (project.findProperty(envName) as? String)
    if (!propVal.isNullOrBlank()) return propVal
    val keyFileVal = getKeystoreProperty(name)
    if (!keyFileVal.isNullOrBlank()) return keyFileVal
    val envVal = System.getenv(envName)
    if (!envVal.isNullOrBlank()) return envVal
    return null
}

val storeFileProp = findPropOrEnv("storeFile", "KEYSTORE_PATH")
val storePasswordProp = findPropOrEnv("storePassword", "KEYSTORE_PASSWORD")
val keyAliasProp = findPropOrEnv("keyAlias", "KEY_ALIAS")
val keyPasswordProp = findPropOrEnv("keyPassword", "KEY_PASSWORD")

val isRealReleaseSigningConfigured = !storeFileProp.isNullOrBlank() &&
    !storePasswordProp.isNullOrBlank() &&
    !storePasswordProp!!.contains("PUT_YOUR_KEYSTORE_PASSWORD") &&
    !keyAliasProp.isNullOrBlank() &&
    !keyPasswordProp.isNullOrBlank() &&
    !keyPasswordProp!!.contains("PUT_YOUR_KEYSTORE_PASSWORD")

val isReleaseSigningConfigured = isRealReleaseSigningConfigured
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
            }
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

gradle.taskGraph.whenReady {
    val isReleaseBuildRequested = allTasks.any { task ->
        val name = task.name
        name.contains("Release", ignoreCase = true) && (
            name.startsWith("assemble", ignoreCase = true) ||
            name.startsWith("bundle", ignoreCase = true) ||
            name.startsWith("package", ignoreCase = true)
        )
    }
    if (isReleaseBuildRequested && !isReleaseSigningConfigured) {
        throw GradleException(
            "Release build rejected: production release signing is not configured.\n" +
            "Release builds (AAB, universal APK, or split APKs) must NEVER fall back to debug signing or be published unsigned.\n" +
            "Please configure android/key.properties or environment variables (KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD).\n" +
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
