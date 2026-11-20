import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/trail.dart';
import '../../services/trail_service.dart';
import '../../widgets/common.dart';

enum _Sort { recent, rating, popular }

class TrailListScreen extends StatefulWidget {
  const TrailListScreen({super.key});

  @override
  State<TrailListScreen> createState() => _TrailListScreenState();
}

class _TrailListScreenState extends State<TrailListScreen> {
  _Sort _sort = _Sort.recent;
  String? _category;
  final _stream = TrailService.instance.watchRecent();

  List<Trail> _apply(List<Trail> list) {
    final out = list.where((t) => _category == null || t.category == _category).toList();
    switch (_sort) {
      case _Sort.recent:
        break;
      case _Sort.rating:
        out.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
      case _Sort.popular:
        out.sort((a, b) => (b.walkCount + b.favoriteCount).compareTo(a.walkCount + a.favoriteCount));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('산책로 목록')),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              DropdownButton<_Sort>(
                value: _sort,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: _Sort.recent, child: Text('최신순')),
                  DropdownMenuItem(value: _Sort.rating, child: Text('평점순')),
                  DropdownMenuItem(value: _Sort.popular, child: Text('인기순')),
                ],
                onChanged: (v) => setState(() => _sort = v!),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('전체'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final e in TrailCategory.labels.entries)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: _category == e.key,
                    onSelected: (_) => setState(() => _category = e.key),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamView<List<Trail>>(
            stream: _stream,
            isEmpty: (l) => _apply(l).isEmpty,
            emptyMessage: '등록된 산책로가 없습니다.\n첫 산책로를 등록해보세요!',
            builder: (context, list) {
              final items = _apply(list);
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) => TrailCard(
                  trail: items[i],
                  onTap: () => context.push('/trail/${items[i].id}'),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
