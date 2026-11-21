import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/trail.dart';
import '../../services/auth_service.dart';
import '../../services/trail_service.dart';
import '../../widgets/common.dart';

/// 홈 — 인사 + 검색 + 카테고리 + 인기 산책로 + 새 산책로 (Figma Homepage 레이아웃)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _category;
  List<Trail>? _trails;
  Set<String> _favs = {};
  final _subs = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    final svc = TrailService.instance;
    _subs.add(svc.watchRecent(limit: 100).listen((t) => setState(() => _trails = t)));
    _subs.add(svc.watchFavoriteIds().listen((f) => setState(() => _favs = f)));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _toggleFav(Trail t) async {
    try {
      await TrailService.instance.toggleFavorite(t, _favs.contains(t.id));
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.instance.profile;
    final all = _trails;
    final filtered = all?.where((t) => _category == null || t.category == _category).toList();
    final popular = [...?filtered]..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.only(bottom: 120), children: [
          // 인사 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.yellow500,
                child: Text(
                  (me?.nickname.isNotEmpty ?? false) ? me!.nickname.characters.first : '?',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.black),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('안녕하세요, ${me?.nickname ?? ''}님!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/me/points'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.yellow100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${me?.points ?? 0} P',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Text('오늘은 어디를\n걸어볼까요?',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.25)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SearchField(
              hint: '산책로 이름, #태그 검색',
              readOnly: true,
              onTap: () => context.push('/search'),
            ),
          ),

          // 카테고리
          SectionHeader('카테고리', action: '지도에서 보기', onAction: () => context.go('/map')),
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                CategoryPill(
                  emoji: '✨',
                  label: '전체',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final e in TrailCategory.labels.entries)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: CategoryPill(
                      emoji: categoryEmoji[e.key]!,
                      label: e.value,
                      selected: _category == e.key,
                      onTap: () => setState(() => _category = e.key),
                    ),
                  ),
              ],
            ),
          ),

          // 인기 산책로
          SectionHeader('인기 산책로', action: '전체보기', onAction: () => context.push('/trails')),
          if (all == null)
            const SizedBox(height: 246, child: Center(child: CircularProgressIndicator()))
          else if (popular.isEmpty)
            const SizedBox(height: 160, child: EmptyView(message: '아직 등록된 산책로가 없어요.'))
          else
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: popular.take(8).length,
                separatorBuilder: (_, _) => const SizedBox(width: 18),
                itemBuilder: (_, i) {
                  final t = popular[i];
                  return TrailFeatureCard(
                    trail: t,
                    favorite: _favs.contains(t.id),
                    onFavorite: () => _toggleFav(t),
                    onTap: () => context.push('/trail/${t.id}'),
                  );
                },
              ),
            ),

          // 새 산책로
          SectionHeader('새로 등록된 산책로', action: '전체보기', onAction: () => context.push('/trails')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              for (final t in (filtered ?? const <Trail>[]).take(10))
                TrailCard(
                  trail: t,
                  favorite: _favs.contains(t.id),
                  onFavorite: () => _toggleFav(t),
                  onTap: () => context.push('/trail/${t.id}'),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
