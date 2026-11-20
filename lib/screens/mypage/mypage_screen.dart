import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/geo.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

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
          appBar: AppBar(title: const BrandLogo(size: 26), centerTitle: false),
          body: ListView(children: [
            const SloganBanner(label: 'MYPAGE'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary,
                  child: Text(me.nickname.characters.first,
                      style: const TextStyle(fontSize: 24, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(me.nickname,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(me.email ?? '', style: const TextStyle(color: Colors.black54)),
                    if (auth.isAdmin)
                      const Text('관리자', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
            // 포인트 카드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => context.push('/me/points'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('내 포인트', style: TextStyle(color: Colors.white70)),
                    Text('${fmt.format(me.points)} P',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _miniStat('등록 산책로', '${me.trailCount}'),
                      _miniStat('산책 횟수', '${me.walkCount}'),
                      _miniStat('누적 거리', formatDistance(me.totalWalkM.toDouble())),
                    ]),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('내 추천인 코드'),
              subtitle: const Text('친구가 가입 시 입력하면 둘 다 300P!'),
              trailing: TextButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: Text(me.referralCode,
                    style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: me.referralCode));
                  if (context.mounted) showSnack(context, '추천인 코드를 복사했습니다.');
                },
              ),
            ),
            const Divider(),
            _section('개인정보 관리'),
            _item(context, Icons.person_outline, '프로필 / 계정 설정', '/me/profile'),
            _section('산책로 관리'),
            _item(context, Icons.route, '나의 산책로 목록', '/me/trails'),
            _item(context, Icons.favorite_border, '관심목록', '/me/favorites'),
            _item(context, Icons.add_location_alt_outlined, '산책로 등록 바로가기', '/trail/record'),
            _section('포인트 & 리워드'),
            _item(context, Icons.receipt_long, '포인트 내역 / 산책 기록', '/me/points'),
            _item(context, Icons.storefront, '리워드 교환 (제휴 매장)', '/me/rewards'),
            _section('고객센터'),
            _item(context, Icons.support_agent, '1:1 문의하기', '/me/inquiries'),
            if (auth.isAdmin) ...[
              _section('관리자'),
              _item(context, Icons.admin_panel_settings_outlined, '문의 답변 관리', '/admin/inquiries'),
            ],
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () async {
                if (await confirmDialog(context, '로그아웃', '로그아웃 하시겠어요?')) {
                  await auth.signOut();
                }
              },
            ),
            const SizedBox(height: 100),
          ]),
        );
      },
    );
  }

  Widget _miniStat(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      );

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
      );

  Widget _item(BuildContext context, IconData icon, String title, String route) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      );
}
