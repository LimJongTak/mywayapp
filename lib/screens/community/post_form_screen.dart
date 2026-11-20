import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';

class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key, this.board = Board.free, this.editPostId});
  final Board board;
  final String? editPostId;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  late Board _board = widget.board;
  bool _busy = false;

  bool get _isEdit => widget.editPostId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      CommunityService.instance.watchPost(widget.editPostId!).first.then((p) {
        if (!mounted || p == null) return;
        if (p.authorId != AuthService.instance.user?.uid) {
          showSnack(context, '수정 권한이 없습니다.');
          context.pop();
          return;
        }
        setState(() {
          _board = p.board;
          _title.text = p.title;
          _content.text = p.content;
        });
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final svc = CommunityService.instance;
      if (_isEdit) {
        await svc.update(widget.editPostId!, _title.text, _content.text);
        if (mounted) context.pop();
      } else {
        final id = await svc.create(_board, _title.text, _content.text);
        if (mounted) context.pushReplacement('/post/$id');
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.isAdmin;
    final boards = Board.values.where((b) => b != Board.notice || isAdmin).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '글 수정' : '글쓰기'),
        actions: [
          TextButton(onPressed: _busy ? null : _save, child: const Text('등록')),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (!_isEdit)
            DropdownButtonFormField<Board>(
              initialValue: boards.contains(_board) ? _board : Board.free,
              items: [for (final b in boards) DropdownMenuItem(value: b, child: Text(b.label))],
              onChanged: (b) => setState(() => _board = b!),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _title,
            maxLength: 100,
            decoration: const InputDecoration(hintText: '제목'),
            validator: Validators.length('제목', 1, 100),
          ),
          TextFormField(
            controller: _content,
            maxLength: 5000,
            minLines: 10,
            maxLines: null,
            decoration: const InputDecoration(hintText: '내용을 입력하세요.'),
            validator: Validators.length('내용', 1, 5000),
          ),
        ]),
      ),
    );
  }
}
