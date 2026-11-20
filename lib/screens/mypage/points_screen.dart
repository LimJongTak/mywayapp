import 'package:material_ui/material_ui.dart';

import '../../core/geo.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../widgets/common.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = UserService.instance;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('포인트 / 산책 기록'),
          bottom: const TabBar(tabs: [Tab(text: '포인트 내역'), Tab(text: '산책 기록')]),
        ),
        body: TabBarView(children: [
          StreamView<List<PointLog>>(
            stream: svc.watchPointLogs(),
            isEmpty: (l) => l.isEmpty,
            emptyMessage: '포인트 내역이 없습니다.',
            builder: (context, logs) => ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final l = logs[i];
                return ListTile(
                  title: Text(l.reason),
                  subtitle: Text(fmtDateTime(l.createdAt)),
                  trailing: Text(
                    '${l.amount > 0 ? '+' : ''}${l.amount}P',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: l.amount > 0 ? AppColors.primary : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
          StreamView<List<WalkRecord>>(
            stream: svc.watchWalks(),
            isEmpty: (l) => l.isEmpty,
            emptyMessage: '산책 기록이 없습니다.\n산책로를 걸어보세요!',
            builder: (context, walks) => ListView.separated(
              itemCount: walks.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final w = walks[i];
                return ListTile(
                  leading: Icon(w.verified ? Icons.verified : Icons.cancel_outlined,
                      color: w.verified ? Colors.green : Colors.grey),
                  title: Text(w.trailTitle),
                  subtitle: Text(
                      '${formatDistance(w.distanceM.toDouble())} · ${(w.durationSec / 60).round()}분 · ${fmtDateTime(w.createdAt)}'),
                  trailing: w.points > 0 ? Text('+${w.points}P') : null,
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
