import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../models/trail.dart';
import '../../services/trail_service.dart';
import '../../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  Future<List<Trail>>? _results;
  final _popular = TrailService.instance.watchPopular();

  static const _suggestTags = ['반려견', '야경', '노을뷰', '데이트', '피크닉', '숲길', '강변'];

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _results = v.trim().isEmpty ? null : TrailService.instance.search(v));
    });
  }

  void _searchTag(String tag) {
    _q.text = tag;
    setState(() => _results = TrailService.instance.search(tag));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('산책로 검색')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _q,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '산책로 이름 또는 태그',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _q.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _q.clear();
                        _results = null;
                      }),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _results == null ? _home() : _resultList()),
      ]),
    );
  }

  Widget _home() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('추천 태그', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final t in _suggestTags)
          ActionChip(
            label: Text('#$t', style: const TextStyle(color: AppColors.primary)),
            onPressed: () => _searchTag(t),
          ),
      ]),
      const SizedBox(height: 24),
      const Text('🔥 평점 높은 산책로', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      StreamBuilder<List<Trail>>(
        stream: _popular,
        builder: (context, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) return const EmptyView(message: '아직 등록된 산책로가 없어요.');
          return Column(children: [
            for (final t in list)
              TrailCard(trail: t, onTap: () => context.push('/trail/${t.id}')),
          ]);
        },
      ),
    ]);
  }

  Widget _resultList() {
    return FutureBuilder<List<Trail>>(
      future: _results,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return const EmptyView(message: '검색 중 오류가 발생했습니다.');
        final list = snap.data ?? [];
        if (list.isEmpty) return const EmptyView(message: '검색 결과가 없습니다.', icon: Icons.search_off);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (_, i) =>
              TrailCard(trail: list[i], onTap: () => context.push('/trail/${list[i].id}')),
        );
      },
    );
  }
}
