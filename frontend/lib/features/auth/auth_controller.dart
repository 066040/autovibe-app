import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/storage/token_storage.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthState {
  final bool loading;

  /// Oturum
  final String? token;
  final String? email;

  /// UI
  final bool rememberMe;

  /// Forgot password flow (şimdilik demo)
  final String? resetEmail;
  final bool resetCodeSent;

  const AuthState({
    this.loading = false,
    this.token,
    this.email,
    this.rememberMe = true,
    this.resetEmail,
    this.resetCodeSent = false,
  });

  bool get isAuthed => token != null && token!.isNotEmpty;

  AuthState copyWith({
    bool? loading,
    String? token,
    String? email,
    bool? rememberMe,
    String? resetEmail,
    bool? resetCodeSent,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      token: token ?? this.token,
      email: email ?? this.email,
      rememberMe: rememberMe ?? this.rememberMe,
      resetEmail: resetEmail ?? this.resetEmail,
      resetCodeSent: resetCodeSent ?? this.resetCodeSent,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  final _storage = TokenStorage();

  // Demo reset kodunu memory’de tutuyoruz (prod’da backend doğrulayacak)
  String? _demoResetCode;

  @override
  AuthState build() {
    // İlk açılışta token varsa yükle
    _boot();
    return const AuthState(loading: true);
  }

  Future<void> _boot() async {
    try {
      final token = await _storage.readToken();
      final remember = await _storage.readRememberMe();

      if (token != null && token.isNotEmpty) {
        state = state.copyWith(
          loading: false,
          token: token,
          // email backend token’dan çözülebilir; şimdilik null kalsın
          rememberMe: remember,
        );
      } else {
        state = state.copyWith(loading: false, rememberMe: remember);
      }
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void setRememberMe(bool v) {
    state = state.copyWith(rememberMe: v);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true);

    // TODO: backend login -> token
    await Future.delayed(const Duration(milliseconds: 650));

    const token = 'demo-token';
    await _storage.saveToken(token, rememberMe: state.rememberMe);

    state = state.copyWith(
      loading: false,
      token: token,
      email: email,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true);

    // TODO: backend register
    await Future.delayed(const Duration(milliseconds: 700));

    // Instagramvari: kayıt sonrası otomatik login yapmıyoruz
    state = state.copyWith(loading: false);
  }

  /// Şimdilik demo: 6 haneli kod üretir.
  /// Backend bağlanınca: /auth/forgot-password çağrısı olacak.
  Future<String> requestPasswordReset({required String email}) async {
    state = state.copyWith(loading: true);

    await Future.delayed(const Duration(milliseconds: 600));

    final code = (Random().nextInt(900000) + 100000).toString();
    _demoResetCode = code;

    state = state.copyWith(
      loading: false,
      resetEmail: email,
      resetCodeSent: true,
    );

    // demo test için geri dönüyoruz (prod’da UI’da göstermeyeceğiz)
    return code;
  }

  /// Şimdilik demo: memory’deki kod ile doğrular.
  /// Backend bağlanınca: /auth/reset-password çağrısı olacak.
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(loading: true);
    await Future.delayed(const Duration(milliseconds: 650));

    final ok = (state.resetEmail == email) && (_demoResetCode == code);
    if (!ok) {
      state = state.copyWith(loading: false);
      throw Exception('Kod hatalı');
    }

    _demoResetCode = null;
    state = state.copyWith(
      loading: false,
      resetEmail: null,
      resetCodeSent: false,
    );
  }

  Future<void> logout() async {
    await _storage.clear();
    _demoResetCode = null;
    state = const AuthState();
  }
}
