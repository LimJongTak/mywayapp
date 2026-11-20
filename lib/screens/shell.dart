import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// 하단 탭: 홈(지도) / 검색 / [+ 산책로 등록] / 커뮤니티 / 마이페이지
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: '산책로 등록',
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/trail/record'),
        child: const Icon(Icons.add_location_alt_outlined),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 64,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _tab(context, 0, Icons.home_outlined, Icons.home, '홈'),
          _tab(context, 1, Icons.search, Icons.search, '검색'),
          const SizedBox(width: 48),
          _tab(context, 2, Icons.chat_bubble_outline, Icons.chat_bubble, '커뮤니티'),
          _tab(context, 3, Icons.person_outline, Icons.person, '마이'),
        ]),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, IconData active, String label) {
    final selected = shell.currentIndex == index;
    final color = selected ? AppColors.primary : Colors.black54;
    return InkResponse(
      onTap: () => shell.goBranch(index, initialLocation: index == shell.currentIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(selected ? active : icon, color: color),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ]),
      ),
    );
  }
}
