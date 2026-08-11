import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: const Text(
          '개인정보 처리방침',
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
            '''[얌얌로드(YamYamRoad)] 개인정보 처리방침
회사명/팀명는 「개인정보 보호법」 등 관련 법령에 따라 이용자의 개인정보를 보호하고, 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 다음과 같이 개인정보 처리방침을 수립·공개합니다.

제 1 조 (개인정보의 수집 항목 및 수집 방법)
회사는 원활한 서비스 제공, 회원 관리, 위치 인증 기반 스탬프 기능 제공 등을 위해 아래와 같은 개인정보를 수집하고 있습니다.

수집 항목

필수 항목: 소셜 로그인(카카오 등) 정보(회원 식별자, 이메일, 닉네임, 프로필 사진), 단말기 식별 번호(Device ID), OS 버전

서비스 이용 시 수집 항목: 위치 정보(GPS 좌표), 카메라 및 사진첩 접근 권한(인증샷 업로드 시), 서비스 이용 기록(스탬프 획득 이력, 포인트 내역), 접속 로그, IP 주소

수집 방법

소셜 로그인 연동을 통한 수집

서비스 이용 과정에서 이용자의 동의를 통한 수집(위치 정보, 카메라 등)
앱 내 마이페이지, 프로필 수정 등을 통한 수집

제 2 조 (개인정보의 수집 및 이용 목적)
회사는 수집한 개인정보를 다음의 목적을 위해 활용합니다.

회원 관리: 본인 확인, 불량 회원의 부정 이용 방지(GPS 조작 및 매크로 사용 방지), 가입 의사 확인, 회원 탈퇴 처리

서비스 제공 및 운영: 위치 기반 디저트 순례 코스 안내, 매장 방문 인증(사진 및 위치 데이터 매칭), 스탬프 발급 및 경험치/포인트 적립, 뱃지 부여

서비스 개선 및 통계: 접속 빈도 파악, 회원의 서비스 이용에 대한 통계, 신규 서비스 개발 및 맞춤형 서비스 제공

고객 지원: 문의 사항 접수 및 처리, 공지사항 전달

제 3 조 (개인정보의 보유 및 이용 기간)
회사는 이용자로부터 개인정보를 수집할 때 동의받은 개인정보 보유 및 이용 기간 내에서 개인정보를 처리 및 보유합니다.

기본 원칙: 회원 탈퇴 시 즉시 파기 (단, 소셜 로그인 연동 해제 처리 포함)

예외 사항 (관계 법령에 의한 보존):

접속에 관한 기록: 3개월 (통신비밀보호법)

소비자의 불만 또는 분쟁 처리에 관한 기록: 3년 (전자상거래 등에서의 소비자보호에 관한 법률)

부정 이용 방지를 위한 자체 식별 기록: 6개월

제 4 조 (개인정보의 파기 절차 및 방법)
회사는 원칙적으로 개인정보 수집 및 이용 목적이 달성되거나, 회원이 탈퇴를 요청한 경우 지체 없이 해당 정보를 파기합니다.

파기 절차: 회원이 입력한 정보는 목적 달성 후 별도의 DB(또는 DB 내 분리된 테이블)로 옮겨져 내부 방침 및 기타 관련 법령에 따라 일정 기간 저장된 후 혹은 즉시 파기됩니다.

파기 방법: 전자적 파일 형태로 저장된 개인정보는 기록을 재생할 수 없는 기술적 방법(Soft Delete 및 주기적 영구 삭제)을 사용하여 삭제합니다.

제 5 조 (개인정보의 제3자 제공 및 위탁)

회사는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다. 단, 이용자가 사전에 동의하거나 법령의 규정에 의거한 경우는 예외로 합니다.

회사는 원활한 서비스 운영을 위해 아래와 같이 개인정보 처리 업무를 위탁하고 있습니다.

수탁 업체: Google LLC (Firebase, Google Cloud Platform 등)

위탁 업무 내용: 데이터베이스 서버 구축 및 운영, 이미지 파일 저장소(Storage) 제공

제 6 조 (이용자 및 법정대리인의 권리와 그 행사 방법)

이용자는 언제든지 앱 내 '마이페이지 > 내 정보 수정' 메뉴를 통해 자신의 개인정보를 조회하거나 수정할 수 있습니다.

이용자는 '마이페이지 > 탈퇴하기' 메뉴를 통해 소셜 로그인 연동 해제 및 개인정보 수집·이용에 대한 동의를 철회할 수 있습니다.

위치 정보, 카메라 접근 권한 등은 스마트폰의 시스템 설정(Settings) 메뉴에서 언제든지 접근 권한 동의를 철회할 수 있습니다.

제 7 조 (개인정보의 안전성 확보 조치)
회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다.

개인정보의 암호화: 비밀번호 등 중요 정보는 암호화되어 저장 및 관리됩니다.

해킹 등에 대비한 대책: 암호화 통신(SSL) 등을 통하여 네트워크상에서 개인정보를 안전하게 전송할 수 있도록 하고 있습니다.

제 8 조 (개인정보 보호책임자 및 담당 부서)
회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 이용자의 불만 처리 및 피해 구제를 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.

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