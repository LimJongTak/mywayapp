import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// 하단 탭 — 선택된 탭은 검정 알약(아이콘+라벨), 나머지는 아이콘만 (Figma 네비게이션)
/// 가운데 노란 버튼: 산책로 등록
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, '홈'),
    (Icons.near_me_outlined, Icons.near_me, '지도'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, '커뮤니티'),
    (Icons.person_outline, Icons.person, '마이'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -6))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 76,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _tab(context, 0),
              _tab(context, 1),
              _addButton(context),
              _tab(context, 2),
              _tab(context, 3),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    return Tooltip(
      message: '산책로 등록',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/trail/record'),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(color: AppColors.yellow500, shape: BoxShape.circle),
          child: const Icon(Icons.add_rounded, color: AppColors.black, size: 28),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index) {
    final (icon, active, label) = _tabs[index];
    final selected = shell.currentIndex == index;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(selected ? active : icon,
                color: selected ? Colors.white : AppColors.black, size: 24),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ]),
        ),
      ),
    );
  }
}
