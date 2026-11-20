import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _nick = TextEditingController(text: AuthService.instance.profile?.nickname);
  bool _busy = false;

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn, String success) async {
    setState(() => _busy = true);
    try {
      await fn();
      if (mounted) showSnack(context, success);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final me = auth.profile;
    final isPassword = auth.user?.providerData.any((p) => p.providerId == 'password') ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 관리')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('이메일'),
            subtitle: Text(me?.email ?? '-'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('가입일'),
            subtitle: Text(fmtDate(me?.createdAt)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nick,
            maxLength: 12,
            decoration: const InputDecoration(labelText: '닉네임'),
            validator: Validators.nickname,
          ),
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    if (!_form.currentState!.validate()) return;
                    _run(() => auth.updateNickname(_nick.text), '닉네임이 변경되었습니다.');
                  },
            child: const Text('닉네임 변경'),
          ),
          const SizedBox(height: 24),
          if (isPassword)
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _busy
                  ? null
                  : () => _run(() => auth.sendPasswordReset(me!.email!),
                      '비밀번호 재설정 메일을 보냈습니다.'),
              child: const Text('비밀번호 변경 메일 받기'),
            ),
          const SizedBox(height: 40),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.orange),
            onPressed: _busy
                ? null
                : () async {
                    final ok = await confirmDialog(context, '회원 탈퇴',
                        '탈퇴하면 포인트, 쿠폰, 등록한 산책로가 모두 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠어요?');
                    if (ok) await _run(auth.deleteAccount, '탈퇴가 완료되었습니다.');
                  },
            child: const Text('회원 탈퇴'),
          ),
        ]),
      ),
    );
  }
}
