import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

/// 사용자에게 그대로 보여줘도 되는 앱 내부 오류
class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 사용자에게 보여줄 오류 메시지 (내부 정보 노출 방지)
String friendlyError(Object e) {
  if (e is AppException) return e.message;
  if (e is FirebaseFunctionsException) {
    return e.message ?? '요청을 처리하지 못했습니다.';
  }
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 가입된 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'too-many-requests':
        return '시도 횟수가 너무 많습니다. 잠시 후 다시 시도하세요.';
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인한 뒤 시도하세요.';
      case 'popup-closed-by-user':
      case 'web-context-canceled':
        return '로그인이 취소되었습니다.';
    }
    return '인증 오류가 발생했습니다. (${e.code})';
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') return '권한이 없습니다.';
    if (e.code == 'unavailable') return '네트워크 연결을 확인하세요.';
    return '오류가 발생했습니다. (${e.code})';
  }
  return '알 수 없는 오류가 발생했습니다.';
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDialog(BuildContext context, String title, String body) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('확인'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
