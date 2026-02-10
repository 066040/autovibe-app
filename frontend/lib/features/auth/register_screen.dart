import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    if (!_agree) {
      _toast('Devam etmek için koşulları kabul etmelisin');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final st = ref.read(authControllerProvider);
    if (st.loading) return;

    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _pass.text,
          );

      if (!mounted) return;
      _toast('Kayıt başarılı! Giriş yapabilirsin.');
      context.go('/login'); // router path’in buydu varsayıyorum
    } catch (e) {
      _toast('Kayıt başarısız: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(authControllerProvider);
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
                    'Kayıt Ol',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'AutoVibe dünyasına katıl',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.60)),
                  ),
                  const SizedBox(height: 16),

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
                          _NeoField(
                            controller: _name,
                            label: 'Ad Soyad',
                            hint: 'Mühendis',
                            icon: Icons.person_outline,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'İsim zorunlu';
                              if (s.length < 2) return 'Çok kısa';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _NeoField(
                            controller: _email,
                            label: 'E-posta',
                            hint: 'ornek@mail.com',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'E-posta zorunlu';
                              if (!s.contains('@') || !s.contains('.')) return 'Geçerli e-posta gir';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _NeoField(
                            controller: _pass,
                            label: 'Şifre',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _obscure1,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscure1 = !_obscure1),
                              icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.white70),
                            ),
                            validator: (v) {
                              final s = (v ?? '');
                              if (s.isEmpty) return 'Şifre zorunlu';
                              if (s.length < 6) return 'En az 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _NeoField(
                            controller: _pass2,
                            label: 'Şifre (Tekrar)',
                            hint: '••••••••',
                            icon: Icons.lock_reset_outlined,
                            obscure: _obscure2,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                              icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.white70),
                            ),
                            validator: (v) {
                              final s = (v ?? '');
                              if (s.isEmpty) return 'Tekrar şifre zorunlu';
                              if (s != _pass.text) return 'Şifreler uyuşmuyor';
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),

                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _agree = !_agree),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _agree,
                                  onChanged: (v) => setState(() => _agree = v ?? true),
                                  activeColor: accent,
                                  checkColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withOpacity(0.20)),
                                ),
                                Expanded(
                                  child: Text(
                                    'Kullanım koşullarını ve gizlilik politikasını kabul ediyorum',
                                    style: TextStyle(color: Colors.white.withOpacity(0.75)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
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
                                  : const Text('Hesap Oluştur', style: TextStyle(fontWeight: FontWeight.w900)),
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
                                  onTap: st.loading ? null : () => _toast('Google kayıt: sonra'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _AltButton(
                                  icon: Icons.apple,
                                  label: 'Apple',
                                  onTap: st.loading ? null : () => _toast('Apple kayıt: sonra'),
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
                      const Text('Zaten hesabın var mı? ', style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: st.loading ? null : () => context.go('/login'),
                        child: const Text('Giriş Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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

class _NeoField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _NeoField({
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
