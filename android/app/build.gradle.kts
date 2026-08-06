import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // 플러터 엔진과 네이티브 라이브러리를 연결해주는 핵심 플러그인
    id("dev.flutter.flutter-gradle-plugin")
    // 🌟 1. 파이어베이스 구글 서비스 플러그인을 Kotlin DSL 문법으로 올바르게 추가합니다.
    id("com.google.gms.google-services")
}

val envProperties = Properties()
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
        manifestPlaceholders["ADMOB_APP_ID"] = envProperties.getProperty("ADMOB_APP_ID", "")
        manifestPlaceholders["KAKAO_APP_KEY"] = envProperties.getProperty("KAKAO_APP_KEY", "")
        manifestPlaceholders["KAKAO_SCHEME"] = envProperties.getProperty("KAKAO_SCHEME", "")
        manifestPlaceholders["NAVER_CLIENT_ID"] = envProperties.getProperty("NAVER_CLIENT_ID", "")
        manifestPlaceholders["NAVER_CLIENT_SECRET"] = envProperties.getProperty("NAVER_CLIENT_SECRET", "")
        manifestPlaceholders["NAVER_CLIENT_NAME"] = envProperties.getProperty("NAVER_CLIENT_NAME", "")
    }

    buildTypes {
        debug {
            // applicationIdSuffix = ".debug"  👈 이 줄을 삭제하거나 주석 처리하세요.
        }
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}
// ❌ 기존 파일 맨 아래에 있던 잘못된 Groovy 방식의 apply 문법은 삭제했습니다.