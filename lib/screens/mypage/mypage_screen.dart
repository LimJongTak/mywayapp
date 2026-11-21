import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/geo.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// 마이페이지 — Figma "Your Profile" 레이아웃 (큰 제목 + 프로필 + 둥근 메뉴 카드)
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final me = auth.profile;
        if (me == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final fmt = NumberFormat.decimalPattern('ko_KR');
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(padding: const EdgeInsets.only(bottom: 120), children: [
              const PageTitle('내 프로필'),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.yellow500,
                    child: Text(me.nickname.characters.first,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.black)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('안녕하세요, ${me.nickname}님',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(me.email ?? '',
                          style: const TextStyle(color: AppColors.grey400, fontSize: 13)),
                    ]),
                  ),
                  if (auth.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('관리자',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                ]),
              ),

              // 포인트 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Material(
                  color: AppColors.yellow500,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () => context.push('/me/points'),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('내 포인트',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.black,
                              backgroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => context.push('/me/rewards'),
                            child: const Text('리워드 교환 →',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        Text('${fmt.format(me.points)} P',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        Row(children: [
                          _miniStat('등록 산책로', '${me.trailCount}'),
                          _miniStat('산책 횟수', '${me.walkCount}'),
                          _miniStat('누적 거리', formatDistance(me.totalWalkM.toDouble())),
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  MenuTile(
                    title: '내 추천인 코드  ${me.referralCode}',
                    icon: Icons.copy_rounded,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: me.referralCode));
                      if (context.mounted) {
                        showSnack(context, '추천인 코드를 복사했어요. 친구가 입력하면 둘 다 300P!');
                      }
                    },
                  ),
                  MenuTile(
                      title: '개인정보 관리',
                      icon: Icons.account_circle_outlined,
                      onTap: () => context.push('/me/profile')),
                  MenuTile(
                      title: '나의 산책로 관리',
                      icon: Icons.route_outlined,
                      onTap: () => context.push('/me/trails')),
                  MenuTile(
                      title: '관심목록',
                      icon: Icons.favorite_border,
                      onTap: () => context.push('/me/favorites')),
                  MenuTile(
                      title: '포인트 내역 / 산책 기록',
                      icon: Icons.receipt_long_outlined,
                      onTap: () => context.push('/me/points')),
                  MenuTile(
                      title: '고객센터 (1:1 문의)',
                      icon: Icons.sms_outlined,
                      onTap: () => context.push('/me/inquiries')),
                  if (auth.isAdmin)
                    MenuTile(
                        title: '관리자 · 문의 답변',
                        icon: Icons.admin_panel_settings_outlined,
                        onTap: () => context.push('/admin/inquiries')),
                  MenuTile(
                    title: '로그아웃',
                    icon: Icons.logout_rounded,
                    onTap: () async {
                      if (await confirmDialog(context, '로그아웃', '로그아웃 하시겠어요?')) {
                        await auth.signOut();
                      }
                    },
                  ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B5A1E))),
        ]),
      );
}
