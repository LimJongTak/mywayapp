import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common.dart';

/// 리워드 — 적립한 포인트로 지역 제휴 매장 쿠폰 교환
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  Future<void> _redeem(BuildContext context, Reward r) async {
    final points = AuthService.instance.profile?.points ?? 0;
    if (points < r.cost) return showSnack(context, '포인트가 부족합니다.');
    if (!await confirmDialog(context, '리워드 교환', '${r.cost}P를 사용해 "${r.title}" 쿠폰으로 교환할까요?')) {
      return;
    }
    try {
      final code = await UserService.instance.redeem(r.id);
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('교환 완료 🎁'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${r.partnerName}에서 아래 코드를 보여주세요.'),
              const SizedBox(height: 12),
              SelectableText(code,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ]),
            actions: [
              TextButton(
                onPressed: () => Clipboard.setData(ClipboardData(text: code)),
                child: const Text('복사'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('리워드'),
          bottom: const TabBar(tabs: [Tab(text: '교환하기'), Tab(text: '내 쿠폰')]),
        ),
        body: TabBarView(children: [
          ListenableBuilder(
            listenable: AuthService.instance,
            builder: (context, _) => StreamView<List<Reward>>(
              stream: UserService.instance.watchRewards(),
              isEmpty: (l) => l.isEmpty,
              emptyMessage: '준비 중인 리워드입니다.',
              builder: (context, list) => ListView(padding: const EdgeInsets.all(12), children: [
                Text('보유 포인트: ${AuthService.instance.profile?.points ?? 0}P',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                for (final r in list)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_offer, color: AppColors.primary),
                      title: Text(r.title),
                      subtitle: Text('${r.partnerName} · 남은 수량 ${r.stock}'),
                      trailing: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(72, 36)),
                        onPressed: r.stock > 0 ? () => _redeem(context, r) : null,
                        child: Text('${r.cost}P'),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          StreamView<List<Coupon>>(
            stream: UserService.instance.watchCoupons(),
            isEmpty: (l) => l.isEmpty,
            emptyMessage: '보유한 쿠폰이 없습니다.',
            builder: (context, list) => ListView(padding: const EdgeInsets.all(12), children: [
              for (final c in list)
                Card(
                  child: ListTile(
                    title: Text(c.title),
                    subtitle: Text('${c.partnerName}\n유효기간 ~${fmtDate(c.expiresAt)}'),
                    isThreeLine: true,
                    trailing: SelectableText(c.code,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: c.used ? TextDecoration.lineThrough : null,
                        )),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
