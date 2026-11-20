import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;

  Future<void> _check() async {
    setState(() => _busy = true);
    await AuthService.instance.reloadUser();
    if (mounted) {
      setState(() => _busy = false);
      if (AuthService.instance.needsEmailVerification) {
        showSnack(context, '아직 인증되지 않았습니다. 메일의 링크를 눌러주세요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.mark_email_unread_outlined, size: 72, color: Colors.indigo),
          const SizedBox(height: 16),
          Text('${auth.user?.email ?? ''} 로\n인증 메일을 보냈습니다.',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text('메일의 링크를 누른 뒤 아래 버튼을 눌러주세요.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 32),
          FilledButton(onPressed: _busy ? null : _check, child: const Text('인증 완료')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              try {
                await auth.resendVerification();
                if (context.mounted) showSnack(context, '인증 메일을 다시 보냈습니다.');
              } catch (e) {
                if (context.mounted) showSnack(context, friendlyError(e));
              }
            },
            child: const Text('메일 다시 보내기'),
          ),
          TextButton(onPressed: auth.signOut, child: const Text('다른 계정으로 로그인')),
        ]),
      ),
    );
  }
}
