const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.socialLogin = onCall(async (request) => {
  const { provider, accessToken } = request.data;
  if (!provider || !accessToken) {
    throw new HttpsError("invalid-argument", "provider와 accessToken이 필요합니다.");
  }

  let uid, userInfo = {};

  if (provider === "naver") {
    const res = await fetch("https://openapi.naver.com/v1/nid/me", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    const json = await res.json();
    if (json.resultcode !== "00") {
      throw new HttpsError("unauthenticated", "네이버 토큰 검증 실패");
    }
    uid = `naver:${json.response.id}`;
    userInfo = {
      displayName: json.response.name,
      email: json.response.email,
      photoURL: json.response.profile_image,
    };
  } else if (provider === "kakao") {
    const res = await fetch("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    const json = await res.json();
    if (!json.id) {
      throw new HttpsError("unauthenticated", "카카오 토큰 검증 실패");
    }
    uid = `kakao:${json.id}`;
    userInfo = {
      displayName: json.kakao_account?.profile?.nickname,
      email: json.kakao_account?.email,
      photoURL: json.kakao_account?.profile?.profile_image_url,
    };
  } else {
    throw new HttpsError("invalid-argument", "지원하지 않는 provider입니다.");
  }

  // 🌟 [핵심 수정] Firebase Admin SDK에 undefined 값이 들어가지 않도록 제거 처리
  const cleanUserInfo = {};
  if (userInfo.displayName) cleanUserInfo.displayName = userInfo.displayName;
  if (userInfo.email) cleanUserInfo.email = userInfo.email;
  if (userInfo.photoURL) cleanUserInfo.photoURL = userInfo.photoURL;

  try {
    await admin.auth().updateUser(uid, cleanUserInfo);
  } catch (e) {
    if (e.code === "auth/user-not-found") {
      await admin.auth().createUser({ uid, ...cleanUserInfo });
    } else {
      console.error("🔴 Firebase Auth 생성/수정 실패:", e);
      throw new HttpsError("internal", e.message || "유저 생성 실패");
    }
  }

  const customToken = await admin.auth().createCustomToken(uid);
  return {
    customToken,
    profile: {
      nickname: userInfo.displayName || null,
      profileImageUrl: userInfo.photoURL || null,
    },
  };
});