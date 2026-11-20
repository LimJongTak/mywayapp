import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final err = Validators.email(_email.text);
    if (err != null) return showSnack(context, '비밀번호를 재설정할 이메일을 입력하세요.');
    await _run(() => AuthService.instance.sendPasswordReset(_email.text));
    // 계정 존재 여부를 노출하지 않도록 항상 동일한 메시지
    if (mounted) showSnack(context, '가입된 이메일이라면 재설정 메일이 발송됩니다.');
  }

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Center(child: BrandLogo(size: 48)),
                  const SizedBox(height: 4),
                  const Text('산책 커뮤니티 & 보상형 플랫폼',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(hintText: '이메일'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pw,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      hintText: '비밀번호',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력하세요.' : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: _busy ? null : _resetPassword, child: const Text('비밀번호 찾기')),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _login,
                    child: _busy
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('로그인'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: _busy ? null : () => _run(AuthService.instance.signInWithGoogle),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Google 계정으로 계속하기'),
                  ),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('아직 회원이 아니신가요?'),
                    TextButton(onPressed: () => context.go('/signup'), child: const Text('회원가입')),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    if (!_form.currentState!.validate()) return;
    _run(() => AuthService.instance.signInWithEmail(_email.text, _pw.text));
  }
}
