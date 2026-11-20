import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _agree = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) return showSnack(context, '이용약관 및 위치기반서비스 이용에 동의해주세요.');
    setState(() => _busy = true);
    try {
      await AuthService.instance.signUpWithEmail(_email.text, _pw.text);
      if (mounted) showSnack(context, '인증 메일을 보냈습니다. 메일함을 확인하세요.');
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
        title: const Text('회원가입'),
        leading: BackButton(onPressed: () => context.go('/login')),
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🎉 지금 가입하면 500P 지급!\n추천인 코드 입력 시 300P 추가 적립',
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: '이메일'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pw,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '비밀번호 (영문+숫자 8자 이상)'),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pw2,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '비밀번호 확인'),
                  validator: (v) => v != _pw.text ? '비밀번호가 일치하지 않습니다.' : null,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('(필수) 이용약관, 개인정보처리방침, 위치기반 서비스 이용약관에 동의합니다.',
                      style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('가입하기'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
