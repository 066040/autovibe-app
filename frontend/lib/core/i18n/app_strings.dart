import 'package:flutter/widgets.dart';

class S {
  final Locale locale;
  const S._(this.locale);

  static const supportedLocales = <Locale>[
    Locale('tr'),
    Locale('en'),
    Locale('de'),
    Locale('zh'),
    Locale('ja'),
    Locale('fr'),
    Locale('it'),
    Locale('ru'),
  ];

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// ✅ SAFE: asla "!" yok
  static S of(BuildContext context) {
    final s = Localizations.of<S>(context, S);
    if (s != null) return s;

    // context hazır değilse fallback
    final lc = Localizations.maybeLocaleOf(context)?.languageCode.toLowerCase() ?? 'en';
    return S._(Locale(lc));
  }

  // ---- Strings Map ----
  static const _strings = <String, Map<String, String>>{
    'en': {
      'settingsTitle': 'Settings',
      'themeTitle': 'Theme',
      'themeSubtitle': 'Light / Dark / System',
      'languageTitle': 'Language',
      'languageSubtitle': 'Choose app language or use system language',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'aboutTitle': 'About',
      'aboutSubtitle': 'CarNews (MVP)',
    },
    'tr': {
      'settingsTitle': 'Ayarlar',
      'themeTitle': 'Tema',
      'themeSubtitle': 'Açık / Koyu / Sistem',
      'languageTitle': 'Dil',
      'languageSubtitle': 'Uygulama dilini seç veya sistem dilini kullan',
      'system': 'Sistem',
      'light': 'Açık',
      'dark': 'Koyu',
      'aboutTitle': 'Hakkında',
      'aboutSubtitle': 'CarNews (MVP)',
    },
    'de': {
      'settingsTitle': 'Einstellungen',
      'themeTitle': 'Design',
      'themeSubtitle': 'Hell / Dunkel / System',
      'languageTitle': 'Sprache',
      'languageSubtitle': 'App-Sprache wählen oder Systemsprache verwenden',
      'system': 'System',
      'light': 'Hell',
      'dark': 'Dunkel',
      'aboutTitle': 'Über',
      'aboutSubtitle': 'CarNews (MVP)',
    },
    'zh': {
      'settingsTitle': '设置',
      'themeTitle': '主题',
      'themeSubtitle': '浅色 / 深色 / 系统',
      'languageTitle': '语言',
      'languageSubtitle': '选择应用语言或使用系统语言',
      'system': '系统',
      'light': '浅色',
      'dark': '深色',
      'aboutTitle': '关于',
      'aboutSubtitle': 'CarNews (MVP)',
    },
    'ja': {
      'settingsTitle': '設定',
      'themeTitle': 'テーマ',
      'themeSubtitle': 'ライト / ダーク / システム',
      'languageTitle': '言語',
      'languageSubtitle': 'アプリの言語を選択するかシステム言語を使用',
      'system': 'システム',
      'light': 'ライト',
      'dark': 'ダーク',
      'aboutTitle': '情報',
      'aboutSubtitle': 'CarNews (MVP)',
    },
    'fr': {
      'settingsTitle': 'Paramètres',
      'themeTitle': 'Thème',
      'themeSubtitle': 'Clair / Sombre / Système',
      'languageTitle': 'Langue',
      'languageSubtitle': 'Choisir la langue de l’app ou utiliser la langue système',
      'system': 'Système',
      'light': 'Clair',
      'dark': 'Sombre',
      'aboutTitle': 'À propos',
      'aboutSubtitle': 'CarNews (MVP)',
    },
    'it': {
      'settingsTitle': 'Impostazioni',
      'themeTitle': 'Tema',
      'themeSubtitle': 'Chiaro / Scuro / Sistema',
      'languageTitle': 'Lingua',
      'languageSubtitle': 'Scegli la lingua dell’app o usa la lingua di sistema',
      'system': 'Sistema',
      'light': 'Chiaro',
      'dark': 'Scuro',
      'aboutTitle': 'Info',
      'aboutSubtitle': 'CarNews (MVP)',
    },
    'ru': {
      'settingsTitle': 'Настройки',
      'themeTitle': 'Тема',
      'themeSubtitle': 'Светлая / Тёмная / Система',
      'languageTitle': 'Язык',
      'languageSubtitle': 'Выберите язык приложения или используйте системный',
      'system': 'Система',
      'light': 'Светлая',
      'dark': 'Тёмная',
      'aboutTitle': 'О приложении',
      'aboutSubtitle': 'CarNews (MVP)',
    },
  };

  String _t(String key) {
    final code = locale.languageCode.toLowerCase();
    final v1 = _strings[code]?[key];
    if (v1 != null) return v1;

    final v2 = _strings['en']?[key];
    if (v2 != null) return v2;

    return key; // ✅ asla crash yok
  }

  String get settingsTitle => _t('settingsTitle');
  String get themeTitle => _t('themeTitle');
  String get themeSubtitle => _t('themeSubtitle');
  String get languageTitle => _t('languageTitle');
  String get languageSubtitle => _t('languageSubtitle');
  String get system => _t('system');
  String get light => _t('light');
  String get dark => _t('dark');
  String get aboutTitle => _t('aboutTitle');
  String get aboutSubtitle => _t('aboutSubtitle');
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) {
    final lc = locale.languageCode.toLowerCase();
    return S.supportedLocales.any((l) => l.languageCode.toLowerCase() == lc);
  }

  @override
  Future<S> load(Locale locale) async {
    return S._(Locale(locale.languageCode.toLowerCase()));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<S> old) => false;
}
