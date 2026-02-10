import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPass = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPass.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _validEmail(String s) => s.contains('@') && s.contains('.');

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    final email = _email.text.trim();
    if (email.isEmpty || !_validEmail(email)) {
      _toast('Geçerli bir e-posta gir');
      return;
    }

    try {
      // ✅ AuthController artık String code döndürüyor (demo için)
      final code = await ref.read(authControllerProvider.notifier).requestPasswordReset(email: email);

      if (!mounted) return;
      // demo: kodu göster (backend bağlayınca bunu kaldıracağız)
      _toast('Kod gönderildi (demo kod: $code)');
    } catch (e) {
      _toast('Kod gönderilemedi');
    }
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    final email = _email.text.trim();
    final code = _code.text.trim();
    final pass = _newPass.text;

    if (email.isEmpty || !_validEmail(email)) {
      _toast('Geçerli bir e-posta gir');
      return;
    }
    if (code.length != 6) {
      _toast('6 haneli kod gir');
      return;
    }
    if (pass.length < 6) {
      _toast('Şifre en az 6 karakter');
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).confirmPasswordReset(
            email: email,
            code: code,
            newPassword: pass,
          );

      if (!mounted) return;
      _toast('Şifre güncellendi. Giriş yapabilirsin.');
      context.go('/login');
    } catch (e) {
      _toast('Kod hatalı');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(authControllerProvider);

    final step2 = st.resetCodeSent;
    const accent = Color(0xFF2D6BFF);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070B14), Color(0xFF0B1220), Color(0xFF0A1020)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Şifre Sıfırlama',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _Card(
                    child: Column(
                      children: [
                        _NeoField(
                          controller: _email,
                          label: 'E-posta',
                          hint: 'ornek@mail.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: st.loading ? null : _sendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: st.loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Kod Gönder', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: step2 ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !step2,
                      child: _Card(
                        child: Column(
                          children: [
                            _NeoField(
                              controller: _code,
                              label: '6 Haneli Kod',
                              hint: '123456',
                              icon: Icons.confirmation_number_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _NeoField(
                              controller: _newPass,
                              label: 'Yeni Şifre',
                              hint: '••••••••',
                              icon: Icons.lock_reset_outlined,
                              obscure: _obscure,
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.white70,
                                ),
                              ),
                              onFieldSubmitted: (_) => _confirm(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: st.loading ? null : _confirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: const Text('Şifreyi Güncelle', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Hatırladın mı? ', style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: child,
    );
  }
}

class _NeoField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final void Function(String)? onFieldSubmitted;

  const _NeoField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220).withOpacity(0.50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        onSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: suffix,
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.72)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w500),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
