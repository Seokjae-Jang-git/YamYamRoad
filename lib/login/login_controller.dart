import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../services/auth_service.dart';

class LoginController {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  Future<void> initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '',
      );
      _googleSignInReady = true;
    } catch (e) {
      // debugPrint('⚠️ Google Sign-In 초기화 실패: $e');
    }
  }

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
      return false;
    }
  }

  // ---------------- 카카오 로그인 ----------------
  Future<void> handleKakaoLogin({
    required Function(bool) setLoading,
    required Function(String) onError,
    required VoidCallback onSuccess,
  }) async {
    setLoading(true);
    try {
      kakao.OAuthToken? token;
      bool isInstalled = await kakao.isKakaoTalkInstalled();

      if (isInstalled) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      if (token.accessToken.isEmpty) {
        onError('카카오 인증 토큰을 받지 못했습니다.');
        return;
      }

      final userModel = await AuthService.loginWithKakao(token.accessToken);
      if (await blockIfBanned(userModel.uid, onError)) return;

      // 🌟 데이터 로드 후 성공 콜백 실행
      await AuthService.loadUserProfileToUserData();
      onSuccess();

    } catch (e) {
      // debugPrint('⚠️ 카카오 로그인 실패: $e');
      onError('카카오 로그인에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  }

  // ---------------- 네이버 로그인 ----------------
  Future<void> handleNaverLogin({
    required Function(bool) setLoading,
    required Function(String) onError,
    required VoidCallback onSuccess,
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

      // 🌟 데이터 로드 후 성공 콜백 실행
      await AuthService.loadUserProfileToUserData();
      onSuccess();

    } catch (e) {
      // debugPrint('⚠️ 네이버 로그인 실패: $e');
      onError('네이버 로그인에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  }

  // ---------------- 구글 로그인 ----------------
  Future<void> handleGoogleLogin({
    required Function(bool) setLoading,
    required Function(String) onError,
    required VoidCallback onSuccess,
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

      // 🌟 데이터 로드 후 성공 콜백 실행
      await AuthService.loadUserProfileToUserData();
      onSuccess();

    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        onError('구글 로그인이 취소되었습니다.');
      } else {
        // debugPrint('⚠️ 구글 로그인 실패: ${e.code} - ${e.description}');
        onError('구글 로그인에 실패했습니다.');
      }
    } catch (e) {
      // debugPrint('⚠️ 구글 로그인 실패: $e');
      onError('구글 로그인에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  }
}