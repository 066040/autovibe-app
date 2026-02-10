import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _email.text.trim();
    final pass = _pass.text;

    try {
      await ref.read(authControllerProvider.notifier).login(
            email: email,
            password: pass,
          );
    } catch (e) {
      _toast('Giriş başarısız');
      return;
    }

    final st = ref.read(authControllerProvider);
    if (!mounted) return;

    if (st.isAuthed) {
      context.go('/autovibe/autovibe_home');
    } else {
      _toast('Giriş başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(authControllerProvider);
    final accent = const Color(0xFF2D6BFF);

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
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                children: [
                  const SizedBox(height: 6),
                  _BrandHeader(accent: accent),
                  const SizedBox(height: 22),

                  Container(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 14),

                          _NeoTextField(
                            controller: _email,
                            label: 'E-posta',
                            hint: 'ornek@mail.com',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'E-posta zorunlu';
                              if (!s.contains('@') || !s.contains('.')) return 'Geçerli bir e-posta gir';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          _NeoTextField(
                            controller: _pass,
                            label: 'Şifre',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white70,
                              ),
                            ),
                            validator: (v) {
                              final s = (v ?? '');
                              if (s.isEmpty) return 'Şifre zorunlu';
                              if (s.length < 6) return 'En az 6 karakter';
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              _RememberMe(
                                value: st.rememberMe,
                                onChanged: st.loading
                                    ? null
                                    : (v) => ref.read(authControllerProvider.notifier).setRememberMe(v),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: st.loading ? null : () => context.go('/forgot'),
                                child: const Text('Şifreni mi unuttun?', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: st.loading ? null : _submit,
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
                                  : const Text('Giriş Yap', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.12), height: 1)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('veya', style: TextStyle(color: Colors.white54)),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.12), height: 1)),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _AltButton(
                                  icon: Icons.g_mobiledata,
                                  label: 'Google',
                                  onTap: st.loading ? null : () => _toast('Google login: sonra'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _AltButton(
                                  icon: Icons.apple,
                                  label: 'Apple',
                                  onTap: st.loading ? null : () => _toast('Apple login: sonra'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Hesabın yok mu? ', style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: st.loading ? null : () => context.go('/register'),
                        child: const Text('Kayıt Ol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Devam ederek, kullanım koşullarını kabul etmiş olursun.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 12),
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

class _BrandHeader extends StatelessWidget {
  final Color accent;
  const _BrandHeader({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accent, accent.withOpacity(0.55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.25), blurRadius: 26, offset: const Offset(0, 10)),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 12),
        const Text('AutoNews', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('AutoVibe ile giriş yap', style: TextStyle(color: Colors.white.withOpacity(0.60))),
      ],
    );
  }
}

class _RememberMe extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _RememberMe({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged == null ? null : (v) => onChanged!(v ?? true),
            activeColor: const Color(0xFF2D6BFF),
            checkColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.20)),
          ),
          const Text('Beni hatırla', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _NeoTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
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
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
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

class _AltButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _AltButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.14)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: const Color(0xFF0B1220).withOpacity(0.25),
        ),
      ),
    );
  }
}
