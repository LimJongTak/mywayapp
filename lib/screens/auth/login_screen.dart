import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 40),
                  const Center(child: BrandLogo(size: 44)),
                  const SizedBox(height: 8),
                  const Text('걷는 만큼 쌓이는 산책 리워드',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey400, fontSize: 14)),
                  const SizedBox(height: 64),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: '이메일'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _pw,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력하세요.' : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: const Text('비밀번호 찾기')),
                  ),
                  const SizedBox(height: 72),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _busy ? null : () => context.go('/signup'),
                    child: const Text('회원가입'),
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33FCD240), blurRadius: 24, offset: Offset(0, 10)),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('로그인'),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text('간편 로그인',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey300, fontSize: 13)),
                  const SizedBox(height: 12),
                  Center(
                    child: Tooltip(
                      message: 'Google 계정으로 계속하기',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _busy ? null : () => _run(AuthService.instance.signInWithGoogle),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                              color: AppColors.grey100, shape: BoxShape.circle),
                          child: const Text('G',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
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
