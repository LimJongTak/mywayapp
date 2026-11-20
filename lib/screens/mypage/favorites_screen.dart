import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/trail.dart';
import '../../services/trail_service.dart';
import '../../widgets/common.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관심목록')),
      body: StreamView<Set<String>>(
        stream: TrailService.instance.watchFavoriteIds(),
        isEmpty: (s) => s.isEmpty,
        emptyMessage: '관심 산책로가 없습니다.\n산책로 상세에서 ♥를 눌러보세요.',
        builder: (context, ids) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final id in ids)
              StreamBuilder<Trail?>(
                stream: TrailService.instance.watch(id),
                builder: (context, snap) {
                  final t = snap.data;
                  if (t == null) return const SizedBox.shrink();
                  return TrailCard(trail: t, onTap: () => context.push('/trail/${t.id}'));
                },
              ),
          ],
        ),
      ),
    );
  }
}
