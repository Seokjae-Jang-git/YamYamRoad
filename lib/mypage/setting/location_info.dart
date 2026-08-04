import 'package:flutter/material.dart';

class LocationInfoScreen extends StatelessWidget {
  const LocationInfoScreen({super.key});

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: const Text(
          '위치기반서비스 이용약관',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate, size: 28),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: deepChocolate.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: deepChocolate.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const SelectableText(
            '''[얌얌로드(YamYamRoad)] 위치기반서비스 이용약관
제 1 조 (목적)
본 약관은 [회사명/팀명](이하 "회사"라 합니다)이 제공하는 위치기반서비스와 관련하여 회사와 개인위치기반서비스주체(이하 "회원"이라 합니다) 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제 2 조 (이용약관의 효력 및 변경)

본 약관은 회원이 본 약관에 동의하고 회사가 정한 소정의 절차에 따라 위치기반서비스의 이용자로 등록함으로써 효력이 발생합니다.

회원이 앱 내의 위치기반서비스 이용 동의 팝업 또는 회원가입 절차에서 '동의' 버튼을 클릭한 경우 본 약관의 내용을 모두 읽고 이를 충분히 이해하였으며, 그 적용에 동의한 것으로 봅니다.

회사는 위치기반서비스의 보호 및 이용 등에 관한 법률 등 관련 법령에 위배되지 않는 범위에서 본 약관을 개정할 수 있으며, 개정 시에는 그 개정 사유와 적용 일자를 명시하여 사전 공지합니다.

제 3 조 (위치기반서비스의 내용)
회사는 스마트폰 등 위치기반서비스 수집 기능을 갖춘 단말기를 통해 수집된 회원의 위치기반서비스를 활용하여 아래와 같은 위치기반서비스를 제공합니다.

내 주변 디저트 매장 안내: 회원의 현재 위치를 기준으로 근처의 디저트 순례 코스(성수동, 가로수길 등) 및 맛집 핀(마커)을 지도 위에 표시하여 제공합니다.

순례 코스 방문 인증 및 스탬프 발급: 회원이 특정 디저트 매장(체크포인트)에 방문하여 스탬프 획득을 요청할 때, GPS 기반으로 해당 장소와의 거리를 계산하여 방문 여부를 인증하고 스탬프를 발급합니다.

사용자 맞춤형 콘텐츠 제공: 회원의 위치에 기반하여 최적화된 지역별 큐레이션 및 추천 디저트 정보를 제공합니다.

제 4 조 (개인위치기반서비스의 수집방법)
회사는 다음과 같은 방식으로 개인위치기반서비스를 수집합니다.

스마트폰, 태블릿 PC 등 회원의 단말기에 내장된 GPS 수신기, Wi-Fi, 기지국 정보 등을 통하여 수집된 위치 좌표를 앱 실행 또는 특정 기능(스탬프 인증 등) 사용 시에만 수집합니다.

제 5 조 (위치기반서비스의 이용 및 보존목적)

회사는 제3조에 명시된 서비스 제공의 목적을 위해서만 회원의 위치기반서비스를 이용합니다.

회사는 원칙적으로 회원의 실시간 위치를 데이터베이스(MySQL, Firestore 등)에 영구적으로 저장하지 않습니다. 단, 스탬프 획득 시 부정 이용 방지 및 인증 내역 관리를 위해 '스탬프를 획득한 시점의 위치(좌표) 및 시간' 데이터는 해당 기록 파기 시까지 보존할 수 있습니다.

제 6 조 (개인위치기반서비스의 제3자 제공)

회사는 회원의 사전 동의 없이 개인위치기반서비스를 제3자에게 제공하지 않습니다.

회사가 제3자에게 위치기반서비스를 제공하게 될 경우, 사전에 제공받는 자와 제공 목적을 회원에게 고지하고 동의를 받습니다.

제 7 조 (개인위치기반서비스주체의 권리)

회원은 스마트폰 단말기의 설정 메뉴를 통해 언제든지 위치기반서비스 수집에 대한 동의를 철회(위치 권한 차단)할 수 있습니다.

동의를 철회할 경우, 회사는 즉시 해당 회원의 위치기반서비스 수집을 중단하며, '주변 맛집 안내' 및 '방문 인증(스탬프)' 등 위치 기반 기능의 제공이 제한될 수 있습니다.

회원은 회사에 대하여 본인의 위치기반서비스 수집, 이용, 제공 내역의 열람 또는 고지를 요구할 수 있으며, 오류가 있는 경우 정정을 요구할 수 있습니다.

제 8 조 (위치기반서비스관리책임자의 지정)
회사는 위치기반서비스를 적절히 관리 및 보호하고 위치기반서비스주체의 불만을 원활히 처리할 수 있도록 위치기반서비스관리책임자를 지정하고 있습니다.

책임자 성명: 홍길동

직책: 프로젝트 팀장 / 개발자

이메일: xxx@xxx.com''',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: deepChocolate,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}