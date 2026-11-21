import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'firebase_refs.dart';

/// 로그인 상태 + 내 프로필을 앱 전역에 제공 (라우터 refreshListenable)
class AuthService extends ChangeNotifier {
  AuthService._() {
    _authSub = Fb.auth.authStateChanges().listen(_onAuthChanged);
  }
  static final AuthService instance = AuthService._();

  StreamSubscription<User?>? _authSub;
  StreamSubscription? _profileSub;

  User? user;
  AppUser? profile;
  bool initialized = false;
  bool profileLoaded = false;
  bool isAdmin = false;

  bool get signedIn => user != null;

  /// 이메일/비밀번호 가입자는 이메일 인증이 끝나야 쓰기 권한이 생긴다.
  bool get needsEmailVerification {
    final u = user;
    if (u == null || u.emailVerified) return false;
    return u.providerData.any((p) => p.providerId == 'password');
  }

  Future<void> _onAuthChanged(User? u) async {
    await _profileSub?.cancel();
    user = u;
    profile = null;
    profileLoaded = false;
    isAdmin = false;
    initialized = true;
    if (u != null) {
      final token = await u.getIdTokenResult();
      isAdmin = token.claims?['admin'] == true;
      _profileSub = Fb.db.collection('users').doc(u.uid).snapshots().listen(
        (snap) {
          profile = snap.exists ? AppUser.fromDoc(snap) : null;
          profileLoaded = true;
          notifyListeners();
        },
        onError: (_) {
          profileLoaded = true;
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) =>
      Fb.auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signUpWithEmail(String email, String password) async {
    final cred = await Fb.auth
        .createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user?.sendEmailVerification();
  }

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      await Fb.auth.signInWithPopup(provider);
    } else {
      await Fb.auth.signInWithProvider(provider);
    }
  }

  Future<void> sendPasswordReset(String email) =>
      Fb.auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerification() async => user?.sendEmailVerification();

  /// 이메일 인증 여부 갱신 (인증 후 새 토큰 발급 필요)
  Future<void> reloadUser() async {
    await Fb.auth.currentUser?.reload();
    await Fb.auth.currentUser?.getIdToken(true);
    user = Fb.auth.currentUser;
    notifyListeners();
  }

  Future<void> initProfile(String nickname, String? referralCode) async {
    await Fb.call('initProfile', {
      'nickname': nickname.trim(),
      if (referralCode != null && referralCode.trim().isNotEmpty)
        'referralCode': referralCode.trim().toUpperCase(),
    });
  }

  Future<void> updateNickname(String nickname) =>
      Fb.call('updateNickname', {'nickname': nickname.trim()});

  Future<void> deleteAccount() async {
    await Fb.call('deleteAccount');
    await Fb.auth.signOut();
  }

  Future<void> signOut() => Fb.auth.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
