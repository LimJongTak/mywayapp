import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../widgets/common.dart';
import '../mypage/inquiry_screens.dart';

/// 관리자: 미답변 문의 목록 + 답변 등록 (권한은 Firestore 규칙에서 재검증)
class AdminInquiriesScreen extends StatelessWidget {
  const AdminInquiriesScreen({super.key});

  Future<void> _answer(BuildContext context, Inquiry q) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('답변: ${q.title}'),
        content: TextField(
          controller: ctrl,
          maxLength: 3000,
          maxLines: 6,
          decoration: const InputDecoration(hintText: '답변 내용'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('등록')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await UserService.instance.answerInquiry(q.id, ctrl.text);
      if (context.mounted) showSnack(context, '답변을 등록했습니다.');
    } catch (e) {
      if (context.mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의 답변 관리')),
      body: StreamView<List<Inquiry>>(
        stream: UserService.instance.watchOpenInquiries(),
        isEmpty: (l) => l.isEmpty,
        emptyMessage: '답변 대기 중인 문의가 없습니다.',
        builder: (context, list) => ListView(padding: const EdgeInsets.all(12), children: [
          for (final q in list)
            InquiryTile(
              inquiry: q,
              trailing: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(children: [
                  Text('작성자: ${q.authorName}', style: const TextStyle(color: Colors.black54)),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(80, 36)),
                    onPressed: () => _answer(context, q),
                    child: const Text('답변하기'),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
