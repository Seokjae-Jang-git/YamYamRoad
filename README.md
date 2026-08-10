# 🍰 YamYamRoad (얌얌로드) - 위치 기반 디저트 순례 & 게이미피케이션 플랫폼
![YamYamRoad Header](https://capsule-render.vercel.app/api?type=shark&height=300&color=gradient&text=YamYam%20Road&animation=scaleIn)

## 📚 목차
1. [프로젝트 소개](#intro)
2. [주요 기능](#features)
3. [개발 기간](#period)
4. [팀원 구성](#members)
5. [사용 기술](#tech)
6. [역할 분담](#roles)
7. [발표 PPT & 자료](#resources)

---

## <a name="intro"></a>🔍 프로젝트 소개 (Project Introduction)

### **"모바일 앱과 함께하는 스마트한 디저트 핫플레이스 탐색 & 순례 플랫폼, YamYamRoad"**

YamYamRoad(얌얌로드)는 성수동, 가로수길, 해리단길 등 급증하는 디저트 핫플레이스 수요에 발맞추어, **위치 기반(GPS) 디저트 탐방 코스 제공 및 영수증 OCR 인증을 통한 스탬프·뱃지·포인트 수집**을 결합한 디저트 순례 하이브리드 앱 서비스입니다.

영수증 OCR 알고리즘과 GPS 어뷰징 방지 로직을 결합하여 가짜 리뷰와 부정 인증을 차단하고, 디저트 탐방에 게이미피케이션(Gamification) 요소를 더해 사용자의 지속적인 방문과 기록을 유도합니다.

---

### 📌 핵심 비즈니스 모델 및 차별성 (Business Core Value)

* 📍 **위치 기반 디저트 탐방 로드(코스) 제공**
  * 위치 권한 기반 사용자의 현재 좌표 및 Geohash 정밀 스캔을 활용해 근처 제휴 매장과 최적의 디저트 탐방 코스를 추천합니다.
* 🧾 **영수증 OCR + GPS 교차 검증 스탬프 인증**
  * 카메라 촬영 영수증의 상호명·일시·금액 OCR 분석과 실시간 GPS 거리 및 어뷰징(루팅, 이동 속도) 검사를 결합하여 100% 신뢰 가능한 방문 인증 생태계를 구축합니다.
* 🏅 **게이미피케이션 기반 유저 락인(Lock-in)**
  * 스탬프 수집 달성도(주간/월간/연간) 및 로드 진척도에 따른 뱃지 발급, 커뮤니티(얌얌북) 대표 뱃지 노출, 포인트 충전 및 기프티콘/이모티콘 교환으로 유저 재방문을 극대화합니다.
* 🤖 **AI 맞춤 추천 & 보상형 광고 생태계**
  * 사용자 위치 및 이전 방문 기록을 분석한 AI 맞춤 매장 추천과 구글 애드몹/자체 제휴 보상형 광고를 연동해 무료 포인트 충전 및 비즈니스 수익 모델을 완성합니다.

---

### <a name="features"></a>🛠️ 주요 기능 (Key Features)

#### 1. 회원 및 소셜 서비스 (Auth & Social)
* 📱 **다양한 인증 및 소셜 로그인**
  * 카카오, 네이버, 구글 OAuth 소셜 로그인 및 휴대폰 번호 SMS 인증 로그인을 지원합니다.
  * 회원 탈퇴 후 30일 이내 재로그인 시 계정 복구 처리 팝업 및 유예 기간 관리 기능을 제공합니다.
* 👤 **통합 마이페이지 & 활동 기록**
  * 다이어리, 얌얌북(커뮤니티) 작성글, 스탬프/뱃지 보유 현황, 포인트 상세 내역, 1:1 문의 및 신고 처리 현황을 한눈에 조회합니다.

#### 2. 위치 기반 얌얌로드 & 지도 서비스 (Location & Maps)
* 🗺️ **Google Maps API 연동 & 위치 탐색**
  * 제휴 스탬프 매장을 지오해시(Geohash) 핀포인트로 스캔하고 지도 상에 마커로 표시합니다.
  * 네이버 지도 길찾기 외부 링크 연동으로 개발 공수를 줄이고 사용자에게 최적의 길안내 기능을 제공합니다.
* 🍰 **지역별·메뉴별 디저트 코스(로드)**
  * 지역 및 디저트 카테고리별 탐방 로드 리스트를 제공하며 로드(코스) 내 업체 평점과 거리를 확인합니다.

#### 3. 영수증 OCR 인증 & 게이미피케이션 (OCR & Gamification)
* 🧾 **스마트 영수증 인증 시스템**
  * 영수증 사진 촬영 시 OCR을 통해 상호명, 결제 일시, 금액을 자동 추출하고 업체 정보 및 GPS 거리를 자동 교차 검증하여 스탬프를 발행합니다.
  * 중복 영수증, 6시간 초과 영수증, GPS 조작 및 어뷰징을 자동 차단합니다.
* 🏅 **스탬프 & 뱃지 리워드**
  * 로드 완주율 및 주간/월간/연간 스탬프 달성도에 따라 브론즈, 실버, 골드, 챔피언 뱃지를 수여하며 커뮤니티 대표 뱃지로 지정 가능합니다.

#### 4. 포인트 결제 & 커뮤니티 & AI 추천 (Commerce & AI)
* 💳 **포인트 충전 & 쇼핑몰**
  * PortOne 결제 모듈 연동을 통한 포인트 충전, 이모티콘 팩 구매, 기프티콘 교환 시스템을 제공합니다.
* 📖 **얌얌북 커뮤니티 & 자체 이모티콘**
  * 커뮤니티 피드 작성/수정/삭제(Soft Delete), 댓글/답글, 좋아요, 태그 검색, 신고 기능과 함께 직접 제작한 이모티콘 토큰 변환/드래그 순서 변경 기능을 제공합니다.
* 🤖 **AI 추천 & 보상형 무료 포인트 충전소**
  * 사용자 위치와 방문 기록 기반 AI 맞춤 매장/코스 추천을 제공합니다.
  * 구글 애드몹(AdMob) 보상형 영상/전면 광고 및 자체 브랜드 제휴 광고 시청 시 무료 포인트를 지급합니다.

#### 5. 관리자 웹 시스템 (Admin Center)
* 🖥️ **Vue.js 기반 백오피스**
  * 앱과 분리된 독립 웹 로그인 환경을 제공하며 회원 상태 관리, 커뮤니티 게시글 검수, 1:1 문의 답변, 신고 접수 및 반려/처리 기능을 지원합니다.

---

## <a name="period"></a>🗓 개발 기간
- **2026.07.06 ~ 2026.07.13 (6일)** : 기능 정의, DB 설계, 화면 설계 (Figma), 개발 담당 정의
- **2026.07.14 ~ 2026.07.28 (10일)** : 개발 환경 설정, 기준정보 입력, 단위별 기능 개발
- **2026.07.31 ~ 2026.08.06 (5일)** : 앱/서버 통합 개발, 단위 및 통합 테스트, 디버깅
- **2026.08.07 (1일)** : 시스템 최종 안정화, 배포 및 오픈

---

## <a name="members"></a>🤝🏼 팀원 구성
| 이름 | 역할 | GitHub | 담당 영역 |
|:---:|:---:|:---:|:---|
| **장석재** | 팀장 | [@장석재](https://github.com) | 마이페이지 전체, 관리자 웹페이지, 뱃지/포인트/스탬프 조회 |
| **필우청** | 팀원 | [@필우청](https://github.com) | 소셜/SMS 로그인, 얌얌북 커뮤니티, 1:1 문의, 이모티콘 팩 시스템 |
| **김현동** | 팀원 | [@김현동](https://github.com) | 영수증 OCR 인증, GPS 어뷰징 방지, PortOne 포인트 결제, AI 추천, 인앱 알림 |
| **임효진** | 팀원 | [@임효진](https://github.com) | 메인페이지, 얌얌로드 지도/업체, Geohash 스캔, AdMob/제휴 보상형 광고, UI/UX 디자인 |

---

## <a name="tech"></a>🖥 사용 기술

### 🎨 Frontend & App
<p>
  <img src="https://img.shields.io/badge/flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white">
  <img src="https://img.shields.io/badge/dart-0175C2?style=for-the-badge&logo=dart&logoColor=white">
  <img src="https://img.shields.io/badge/vue.js_3-4FC08D?style=for-the-badge&logo=vuedotjs&logoColor=white">
  <img src="https://img.shields.io/badge/javascript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black">
  <img src="https://img.shields.io/badge/html5-E34F26?style=for-the-badge&logo=html5&logoColor=white">
  <img src="https://img.shields.io/badge/css3-1572B6?style=for-the-badge&logo=css3&logoColor=white">
</p>

* **Flutter / Dart**: iOS & Android 크로스 플랫폼 앱 단일 코드베이스 구축
* **Vue.js 3**: 관리자(Admin) 백오피스 웹 프레임워크 활용

### 🛠 Backend & Cloud Services
<p>
  <img src="https://img.shields.io/badge/firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black">
  <img src="https://img.shields.io/badge/firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black">
  <img src="https://img.shields.io/badge/python-3776AB?style=for-the-badge&logo=python&logoColor=white">
  <img src="https://img.shields.io/badge/fastapi-009688?style=for-the-badge&logo=fastapi&logoColor=white">
</p>

* **Firebase Cloud Firestore**: NoSQL 기반 실시간 데이터베이스 구축 및 Geohash 복합 색인 최적화
* **Firebase Cloud Messaging (FCM)**: 인앱 푸시 알림 및 맞춤 추천 알림 발송
* **Python / FastAPI**: 영수증 OCR 분석 및 AI 맞춤 추천 알고리즘 백엔드 연동

### 🔌 APIs & External Services
<p>
  <img src="https://img.shields.io/badge/google_maps-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white">
  <img src="https://img.shields.io/badge/google_admob-EA4335?style=for-the-badge&logo=googleadmob&logoColor=white">
  <img src="https://img.shields.io/badge/portone-000000?style=for-the-badge&logo=portone&logoColor=white">
  <img src="https://img.shields.io/badge/google_oauth-4285F4?style=for-the-badge&logo=google&logoColor=white">
  <img src="https://img.shields.io/badge/kakao_login-FFCD00?style=for-the-badge&logo=kakaotalk&logoColor=black">
  <img src="https://img.shields.io/badge/naver_login-03C75A?style=for-the-badge&logo=naver&logoColor=white">
</p>

* **Google Maps API**: 위치 기반 마커 표시 및 거리 측정
* **Google AdMob**: 보상형 전면/영상 광고 인앱 결합
* **PortOne API**: PG사 연동 포인트 신용카드/계좌 결제 처리

---

## <a name="roles"></a>💪🏼 역할 분담

### 장석재 (팀장)
- **작업 페이지:**
  - 마이페이지 메인, 다이어리, 스탬프/뱃지/포인트 내역 조회, 문의/신고 내역, 설정
  - 관리자 웹페이지 전체 (회원 관리, 커뮤니티 관리, 문의 관리, 신고 관리)
- **구현 주요 기능:**
  - **팀 전체 스케줄 및 Git Repository 총괄 관리**
  - **게이미피케이션 조회 시스템**: 로드별 스탬프 수집 현황, 조건별(주간/월간/연간/진척도) 뱃지 발급 및 대표 뱃지 설정 로직 연동
  - **포인트 결제 및 상세 필터링**: 충전/사용 포인트 현황, 기간별/구분별/정렬별 필터링 및 카드 결제 승인 상세 정보 조회
  - **Vue.js 기반 독립 관리자 웹페이지 구축**: 앱과 분리된 백오피스 로그인 환경 구현, 회원/게시글 상태 변경, 신고 및 문의 처리/답변 백오피스 로직 개발

### 필우청
- **작업 페이지:**
  - 로그인/회원가입, 얌얌북 커뮤니티 (메인/글쓰기/상세/검색), 1:1 문의하기 및 내역
- **구현 주요 기능:**
  - **다중 인증 시스템 구축**: 구글, 카카오, 네이버 소셜 OAuth 로그인 연동 및 휴대폰 번호 SMS 인증 번호 발송/확인 로직 구현
  - **계정 복구 프로세스**: 탈퇴 신청 후 30일 이내 재로그인 시 계정 복구 팝업 제공 및 유예 기간 지나면 불가능하도록 처리
  - **얌얌북 커뮤니티 전체 로직**: 게시글/댓글/답글 CRUD, Soft Delete(상태값) 삭제 방식 적용, 좋아요/스크랩, 작성자 전용 뱃지 표시, 태그 검색 연동 및 신고 기능 구현
  - **커스텀 이모티콘 팩 시스템**: 캐릭터별 이모티콘 5팩(총 100개) 제작, 텍스트 토큰 변환/렌더링 및 드래그 앤 드롭을 이용한 순서 변경 기능 연동

### 김현동
- **작업 페이지:**
  - 영수증 스탬프 인증, 이모티콘/기프티콘/포인트 구매, AI 맞춤 추천, 인앱 알림 목록
- **구현 주요 기능:**
  - **스마트 영수증 OCR 인증 엔진**: 영수증 촬영 사진에서 상호명·날짜·시간·금액 추출 및 업체 DB 정보와 자동 비교
  - **GPS 어뷰징 및 부정 인증 검증 로직**: GPS 측정 거리 검사, 6시간 이내 결제 건 검증, 중복 영수증 차단, GPS 조작/루팅/비정상 이동 속도 자동 필터링 구축
  - **인증 보상 연동**: 검증 통과 시 스탬프 즉시 발행, 포인트 자동 지급 및 뱃지 획득 조건 판정 처리
  - **PortOne 결제 및 AI 추천**: PortOne 결제 모듈 연동 포인트 충전, FastAPI 연동 위치/이용 기록 기반 AI 맞춤 매장·코스 추천, FCM 인앱 푸시 알림 연동
- **관련 저장소:** [**YamYamServer**](https://github.com/Medo-skb/YamYamServer), [**yamyamroad-data-tools**](https://github.com/Medo-skb/yamyamroad-data-tools)

### 임효진
- **작업 페이지:**
  - 메인페이지, 얌얌로드(코스) 목록, 무료 포인트 광고 충전소, 지도-업체 상세 페이지
- **구현 주요 기능:**
  - **앱 전체 UI/UX 디자인 개선**: 사용자 친화적 테마 및 컴포넌트 디자인 구축
  - **Geohash 5자리 정밀 스캔 & 근처 매장 탐색**: 위치 권한 동의 후 Geohash 핀포인트 쿼리를 통해 사용자 위치 2km 이내 제휴 스탬프 매장 실시간 수급
  - **Google Maps API & 길찾기 연동**: 지도 위 업체 마커 및 내 위치-업체 간 거리를 표시하고 네이버 지도 외부 길찾기 분기 연동
  - **구글 AdMob & 자체 제휴 보상형 광고**: 로드 목록 내 배너 광고 부착, 보상형 전면/영상 광고 시청 시 무료 포인트 지급 및 일일 1회 제한 로직 구현

---

## <a name="resources"></a>📂 프로젝트 자료 모음 및 시연 영상

### 🎥 시연 영상
**[팀원별 담당 페이지 시연 영상]**
* ▶ **장석재 (팀장)**: [마이페이지 & 관리자 백오피스 웹 시연 영상](https://drive.google.com)
* ▶ **필우청**: [소셜/SMS 로그인 & 얌얌북 커뮤니티 & 1:1 문의 시연 영상](https://drive.google.com)
* ▶ **김현동**: [영수증 OCR 스탬프 인증 & 포인트 결제 & AI 추천 시연 영상](https://drive.google.com)
* ▶ **임효진**: [메인 & 얌얌로드 지도 & 무료 포인트 충전소 시연 영상](https://drive.google.com)

---

### 📋 기타 자료
| 분류 | 내용 및 링크 |
|------|------|
| 📝 **발표 자료** | [YamYamRoad 발표 PPT(PDF) 보기](https://drive.google.com/file/d/1x51YmlAJ-5Fp_6i1bwwfnxP3HW8GRBxy/view?usp=sharing) |
| 📊 **설계 자료** | [Figma 화면 설계 & Flow Chart](https://www.figma.com/board/gnpmd6pOIDDUzFAJUkc9px/YamYam-Road-%ED%99%94%EB%A9%B4%EC%84%A4%EA%B3%84?node-id=0-1&t=bkaj5lBuy3JGVWfG-1) \| [Google Sheet DB 명세서](https://docs.google.com/spreadsheets/d/1q33JJ1_Aat1rMSqjFgVJnWvNoOQW9FJn/edit?usp=sharing&ouid=108808101243830684768&rtpof=true&sd=true) |
