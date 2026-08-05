import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

import '../services/auth_service.dart';

class LoginController {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  Future<void> initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: '964766524983-2h5i53gehbvf1ti82ih7aeel99k7aln2.apps.googleusercontent.com',
      );
      _googleSignInReady = true;
      debugPrint('✅ 구글 SDK 초기화 성공');
    } catch (e) {
      debugPrint('🔴 구글 SDK 초기화 실패: $e');
    }
  }

  // 🌟 차단(banned) 유저 검증
  Future<bool> blockIfBanned(String uid, Function(String) onError) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final status = doc.data()?['status'] as String?;
      if (status == 'banned') {
        await FirebaseAuth.instance.signOut();
        onError('이용이 제한된 계정입니다. 고객센터로 문의해주세요.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🔴 계정 상태 확인 실패: $e');
      return false;
    }
  }

  // ---------------- 카카오 로그인 ----------------
  Future<void> handleKakaoLogin({
    required Function(bool) setLoading,
    required Function(String) onError,
  }) async {
    setLoading(true);
    try {
      kakao.OAuthToken? token;

      // 1. 카카오톡 앱 설치 여부 확인 후 로그인 시도
      bool isInstalled = await kakao.isKakaoTalkInstalled();

      if (isInstalled) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          debugPrint('⚠️ 카카오톡 앱 로그인 실패/취소, 브라우저 로그인으로 전환: $e');
          // 카카오톡 앱 로그인 실패 시(유저 취소 포함) 웹 브라우저 로그인으로 예외 전환
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // 카카오톡 미설치 시 바로 웹 브라우저 로그인
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 2. 토큰 정상 추출 여부 디버그 확인
      debugPrint('🔑 발급된 카카오 accessToken: ${token.accessToken}');

      if (token.accessToken.isEmpty) {
        onError('카카오 인증 토큰을 받지 못했습니다.');
        return;
      }

      // 3. 백엔드 Cloud Function 호출 (accessToken 전달)
      final userModel = await AuthService.loginWithKakao(token.accessToken);
      if (await blockIfBanned(userModel.uid, onError)) return;

    } catch (e, stackTrace) {
      debugPrint('🔴 카카오 로그인 최종 에러: $e\n$stackTrace');
      onError('카카오 로그인에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  }

  // ---------------- 네이버 로그인 ----------------
  Future<void> handleNaverLogin({
    required Function(bool) setLoading,
    required Function(String) onError,
  }) async {
    setLoading(true);
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status != NaverLoginStatus.loggedIn) {
        onError('네이버 로그인이 취소되었습니다.');
        return;
      }

      final tokenResult = await FlutterNaverLogin.getCurrentAccessToken();
      final userModel = await AuthService.loginWithNaver(tokenResult.accessToken);
      if (await blockIfBanned(userModel.uid, onError)) return;
    } catch (e, stackTrace) {
      debugPrint('🔴 네이버 로그인 에러: $e\n$stackTrace');
      onError('네이버 로그인에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  }

  // ---------------- 구글 로그인 ----------------
  Future<void> handleGoogleLogin({
    required Function(bool) setLoading,
    required Function(String) onError,
  }) async {
    setLoading(true);
    try {
      if (!_googleSignInReady) {
        await initGoogleSignIn();
      }

      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      final userModel = await AuthService.loginWithGoogle(idToken: idToken);
      if (await blockIfBanned(userModel.uid, onError)) return;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        onError('구글 로그인이 취소되었습니다.');
      } else {
        onError('구글 로그인에 실패했습니다.');
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 구글 로그인 알 수 없는 에러: $e\n$stackTrace');
      onError('구글 로그인에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  }
}