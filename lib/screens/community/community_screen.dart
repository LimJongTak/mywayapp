import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../widgets/common.dart';

/// 커뮤니티 — 공지사항 / 자유게시판 / Q&A
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: Board.values.length, vsync: this, initialIndex: 1)
    ..addListener(() => setState(() {}));
  final _search = TextEditingController();

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Board get _board => Board.values[_tabs.index];

  @override
  Widget build(BuildContext context) {
    final canWrite = _board != Board.notice || AuthService.instance.isAdmin;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          const SliverAppBar(
            pinned: true,
            title: BrandLogo(size: 26),
            centerTitle: false,
          ),
          const SliverToBoxAdapter(child: SloganBanner(label: 'COMMUNITY')),
          SliverToBoxAdapter(
            child: Row(children: [
              Expanded(
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primary,
                  tabs: [for (final b in Board.values) Tab(text: b.label)],
                ),
              ),
              if (canWrite)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(64, 36)),
                    onPressed: () => context.push('/post/new?board=${_board.name}'),
                    child: const Text('글쓰기'),
                  ),
                ),
            ]),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '검색어를 입력하세요.',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            for (final b in Board.values) _BoardList(board: b, query: _search.text.trim()),
          ],
        ),
      ),
    );
  }
}

class _BoardList extends StatelessWidget {
  const _BoardList({required this.board, required this.query});
  final Board board;
  final String query;

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Post>>(
      stream: CommunityService.instance.watchBoard(board),
      builder: (context, posts) {
        final filtered = query.isEmpty
            ? posts
            : posts.where((p) => p.title.contains(query) || p.content.contains(query)).toList();
        return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          if (board == Board.free && query.isEmpty) const _HotPosts(),
          if (filtered.isEmpty)
            EmptyView(message: query.isEmpty ? '첫 글을 작성해보세요!' : '검색 결과가 없습니다.'),
          for (final p in filtered) _PostTile(post: p),
          const SizedBox(height: 80),
        ]);
      },
    );
  }
}

class _HotPosts extends StatelessWidget {
  const _HotPosts();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: CommunityService.instance.watchHot(),
      builder: (context, snap) {
        final hot = (snap.data ?? []).where((p) => p.viewCount > 0).toList();
        if (hot.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('HOT 게시물 🔥🔥', style: TextStyle(fontWeight: FontWeight.w800)),
            for (final p in hot)
              InkWell(
                onTap: () => context.push('/post/${p.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('조회수: ${p.viewCount}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: post.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (post.commentCount > 0)
                  TextSpan(
                    text: ' [${post.commentCount}]',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
              ]), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${post.authorName} · ${fmtDate(post.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
          ),
          Text('조회수: ${post.viewCount}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ]),
      ),
    );
  }
}
