plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun env(name: String) = System.getenv(name)?.takeIf { it.isNotBlank() }

val testAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val productionAdMobAppId = env("ADMOB_APP_ID")
// Explicit opt-in for an ad-free test build (e.g. the first closed test).
// The Dart side requests no ads in release without ADMOB_REWARDED_ANDROID_ID,
// so the sample app ID only satisfies the SDK manifest check.
val releaseWithoutAds = env("KOTOBA_RELEASE_WITHOUT_ADS") == "true"
val releaseRequested = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (releaseRequested && productionAdMobAppId == null && !releaseWithoutAds) {
    throw GradleException("公開用ビルドには、AdMobコンソールのアプリIDを環境変数 ADMOB_APP_ID に設定してください。広告なしのテスト版を作るときだけ KOTOBA_RELEASE_WITHOUT_ADS=true を指定します。")
}

// Upload-key signing. Nothing secret is stored in the repository: the keystore
// path and passwords come from environment variables at build time.
val uploadStoreFile = env("KOTOBA_UPLOAD_STORE_FILE")
val uploadStorePassword = env("KOTOBA_UPLOAD_STORE_PASSWORD")
val uploadKeyAlias = env("KOTOBA_UPLOAD_KEY_ALIAS") ?: "upload"
val uploadKeyPassword = env("KOTOBA_UPLOAD_KEY_PASSWORD") ?: uploadStorePassword
val uploadSigningReady = uploadStoreFile != null && uploadStorePassword != null
if (releaseRequested && !uploadSigningReady) {
    throw GradleException("公開用ビルドには署名が必要です。環境変数 KOTOBA_UPLOAD_STORE_FILE（キーストアの場所）と KOTOBA_UPLOAD_STORE_PASSWORD を設定してください。")
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

    signingConfigs {
        create("upload") {
            if (uploadSigningReady) {
                storeFile = file(uploadStoreFile!!)
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Signed with the upload key; Play App Signing re-signs for users.
            signingConfig = if (uploadSigningReady) signingConfigs.getByName("upload") else null
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
