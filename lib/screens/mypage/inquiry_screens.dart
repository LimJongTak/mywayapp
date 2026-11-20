import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../widgets/common.dart';

class InquiryListScreen extends StatelessWidget {
  const InquiryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('고객센터')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/me/inquiries/new'),
        icon: const Icon(Icons.edit),
        label: const Text('문의하기'),
      ),
      body: StreamView<List<Inquiry>>(
        stream: UserService.instance.watchMyInquiries(),
        isEmpty: (l) => l.isEmpty,
        emptyMessage: '문의 내역이 없습니다.',
        builder: (context, list) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [for (final q in list) InquiryTile(inquiry: q)],
        ),
      ),
    );
  }
}

class InquiryTile extends StatelessWidget {
  const InquiryTile({super.key, required this.inquiry, this.trailing});
  final Inquiry inquiry;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(inquiry.title),
        subtitle: Text('${fmtDateTime(inquiry.createdAt)} · ${inquiry.answered ? '답변 완료' : '답변 대기'}',
            style: TextStyle(color: inquiry.answered ? Colors.green : Colors.orange, fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(inquiry.content),
          if (inquiry.answer != null) ...[
            const Divider(height: 24),
            const Text('답변', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(inquiry.answer!),
          ],
          ?trailing,
        ],
      ),
    );
  }
}

class InquiryFormScreen extends StatefulWidget {
  const InquiryFormScreen({super.key});

  @override
  State<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends State<InquiryFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await UserService.instance.createInquiry(_title.text, _content.text);
      if (mounted) {
        showSnack(context, '문의가 접수되었습니다.');
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1:1 문의하기')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _title,
            maxLength: 100,
            decoration: const InputDecoration(hintText: '제목'),
            validator: Validators.length('제목', 1, 100),
          ),
          TextFormField(
            controller: _content,
            maxLength: 3000,
            minLines: 8,
            maxLines: null,
            decoration: const InputDecoration(hintText: '문의 내용을 입력하세요.'),
            validator: Validators.length('내용', 1, 3000),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _submit, child: const Text('문의 등록')),
        ]),
      ),
    );
  }
}
