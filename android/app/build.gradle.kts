import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // 플러터 엔진과 네이티브 라이브러리를 연결해주는 핵심 플러그인
    id("dev.flutter.flutter-gradle-plugin")
}

val envProperties = Properties()
// 플러터 프로젝트 루트 디렉토리의 .env 파일을 가리키도록 상위 경로(../.env) 지정
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
            // 개발용(디버그) 앱 실행 시 식별자 뒤에 .debug를 추가하여 배포용 앱과 분리
            applicationIdSuffix = ".debug"
        }
        release {
            // R8 난독화 및 리소스 제거 기능 비활성화 (Kotlin DSL 정식 속성명)
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}