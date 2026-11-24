plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Base64
import java.util.Properties

/**
 * Release signing: android/key.properties (local) or the ANDROID_KEYSTORE_* environment variables
 * (CI). Without either, the release build is signed with the debug key so it still builds.
 * Keep the same keystore forever: phones only accept updates signed with the same key.
 */
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
fun signingValue(property: String, env: String): String? =
    keystoreProperties.getProperty(property) ?: System.getenv(env)?.takeIf { it.isNotBlank() }
val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")

/** MAPS_API_KEY de `--dart-define`: Flutter pasa la lista como `dart-defines`, cada entrada en base64. */
fun mapsKeyFromDartDefines(): String? =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { entry -> runCatching { String(Base64.getDecoder().decode(entry)) }.getOrNull() }
        ?.firstOrNull { it.startsWith("MAPS_API_KEY=") }
        ?.substringAfter("=")

/**
 * Clave de cliente de Google Maps (restringida a la app Android), en este orden: propiedad de
 * Gradle MAPS_API_KEY, android/local.properties o `--dart-define=MAPS_API_KEY`.
 */
val mapsApiKey: String = listOf(
    project.findProperty("MAPS_API_KEY") as String?,
    Properties().apply {
        val file = rootProject.file("local.properties")
        if (file.exists()) file.inputStream().use { load(it) }
    }.getProperty("MAPS_API_KEY"),
    mapsKeyFromDartDefines(),
).firstOrNull { !it.isNullOrBlank() } ?: ""

if (mapsApiKey.isBlank()) {
    logger.warn(
        "MAPS_API_KEY no está configurada para Android: el mapa de Google se verá vacío. " +
            "Ponla en android/local.properties o pásala con --dart-define=MAPS_API_KEY.",
    )
}

android {
    namespace = "com.example.farma_go"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.farma_go"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = file(releaseStoreFile)
                storePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseStoreFile != null) {
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
