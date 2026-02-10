import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'edit_profile_screen.dart';

import 'reactions_library_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _accent = Color(0xFF2D6BFF);
  int _tab = 0; // 0: Posts, 1: Revz, 2: Garage

  void _toast(String msg) {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  ImageProvider? _imgProvider(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;

    final lower = s.toLowerCase();
    final isUrl = lower.startsWith('http://') || lower.startsWith('https://');
    if (isUrl) return NetworkImage(s);

    if (!kIsWeb) {
      final f = File(s);
      if (f.existsSync()) return FileImage(f);
    }
    return null;
  }

  String _roleLabel(ProfileRole r) {
    switch (r) {
      case ProfileRole.reader:
        return 'Okuyucu';
      case ProfileRole.journalist:
        return 'Gazeteci';
      case ProfileRole.publisher:
        return 'Yayıncı';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Profile error: $e')),
          data: (p) {
            final coverImg = _imgProvider(p.cover);
            final avatarImg = _imgProvider(p.avatar);

            final displayName = p.displayName.trim().isEmpty ? 'ok&ya' : p.displayName.trim();
            final bio = p.bio.trim();
            final website = p.website.trim();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // --- TOP BAR ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          'Profil',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 10),
_IconPill(
  isDark: isDark,
  icon: Icons.favorite_border,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReactionsLibraryScreen()),
    );
  },
),
                        const SizedBox(width: 10),
                        _IconPill(
                          isDark: isDark,
                          icon: Icons.settings_outlined,
                          onTap: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- HEADER (COVER + AVATAR + INFO) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ProfileHeaderCard(
                      isDark: isDark,
                      accent: _accent,
                      coverImg: coverImg,
                      avatarImg: avatarImg,
                      displayName: displayName,
                      bio: bio,
                      website: website,
                      roleText: _roleLabel(p.role),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // --- ACTIONS ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _EditProfileButton(
                            isDark: isDark,
                            onTap: () async {
                              final res = await context.push('/edit-profile');
                              if (res == true) {
                                // prefs değişti -> profileProvider yenile
                                ref.invalidate(profileProvider);
                                _toast('Profil güncellendi');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        _IconButtonSquare(
                          isDark: isDark,
                          icon: Icons.verified_outlined,
                          onTap: () => _toast('Doğrulama (yakında)'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // --- TABS ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _Tabs(
                      isDark: isDark,
                      tab: _tab,
                      onChange: (i) => setState(() => _tab = i),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // --- CONTENT ---
                if (_tab == 0) ..._postsSlivers(isDark)
                else if (_tab == 1) ..._revzSlivers(isDark)
                else ..._garageSlivers(isDark),

                const SliverToBoxAdapter(child: SizedBox(height: 18)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _postsSlivers(bool isDark) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _GridTile(isDark: isDark, label: 'Post ${i + 1}'),
            childCount: 12,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
        ),
      ),
    ];
  }

  List<Widget> _revzSlivers(bool isDark) {
    final items = List.generate(8, (i) => 'Revz ${i + 1}');
    return [
      SliverList.separated(
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _RowCard(
            isDark: isDark,
            title: items[i],
            subtitle: 'Video • 12.4K görüntülenme • 2s',
            onTap: () => _toast('Revz aç: yakında'),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: items.length,
      ),
    ];
  }

  List<Widget> _garageSlivers(bool isDark) {
    final cars = const [
      ('BMW E60', '520d • M Paket • 2010', Icons.directions_car_filled_rounded),
      ('Renault Toros', '1.4 • Efsane • 1998', Icons.local_fire_department_rounded),
    ];
    return [
      SliverList.separated(
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _GarageCard(
            isDark: isDark,
            title: cars[i].$1,
            subtitle: cars[i].$2,
            icon: cars[i].$3,
            onTap: () => _toast('Garage detay: yakında'),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: cars.length,
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: _EditProfileButton(
            isDark: isDark,
            onTap: () => _toast('Araba ekle: yakında'),
            label: 'Araba Ekle',
            icon: Icons.add_rounded,
          ),
        ),
      ),
    ];
  }
}

// -------------------- HEADER CARD --------------------

class _ProfileHeaderCard extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final ImageProvider? coverImg;
  final ImageProvider? avatarImg;
  final String displayName;
  final String bio;
  final String website;
  final String roleText;

  const _ProfileHeaderCard({
    required this.isDark,
    required this.accent,
    required this.coverImg,
    required this.avatarImg,
    required this.displayName,
    required this.bio,
    required this.website,
    required this.roleText,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // cover
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
              image: coverImg != null ? DecorationImage(image: coverImg!, fit: BoxFit.cover) : null,
            ),
            child: coverImg == null
                ? Center(
                    child: Text(
                      'Cover',
                      style: TextStyle(color: fg.withOpacity(0.35), fontWeight: FontWeight.w900),
                    ),
                  )
                : null,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    // avatar
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: accent.withOpacity(isDark ? 0.22 : 0.12),
                        border: Border.all(color: accent.withOpacity(0.40)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: avatarImg != null
                          ? Image(image: avatarImg!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : 'U',
                                style: TextStyle(fontWeight: FontWeight.w900, color: fg),
                              ),
                            ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: fg,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.verified, size: 18, color: accent.withOpacity(0.85)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roleText,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                          if (website.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              website,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: accent.withOpacity(isDark ? 0.95 : 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: const [
                    Expanded(child: _Stat(label: 'Post', value: '128')),
                    SizedBox(width: 10),
                    Expanded(child: _Stat(label: 'Takipçi', value: '24.1K')),
                    SizedBox(width: 10),
                    Expanded(child: _Stat(label: 'Takip', value: '412')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }
}

// -------------------- BUTTONS --------------------

class _EditProfileButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const _EditProfileButton({
    required this.isDark,
    required this.onTap,
    this.label = 'Profili Düzenle',
    this.icon = Icons.edit_outlined,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              accent.withOpacity(isDark ? 0.35 : 0.18),
              accent.withOpacity(isDark ? 0.18 : 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accent.withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.18 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButtonSquare extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonSquare({required this.isDark, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _IconPill({required this.isDark, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}

// -------------------- TABS + CONTENT --------------------

class _Tabs extends StatelessWidget {
  final bool isDark;
  final int tab;
  final ValueChanged<int> onChange;

  const _Tabs({required this.isDark, required this.tab, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);

    Widget chip(int i, IconData icon, String text) {
      final selected = tab == i;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChange(i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withOpacity(isDark ? 0.22 : 0.12)
                  : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? accent.withOpacity(0.55)
                    : (isDark ? Colors.white.withOpacity(0.10) : Colors.black12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                const SizedBox(width: 8),
                Text(text, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(0, Icons.grid_on_rounded, 'Posts'),
        const SizedBox(width: 10),
        chip(1, Icons.play_circle_outline_rounded, 'Revz'),
        const SizedBox(width: 10),
        chip(2, Icons.directions_car_filled_rounded, 'Garage'),
      ],
    );
  }
}

class _GridTile extends StatelessWidget {
  final bool isDark;
  final String label;
  const _GridTile({required this.isDark, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aç: $label (yakında)'), behavior: SnackBarBehavior.floating),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        alignment: Alignment.center,
        child: Text(
          'IMG',
          style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black45),
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RowCard({required this.isDark, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 86,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('VID', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black45)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black54, height: 1.15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _GarageCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GarageCard({required this.isDark, required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: accent.withOpacity(isDark ? 0.22 : 0.12),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black54)),
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
