import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _kToken = 'auth_token_v1';
  static const _kRemember = 'remember_me_v1';

  Future<void> saveToken(String token, {required bool rememberMe}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, rememberMe);
    if (rememberMe) {
      await p.setString(_kToken, token);
    } else {
      await p.remove(_kToken);
    }
  }

  Future<String?> readToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken);
  }

  Future<bool> readRememberMe() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRemember) ?? true;
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kRemember);
  }
}
