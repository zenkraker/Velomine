plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.velomine.velomine"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.velomine.velomine"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Sentry Flutter 10 requires API 26; Flutter's default is 24.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // flutter_appauth's RedirectUriReceiverActivity claims this scheme.
        manifestPlaceholders.putAll(mapOf("appAuthRedirectScheme" to "com.velomine.app"))
    }

    // CI passes the release key through these variables (repository secrets); without them, as on a laptop, the
    // release build is signed with the debug key so `flutter run --release` works.
    val releaseKeystore = System.getenv("VELOMINE_KEYSTORE_PATH")
    signingConfigs {
        if (releaseKeystore != null) {
            create("release") {
                storeFile = file(releaseKeystore)
                storePassword = System.getenv("VELOMINE_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("VELOMINE_KEY_ALIAS")
                keyPassword = System.getenv("VELOMINE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (releaseKeystore != null) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Official AndroidX library: uploads queued rides while the app is not open.
    implementation("androidx.work:work-runtime-ktx:2.10.1")
    // Official Kotlin test library, for the recorder's pure helpers.
    testImplementation(kotlin("test"))
}

flutter {
    source = "../.."
}
