import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// 최초 로그인 시 닉네임/추천인 코드 입력 → 서버에서 프로필 생성 + 포인트 지급
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _nick = TextEditingController();
  final _ref = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nick.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService.instance.initProfile(_nick.text, _ref.text);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 설정'),
        actions: [
          TextButton(onPressed: AuthService.instance.signOut, child: const Text('로그아웃')),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Center(child: BrandLogo(size: 36)),
                const SizedBox(height: 24),
                const Text('MyWay에서 사용할 닉네임을 정해주세요.', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nick,
                  maxLength: 12,
                  decoration: const InputDecoration(hintText: '닉네임 (2~12자)'),
                  validator: Validators.nickname,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ref,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: '추천인 코드 (선택)'),
                  validator: Validators.referralCode,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('시작하기'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
