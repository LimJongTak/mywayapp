import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// 디자인 토큰 — Figma "Traveling Mobile app (Pickolab Studio)" 스타일 가이드 기반
class AppColors {
  // Brand / Yellow
  static const yellow500 = Color(0xFFFCD240); // 메인 CTA
  static const yellow300 = Color(0xFFFEE98C);
  static const yellow200 = Color(0xFFFEF3B2);
  static const yellow100 = Color(0xFFFEF9D8);
  static const yellow700 = Color(0xFFB58D20);

  // Primary / Black (neutral)
  static const black = Color(0xFF1B1B1B); // 텍스트, 선택된 탭
  static const grey400 = Color(0xFF767676); // 보조 텍스트
  static const grey300 = Color(0xFFBABABA); // placeholder
  static const grey200 = Color(0xFFE8E8E8); // 테두리
  static const grey100 = Color(0xFFF3F3F3); // 입력창 배경
  static const white = Color(0xFFFFFFFF);

  // Semantic
  static const orange = Color(0xFFFD5B1F); // 하트, 강조 수치 (Error/500)
  static const success = Color(0xFF20CC89);
  static const info = Color(0xFF1668FF);

  // 기존 코드 호환용 별칭
  static const primary = black;
  static const accent = yellow500;
  static const star = yellow500;
  static const navy = black;

  static const brandGradient = LinearGradient(
    colors: [yellow500, Color(0xFFFFB648)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 사진 위 텍스트 가독성을 위한 하단 어두운 그라데이션
  static const photoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x99000000)],
    stops: [0.45, 1],
  );
}

class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.yellow500,
    primary: AppColors.black,
    onPrimary: Colors.white,
    secondary: AppColors.yellow500,
    onSecondary: AppColors.black,
    error: AppColors.orange,
    surface: Colors.white,
  );
  // Urbanist(라틴) + Noto Sans KR(한글) 조합
  final base = GoogleFonts.urbanistTextTheme().apply(
    bodyColor: AppColors.black,
    displayColor: AppColors.black,
    fontFamilyFallback: [GoogleFonts.notoSansKr().fontFamily!],
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: const BorderSide(color: AppColors.grey200),
  );

  return ThemeData(
    colorScheme: scheme,
    textTheme: base,
    scaffoldBackgroundColor: Colors.white,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: base.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.black)),
      errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.orange)),
      hintStyle: const TextStyle(color: AppColors.grey300),
      labelStyle: const TextStyle(color: AppColors.grey300),
      floatingLabelStyle: const TextStyle(color: AppColors.grey400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.yellow500,
        foregroundColor: AppColors.black,
        disabledBackgroundColor: AppColors.grey100,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        side: const BorderSide(color: AppColors.grey200),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.grey400),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.black,
      secondarySelectedColor: AppColors.black,
      side: const BorderSide(color: AppColors.grey200),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.black,
      unselectedLabelColor: AppColors.grey300,
      indicatorColor: AppColors.black,
      dividerColor: AppColors.grey200,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.grey200, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.black),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.black,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: AppColors.grey300),
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.black : Colors.transparent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}
