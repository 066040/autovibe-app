import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale_v1'; // 'tr','en',... veya 'system'

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString(_kLocaleKey) ?? 'system').trim().toLowerCase();

    if (raw.isEmpty || raw == 'system') return null; // null => system
    return Locale(raw);
  }

  Future<void> setSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, 'system');
    state = const AsyncData(null);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();

    if (locale == null) {
      await prefs.setString(_kLocaleKey, 'system');
      state = const AsyncData(null);
      return;
    }

    final code = locale.languageCode.trim().toLowerCase();
    if (code.isEmpty) {
      await prefs.setString(_kLocaleKey, 'system');
      state = const AsyncData(null);
      return;
    }

    await prefs.setString(_kLocaleKey, code);
    state = AsyncData(Locale(code));
  }

  Future<void> setLanguageCode(String code) async {
    await setLocale(Locale(code.trim().toLowerCase()));
  }
}
