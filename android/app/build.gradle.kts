plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun localProperties(): java.util.Properties {
    val properties = java.util.Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        properties.load(java.io.FileInputStream(localPropertiesFile))
    }
    return properties
}

val flutterVersionCode: String by localProperties()
val flutterVersionName: String by localProperties()

android {
    namespace = "com.example.best_flutter_ui_templates"
    compileSdk = 34
    ndkVersion = "25.1.8937393" // تحديد إصدار ثابت ومستقر

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets["main"].java.srcDirs("src/main/kotlin")

    defaultConfig {
        applicationId = "com.example.best_flutter_ui_templates"
        minSdk = 21
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            isSigningReady = false // تعطيل فحص التوقيع في GitHub Actions
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    //
}
