import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// --- Load keystore (optional) ---
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    buildToolsVersion = "34.0.0"
    namespace = "com.todolist.to_dolist"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        // ✅ สร้าง release เฉพาะตอน key.properties มีค่าครบ (กัน debug build พัง)
        if (keystorePropertiesFile.exists()) {
            val keyAliasVal = keystoreProperties["keyAlias"] as String?
            val keyPasswordVal = keystoreProperties["keyPassword"] as String?
            val storeFileVal = keystoreProperties["storeFile"] as String?
            val storePasswordVal = keystoreProperties["storePassword"] as String?

            if (!keyAliasVal.isNullOrBlank()
                && !keyPasswordVal.isNullOrBlank()
                && !storeFileVal.isNullOrBlank()
                && !storePasswordVal.isNullOrBlank()
            ) {
                create("release") {
                    keyAlias = keyAliasVal
                    keyPassword = keyPasswordVal
                    storeFile = file(storeFileVal)
                    storePassword = storePasswordVal
                }
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.todolist.to_dolist"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ✅ ถ้ามี release signing ก็ใช้ ถ้าไม่มีก็ fallback ไป debug (กัน build พัง)
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
