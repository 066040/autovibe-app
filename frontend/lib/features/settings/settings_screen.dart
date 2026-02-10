import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';

/// --------------------
/// SETTINGS STATE
/// --------------------
enum AppThemeMode { system, dark, light }

class SettingsState {
  final AppThemeMode themeMode;
  final String languageCode; // 'tr', 'en' vs.
  final bool pushNews;
  final bool pushVibes;
  final bool pushMarket;
  final bool haptics;
  final bool autoplayReels;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.languageCode = 'tr',
    this.pushNews = true,
    this.pushVibes = true,
    this.pushMarket = true,
    this.haptics = true,
    this.autoplayReels = true,
  });

  SettingsState copyWith({
    AppThemeMode? themeMode,
    String? languageCode,
    bool? pushNews,
    bool? pushVibes,
    bool? pushMarket,
    bool? haptics,
    bool? autoplayReels,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      pushNews: pushNews ?? this.pushNews,
      pushVibes: pushVibes ?? this.pushVibes,
      pushMarket: pushMarket ?? this.pushMarket,
      haptics: haptics ?? this.haptics,
      autoplayReels: autoplayReels ?? this.autoplayReels,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setTheme(AppThemeMode v) => state = state.copyWith(themeMode: v);
  void setLang(String code) => state = state.copyWith(languageCode: code);

  void toggleNews(bool v) => state = state.copyWith(pushNews: v);
  void toggleVibes(bool v) => state = state.copyWith(pushVibes: v);
  void toggleMarket(bool v) => state = state.copyWith(pushMarket: v);
  void toggleHaptics(bool v) => state = state.copyWith(haptics: v);
  void toggleAutoplay(bool v) => state = state.copyWith(autoplayReels: v);
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

/// --------------------
/// UI
/// --------------------
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _accent = Color(0xFF2D6BFF);

  void _toast(BuildContext context, String msg) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    final st = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Ayarlar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _accent.withOpacity(0.45)),
                      ),
                      child: Text(
                        auth.isAuthed ? 'Oturum Açık' : 'Misafir',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ACCOUNT
            _SectionTitle('Hesap'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Card(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _Row(
                        isDark: isDark,
                        icon: Icons.person_outline,
                        title: 'Hesap Bilgisi',
                        subtitle: auth.email ?? 'MÜHENDİS',
                        onTap: () => _toast(context, 'Profil düzenleme yakında'),
                      ),
                      const _Divider(),
                      _Row(
                        isDark: isDark,
                        icon: Icons.security_outlined,
                        title: 'Güvenlik',
                        subtitle: 'Şifre, oturumlar',
                        onTap: () => _toast(context, 'Güvenlik sayfası yakında'),
                      ),
                      const _Divider(),
                      _Row(
                        isDark: isDark,
                        icon: Icons.logout_rounded,
                        title: 'Çıkış Yap',
                        subtitle: 'Oturumu kapat',
                        danger: true,
                        onTap: () async {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // APPEARANCE
            _SectionTitle('Görünüm'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Card(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _ChoiceRow<AppThemeMode>(
                        isDark: isDark,
                        icon: Icons.brightness_6_outlined,
                        title: 'Tema',
                        value: st.themeMode,
                        items: const [
                          (AppThemeMode.system, 'Sistem'),
                          (AppThemeMode.dark, 'Koyu'),
                          (AppThemeMode.light, 'Açık'),
                        ],
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setTheme(v),
                      ),
                      const _Divider(),
                      _ChoiceRow<String>(
                        isDark: isDark,
                        icon: Icons.language_outlined,
                        title: 'Dil',
                        value: st.languageCode,
                        items: const [
                          ('tr', 'Türkçe'),
                          ('en', 'English'),
                          ('de', 'Deutsch'),
                          ('fr', 'Français'),
                          ('it', 'Italiano'),
                          ('ru', 'Русский'),
                          ('ja', '日本語'),
                          ('zh', '中文'),
                        ],
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setLang(v),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                        child: Text(
                          'Not: Şimdilik UI seçimi. Lokalizasyon bağlayınca otomatik uygulama dilini değiştireceğiz.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // NOTIFICATIONS
            _SectionTitle('Bildirimler'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Card(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _SwitchRow(
                        isDark: isDark,
                        icon: Icons.newspaper_outlined,
                        title: 'Haber Bildirimleri',
                        subtitle: 'Yeni haberler ve öne çıkanlar',
                        value: st.pushNews,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).toggleNews(v),
                      ),
                      const _Divider(),
                      _SwitchRow(
                        isDark: isDark,
                        icon: Icons.play_circle_outline_rounded,
                        title: 'Vibes Bildirimleri',
                        subtitle: 'Trend Revz ve kanal aktiviteleri',
                        value: st.pushVibes,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).toggleVibes(v),
                      ),
                      const _Divider(),
                      _SwitchRow(
                        isDark: isDark,
                        icon: Icons.storefront_outlined,
                        title: 'Market Bildirimleri',
                        subtitle: 'Favori ilan ve fiyat düşüşleri',
                        value: st.pushMarket,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).toggleMarket(v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // EXPERIENCE
            _SectionTitle('Deneyim'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Card(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _SwitchRow(
                        isDark: isDark,
                        icon: Icons.vibration_rounded,
                        title: 'Haptics',
                        subtitle: 'Dokunuş titreşimi',
                        value: st.haptics,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).toggleHaptics(v),
                      ),
                      const _Divider(),
                      _SwitchRow(
                        isDark: isDark,
                        icon: Icons.smart_display_outlined,
                        title: 'Revz Otomatik Oynat',
                        subtitle: 'Reels açılınca otomatik başlasın',
                        value: st.autoplayReels,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).toggleAutoplay(v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ABOUT
            _SectionTitle('Hakkında'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Card(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _Row(
                        isDark: isDark,
                        icon: Icons.info_outline,
                        title: 'Uygulama',
                        subtitle: 'AutoNews • AutoVibe',
                        onTap: () => _toast(context, 'About yakında'),
                      ),
                      const _Divider(),
                      _Row(
                        isDark: isDark,
                        icon: Icons.privacy_tip_outlined,
                        title: 'Gizlilik',
                        subtitle: 'KVKK / Privacy',
                        onTap: () => _toast(context, 'Gizlilik sayfası yakında'),
                      ),
                      const _Divider(),
                      _Row(
                        isDark: isDark,
                        icon: Icons.article_outlined,
                        title: 'Kullanım Şartları',
                        subtitle: 'Terms',
                        onTap: () => _toast(context, 'Şartlar yakında'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends SliverToBoxAdapter {
  _SectionTitle(String text)
      : super(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
}

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.black12);
  }
}

class _Row extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _Row({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = danger
        ? (isDark ? const Color(0xFFFF6B6B) : Colors.red)
        : (isDark ? Colors.white : Colors.black);

    final subColor = isDark ? Colors.white60 : Colors.black54;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: titleColor)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontWeight: FontWeight.w700, color: subColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  const _ChoiceRow({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    String labelOf(T v) {
      for (final it in items) {
        if (it.$1 == v) return it.$2;
      }
      return '';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        HapticFeedback.selectionClick();
        final chosen = await showModalBottomSheet<T>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _ChoiceSheet<T>(
            isDark: isDark,
            title: title,
            value: value,
            items: items,
          ),
        );
        if (chosen != null) onChanged(chosen);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: titleColor)),
                  const SizedBox(height: 4),
                  Text(labelOf(value), style: TextStyle(fontWeight: FontWeight.w700, color: subColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _ChoiceSheet<T> extends StatelessWidget {
  final bool isDark;
  final String title;
  final T value;
  final List<(T, String)> items;

  const _ChoiceSheet({
    required this.isDark,
    required this.title,
    required this.value,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0B1220) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: text)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final selected = it.$1 == value;
                    return ListTile(
                      onTap: () => Navigator.of(context).pop<T>(it.$1),
                      title: Text(it.$2, style: TextStyle(fontWeight: FontWeight.w800, color: text)),
                      trailing: selected ? const Icon(Icons.check, color: Color(0xFF2D6BFF)) : null,
                    );
                  },
                  separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                  itemCount: items.length,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
