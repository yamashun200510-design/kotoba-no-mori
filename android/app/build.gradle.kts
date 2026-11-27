plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val testAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val productionAdMobAppId = System.getenv("ADMOB_APP_ID")?.takeIf { it.isNotBlank() }
val releaseRequested = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (releaseRequested && productionAdMobAppId == null) {
    throw GradleException("公開用ビルドには、AdMobコンソールのアプリIDを環境変数 ADMOB_APP_ID に設定してください。テストIDのまま公開できません。")
}

android {
    namespace = "jp.kotobanomori.kotoba_no_mori"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        manifestPlaceholders["adMobAppId"] = productionAdMobAppId ?: testAdMobAppId
        // Unique Application ID for the Amuse工房 developer account.
        applicationId = "jp.amuse.kotobanomori"
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
    }

    buildTypes {
        release {
            // Produce an unsigned artifact until release signing is configured.
            signingConfig = null
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
