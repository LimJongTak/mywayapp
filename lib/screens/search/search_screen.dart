import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
      appBar: AppBar(title: const Text('검색')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: SearchField(
            controller: _q,
            hint: '산책로 이름 또는 #태그',
            onChanged: (v) {
              setState(() {});
              _onChanged(v);
            },
            onSubmitted: _onChanged,
            onClear: () => setState(() {
              _q.clear();
              _results = null;
            }),
          ),
        ),
        Expanded(child: _results == null ? _home() : _resultList()),
      ]),
    );
  }

  Widget _home() {
    return ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), children: [
      const Text('추천 태그', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in _suggestTags)
          ActionChip(
            label: Text('#$t'),
            onPressed: () => _searchTag(t),
          ),
      ]),
      const SizedBox(height: 28),
      const Text('평점 높은 산책로', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 14),
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
        return ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), children: [
          Text('"${_q.text.trim()}" 검색 결과 ${list.length}개',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (final t in list)
            TrailCard(trail: t, onTap: () => context.push('/trail/${t.id}')),
        ]);
      },
    );
  }
}
