import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../widgets/common.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _comment = TextEditingController();
  bool _sending = false;
  final _svc = CommunityService.instance;

  @override
  void initState() {
    super.initState();
    _svc.markViewed(widget.postId);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    if (text.length > 1000) return showSnack(context, '댓글은 1000자 이하로 입력하세요.');
    setState(() => _sending = true);
    try {
      await _svc.addComment(widget.postId, text);
      _comment.clear();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Post post) async {
    if (!await confirmDialog(context, '게시글 삭제', '이 게시글을 삭제할까요?')) return;
    try {
      await _svc.delete(post.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return StreamBuilder<Post?>(
      stream: _svc.watchPost(widget.postId),
      builder: (context, snap) {
        if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final post = snap.data;
        if (post == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyView(message: '삭제된 게시글입니다.'));
        }
        final mine = post.authorId == auth.user?.uid;
        return Scaffold(
          appBar: AppBar(
            title: Text(post.board.label),
            actions: [
              if (mine || auth.isAdmin)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') context.push('/post/${post.id}/edit');
                    if (v == 'delete') _delete(post);
                  },
                  itemBuilder: (_) => [
                    if (mine) const PopupMenuItem(value: 'edit', child: Text('수정')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Text(post.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              '${post.authorName} · ${fmtDateTime(post.createdAt)} · 조회수 ${post.viewCount}',
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
            const Divider(height: 32),
            SelectableText(post.content, style: const TextStyle(height: 1.6, fontSize: 15)),
            const Divider(height: 32),
            Text('댓글 ${post.commentCount}', style: const TextStyle(fontWeight: FontWeight.w700)),
            StreamBuilder<List<Comment>>(
              stream: _svc.watchComments(post.id),
              builder: (context, cs) {
                final comments = cs.data ?? [];
                return Column(children: [
                  for (final c in comments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.authorName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('${c.content}\n${fmtDateTime(c.createdAt)}'),
                      isThreeLine: true,
                      trailing: (c.authorId == auth.user?.uid || auth.isAdmin)
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                if (await confirmDialog(context, '댓글 삭제', '댓글을 삭제할까요?')) {
                                  await _svc.deleteComment(post.id, c.id);
                                }
                              },
                            )
                          : null,
                    ),
                ]);
              },
            ),
          ]),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, 8 + MediaQuery.viewInsetsOf(context).bottom),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _comment,
                    maxLength: 1000,
                    decoration: const InputDecoration(hintText: '댓글을 입력하세요.', counterText: ''),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
