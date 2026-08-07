import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // 플러터 엔진과 네이티브 라이브러리를 연결해주는 핵심 플러그인
    id("dev.flutter.flutter-gradle-plugin")
    // 파이어베이스 구글 서비스 플러그인
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

    // 🔑 Release Keystore 서명 설정 추가
    signingConfigs {
        create("release") {
            val keystoreFile = System.getenv("KEYSTORE_FILE")
            if (!keystoreFile.isNullOrEmpty()) {
                storeFile = file(keystoreFile)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        debug {
            // USB 디버그 빌드 시 패키지명 뒤에 .debug를 붙여 릴리즈 앱과 완전 분리
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "얌얌로드 (Debug)"
        }
        release {
            val keystoreFile = System.getenv("KEYSTORE_FILE")
            // GitHub Actions 가상 환경일 때 릴리즈 키 적용, 내 PC 로컬일 때 디버그 키 적용
            signingConfig = if (!keystoreFile.isNullOrEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}