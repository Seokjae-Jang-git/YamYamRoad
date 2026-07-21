import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // 플러터 엔진과 네이티브 라이브러리를 연결해주는 핵심 플러구인
    id("dev.flutter.flutter-gradle-plugin")
}

val envProperties = Properties()
// 👈 플러터 프로젝트 루트 디렉토리의 .env 파일을 가리키도록 상위 경로(../.env)로 수정했습니다.
val envFile = rootProject.file("../.env")
if (envFile.exists()) {
    envFile.forEachLine { line ->
        val trimmedLine = line.trim()
        if (trimmedLine.isNotEmpty() && !trimmedLine.startsWith("#") && trimmedLine.contains("=")) {
            val keyVal = trimmedLine.split("=", limit = 2)
            envProperties.setProperty(keyVal[0].trim(), keyVal[1].trim())
        }
    }
}

android {
    namespace = "com.example.yamyam_road"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.yamyam_road"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = envProperties.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}