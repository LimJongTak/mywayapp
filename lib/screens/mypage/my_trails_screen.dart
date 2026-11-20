import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/trail.dart';
import '../../services/firebase_refs.dart';
import '../../services/trail_service.dart';
import '../../widgets/common.dart';

class MyTrailsScreen extends StatelessWidget {
  const MyTrailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나의 산책로 목록')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trail/record'),
        icon: const Icon(Icons.add),
        label: const Text('산책로 등록 바로가기'),
      ),
      body: StreamView<List<Trail>>(
        stream: TrailService.instance.watchMine(Fb.uid!),
        isEmpty: (l) => l.isEmpty,
        emptyMessage: '아직 등록한 산책로가 없어요.',
        builder: (context, list) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final t = list[i];
            return TrailCard(
              trail: t,
              onTap: () => context.push('/trail/${t.id}'),
              trailing: Column(mainAxisSize: MainAxisSize.min, children: [
                TextButton(
                    onPressed: () => context.push('/trail/${t.id}/edit'), child: const Text('수정')),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.orange),
                  onPressed: () async {
                    if (!await confirmDialog(context, '삭제', '"${t.title}"을(를) 삭제할까요?')) return;
                    try {
                      await TrailService.instance.delete(t.id);
                    } catch (e) {
                      if (context.mounted) showSnack(context, friendlyError(e));
                    }
                  },
                  child: const Text('삭제'),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
