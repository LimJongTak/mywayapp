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
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          PageTitle(
            '커뮤니티',
            trailing: canWrite
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => context.push('/post/new?board=${_board.name}'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('글쓰기'),
                  )
                : null,
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              children: [
                for (final b in Board.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(b.label),
                      selected: _board == b,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _board == b ? Colors.white : AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => _tabs.animateTo(b.index),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: SearchField(
              controller: _search,
              hint: '게시글 검색',
              onChanged: (_) => setState(() {}),
              onClear: () => setState(_search.clear),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                for (final b in Board.values) _BoardList(board: b, query: _search.text.trim()),
              ],
            ),
          ),
        ]),
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
        return ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
          if (board == Board.free && query.isEmpty) const _HotPosts(),
          if (filtered.isEmpty)
            EmptyView(message: query.isEmpty ? '첫 글을 작성해보세요!' : '검색 결과가 없습니다.'),
          for (final p in filtered) _PostTile(post: p),
          const SizedBox(height: 120),
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.yellow100,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🔥 HOT 게시물', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.grey200))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: post.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (post.commentCount > 0)
                  TextSpan(
                    text: ' [${post.commentCount}]',
                    style: const TextStyle(color: AppColors.orange, fontSize: 12),
                  ),
              ]), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${post.authorName} · ${fmtDate(post.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
            ]),
          ),
          Text('조회수: ${post.viewCount}', style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
        ]),
      ),
    );
  }
}
