/// 클라이언트 입력 검증 (서버 규칙과 동일한 기준 — UX용 1차 검증)
class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _nickname = RegExp(r'^[0-9A-Za-z가-힣_]{2,12}$');

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return '이메일을 입력하세요.';
    if (!_email.hasMatch(v.trim())) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  /// 8자 이상, 영문+숫자 포함
  static String? password(String? v) {
    if (v == null || v.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return '영문과 숫자를 모두 포함해야 합니다.';
    }
    return null;
  }

  static String? nickname(String? v) {
    if (v == null || !_nickname.hasMatch(v.trim())) {
      return '2~12자의 한글/영문/숫자/_ 만 가능합니다.';
    }
    return null;
  }

  static String? Function(String?) length(String label, int min, int max) =>
      (v) {
        final len = v?.trim().length ?? 0;
        if (len < min) return '$label을(를) 입력하세요.';
        if (len > max) return '$label은(는) $max자 이하로 입력하세요.';
        return null;
      };

  static String? referralCode(String? v) {
    if (v == null || v.trim().isEmpty) return null; // 선택 입력
    if (!RegExp(r'^[A-Za-z0-9]{6,8}$').hasMatch(v.trim())) {
      return '추천인 코드 형식이 올바르지 않습니다.';
    }
    return null;
  }

  /// "#노을뷰 #산책로, 데이트" → ['노을뷰', '산책로', '데이트']
  static List<String> parseTags(String raw) => raw
      .split(RegExp(r'[\s,#]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty && t.length <= 15)
      .toSet()
      .take(10)
      .toList();
}
