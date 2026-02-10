import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'event_detail_screen.dart';
import 'events_map_screen.dart';
import 'create_event_screen.dart';

class VibesScreen extends ConsumerStatefulWidget {
  const VibesScreen({super.key});

  @override
  ConsumerState<VibesScreen> createState() => _VibesScreenState();
}

class _VibesScreenState extends ConsumerState<VibesScreen> {
  static const _accent = Color(0xFF2D6BFF);
  late List<_Event> _events;

  final _search = TextEditingController();
  int _chip = 0; // 0: Öne çıkanlar, 1: Yakın etkinlikler, 2: Yeni kanallar, 3: Takip ettiklerim
  @override
  void initState() {
  super.initState();
  _events = List<_Event>.from(_mockEvents);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    final query = _search.text.trim().toLowerCase();

    // --- MOCK STATE (sonra backend/provider’a bağlanacak) ---
    // Senin sisteminde bunlar user/profile/provider’dan gelecek.
    const myUserId = 'u_me';
    final myFollowedChannels = <String>{'BMW Society'}; // örnek: BMW Society takip ediliyor
    final myFollowedOrganizers = <String>{}; // örnek: organizer takip ediliyor

    // --- DATA ---
    final vibeItems = _mockVibes
        .where((e) =>
            e.title.toLowerCase().contains(query) ||
            e.subtitle.toLowerCase().contains(query))
        .toList();

    final eventItems = _events
      .where((e) =>
        e.title.toLowerCase().contains(query) ||
        e.typeLabel.toLowerCase().contains(query) ||
        e.channelName.toLowerCase().contains(query) ||
        e.organizerName.toLowerCase().contains(query))
      .toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            // --- HEADER ---
            Row(
              children: [
                Text(
                  'Vibes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                _IconPill(
                  isDark: isDark,
                  icon: Icons.event_available_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _chip = 1);
                  },
                ),
                const SizedBox(width: 10),
                _IconPill(
  isDark: isDark,
  icon: Icons.add_circle_outline_rounded,
  onTap: () async {
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(
          isDark: isDark,
          myChannels: const ['BMW Society', 'JDM Nights', 'Offroad Crew', 'Detailing Lab', 'Supercar Spot'],
        ),
      ),
    );

    if (res == null) return;

final newEvent = _Event(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: res['title'],
  typeLabel: res['typeLabel'],
  icon: Icons.local_activity_rounded,
  organizerId: 'u_me',
  organizerName: 'Sen',
  channelName: res['channelName'],
  isChannelEvent: res['isChannelEvent'],
  visibility: _EventVisibility.values.firstWhere(
    (v) => v.name == res['visibility'],
  ),
  requiresChannelFollow: res['requiresChannelFollow'],
  password: res['password'],
  timeLabel: res['timeLabel'],
  locationLabel: res['locationLabel'],
  lat: res['lat'],
  lng: res['lng'],
);

  setState(() {
    _events.insert(0, newEvent);
    _chip = 1; // otomatik “Yakın etkinlikler”e geç
  });

  _toast(context, 'Etkinlik oluşturuldu ✅');

    _toast(context, 'Etkinlik taslağı oluştu ✅ (şimdi listeye ekleyeceğiz)');
  },
),
              ],
            ),
            const SizedBox(height: 12),

            // --- SEARCH ---
            _SearchBox(
              controller: _search,
              isDark: isDark,
              hint: _chip == 1 ? 'Etkinlik / kanal / düzenleyici ara…' : 'Kanal / vibe / kullanıcı ara…',
              onChanged: (_) => setState(() {}),
              onClear: () {
                _search.clear();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // --- QUICK CHIPS ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _Chip(
                    isDark: isDark,
                    text: 'Öne çıkanlar',
                    selected: _chip == 0,
                    onTap: () => setState(() => _chip = 0),
                  ),
                  const SizedBox(width: 10),
                  _Chip(
                    isDark: isDark,
                    text: 'Yakın etkinlikler',
                    selected: _chip == 1,
                    onTap: () => setState(() => _chip = 1),
                  ),
                  const SizedBox(width: 10),
                  _Chip(
                    isDark: isDark,
                    text: 'Yeni kanallar',
                    selected: _chip == 2,
                    onTap: () => setState(() => _chip = 2),
                  ),
                  const SizedBox(width: 10),
                  _Chip(
                    isDark: isDark,
                    text: 'Takip ettiklerim',
                    selected: _chip == 3,
                    onTap: () => setState(() => _chip = 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // --- HERO CARD ---
            if (_chip == 1)
              _EventsHero(isDark: isDark)
            else
              _VibesHero(isDark: isDark),

            const SizedBox(height: 12),

            // --- BODY ---
            if (_chip == 1) ...[
              // HARITA (placeholder) + etkinlikler
              _MapPreviewCard(
                isDark: isDark,
                accent: _accent,
                events: eventItems,
                onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EventsMapScreen(events: eventItems, isDark: isDark),
    ),
  );
},
              ),
              const SizedBox(height: 12),

              if (eventItems.isEmpty)
                _Empty(isDark: isDark)
              else
                ...eventItems.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EventCard(
                      isDark: isDark,
                      accent: _accent,
                      data: e,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _openJoinEventSheet(
                          context: context,
                          isDark: isDark,
                          event: e,
                          myUserId: myUserId,
                          myFollowedChannels: myFollowedChannels,
                          myFollowedOrganizers: myFollowedOrganizers,
                        );
                      },
                    ),
                  ),
                ),
            ] else ...[
              // Kanallar / Vibes
              if (vibeItems.isEmpty)
                _Empty(isDark: isDark)
              else
                ...vibeItems.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _VibeCard(
                      isDark: isDark,
                      data: e,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _toast(context, 'Kanal aç: ${e.title} (yakında)');
                      },
                      onFollow: () => _toast(context, 'Takip: ${e.title} (yakında)'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
  void _openJoinEventSheet({
  required BuildContext context,
  required bool isDark,
  required _Event event,
  required String myUserId,
  required Set<String> myFollowedChannels,
  required Set<String> myFollowedOrganizers,
}) {
  final passCtrl = TextEditingController();

  bool channelOk =
      !event.requiresChannelFollow || myFollowedChannels.contains(event.channelName);
  bool followersOk = !event.followersOnly ||
      myFollowedOrganizers.contains(event.organizerId) ||
      event.organizerId == myUserId;
  bool passOk = !event.hasPassword;

  void showError(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setM) {
          final sheetBg = isDark ? const Color(0xFF0E1728) : Colors.white;
          final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;

          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: _accent.withOpacity(isDark ? 0.22 : 0.12),
                        ),
                        child: Icon(event.icon, color: _accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniBadge(
                        isDark: isDark,
                        text: event.isPrivate ? 'Gizli' : 'Açık',
                        icon: event.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                      ),
                      _MiniBadge(isDark: isDark, text: event.typeLabel, icon: Icons.local_activity_rounded),
                      _MiniBadge(isDark: isDark, text: event.channelName, icon: Icons.group_rounded),
                      if (event.followersOnly)
                        _MiniBadge(isDark: isDark, text: 'Sadece takipçilere', icon: Icons.verified_rounded),
                      if (event.hasPassword)
                        _MiniBadge(isDark: isDark, text: 'Şifreli', icon: Icons.password_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (event.followersOnly && !followersOk) ...[
                    _GateRow(
                      isDark: isDark,
                      title: 'Takipçi etkinliği',
                      subtitle: 'Katılmak için düzenleyiciyi takip etmen gerekiyor.',
                      actionText: 'Takip Et (mock)',
                      onAction: () {
                        setM(() {
                          myFollowedOrganizers.add(event.organizerId);
                          followersOk = true;
                        });
                        _toast(context, 'Takip edildi (mock)');
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (event.requiresChannelFollow && !channelOk) ...[
                    _GateRow(
                      isDark: isDark,
                      title: 'Kanal şartı var',
                      subtitle: 'Bu etkinlik “${event.channelName}” için. Önce kanalı takip et.',
                      actionText: 'Kanalı Takip Et (mock)',
                      onAction: () {
                        setM(() {
                          myFollowedChannels.add(event.channelName);
                          channelOk = true;
                        });
                        _toast(context, 'Kanal takip edildi (mock)');
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (event.hasPassword && (channelOk && followersOk)) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.password_rounded, color: isDark ? Colors.white54 : Colors.black38),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: passCtrl,
                              obscureText: true,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Etkinlik şifresi',
                                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                                border: InputBorder.none,
                              ),
                              onChanged: (_) {
                                setM(() => passOk = passCtrl.text.trim() == event.password);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            passOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            color: passOk ? Colors.green : (isDark ? Colors.white38 : Colors.black38),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (event.followersOnly && !followersOk) {
                          showError('Önce düzenleyiciyi takip etmelisin.');
                          return;
                        }
                        if (event.requiresChannelFollow && !channelOk) {
                          showError('Önce kanalı takip etmelisin.');
                          return;
                        }
                        if (event.hasPassword && !passOk) {
                          showError('Şifre yanlış.');
                          return;
                        }

                        Navigator.pop(ctx);
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => EventDetailScreen(event: event, isDark: isDark),
  ),
);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Konumu Göster',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
     },
    ).whenComplete(() => passCtrl.dispose());
  }
}
class _GateRow extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  const _GateRow({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final bg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: isDark ? Colors.white60 : Colors.black45),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ UI Pieces ------------------

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

class _Chip extends StatelessWidget {
  final bool isDark;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.isDark, required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);

    final border = selected
        ? accent.withOpacity(0.55)
        : (isDark ? Colors.white.withOpacity(0.10) : Colors.black12);
    final bg = selected
        ? accent.withOpacity(isDark ? 0.22 : 0.12)
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.white);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.isDark,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black38),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                border: InputBorder.none,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, __) {
              if (v.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, size: 18, color: isDark ? Colors.white54 : Colors.black38),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isDark;
  const _Empty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Text(
        'Sonuç yok.\nBaşka bir arama dene.',
        style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}

// ---- HERO ----

class _VibesHero extends StatelessWidget {
  final bool isDark;
  const _VibesHero({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);
    return Container(
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
            child: const Icon(Icons.auto_awesome_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Senin vibe’ın ne?\nKanal keşfet • editle & paylaş',
              style: TextStyle(
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsHero extends StatelessWidget {
  final bool isDark;
  const _EventsHero({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);
    return Container(
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
            child: const Icon(Icons.event_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Yakın etkinlikler\nMeet • Sergi • Drift • Drag • Cruise',
              style: TextStyle(
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- MAP PREVIEW ----

class _MapPreviewCard extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final List<_Event> events;
  final VoidCallback onTap;

  const _MapPreviewCard({
    required this.isDark,
    required this.accent,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.map_rounded, color: isDark ? Colors.white70 : Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Harita • Etkinlik Pinleri',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(
                  '${events.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark ? const Color(0xFF0B1220) : const Color(0xFFEFF3FA),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: accent.withOpacity(isDark ? 0.20 : 0.12),
                          border: Border.all(color: accent.withOpacity(0.35)),
                        ),
                        child: const Text(
                          'MAP (placeholder)',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    ...List.generate(events.take(4).length, (i) {
                      final e = events[i];
                      final locked = e.isPrivate || e.hasPassword;
                      return Positioned(
                        left: 40.0 + i * 55.0,
                        top: 55.0 + (i.isEven ? 30 : 0),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(isDark ? 0.22 : 0.14),
                            border: Border.all(color: accent.withOpacity(0.45)),
                          ),
                          child: Icon(
                            locked ? Icons.lock_rounded : Icons.place_rounded,
                            size: 18,
                            color: locked ? (isDark ? Colors.white70 : Colors.black54) : accent,
                          ),
                        ),
                      );
                    }),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Row(
                        children: [
                          Icon(Icons.touch_app_rounded, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                          const SizedBox(width: 6),
                          Text(
                            'Dokun: yakında harita',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final _Event data;
  final VoidCallback onTap;

  const _EventCard({
    required this.isDark,
    required this.accent,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final subtle = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
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
              child: Icon(data.icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniBadge(
                        isDark: isDark,
                        text: data.isPrivate ? 'Gizli' : 'Açık',
                        icon: data.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.typeLabel} • ${data.channelName} • ${data.organizerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, color: subtle),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniBadge(isDark: isDark, text: data.timeLabel, icon: Icons.schedule_rounded),
                      _MiniBadge(isDark: isDark, text: data.locationLabel, icon: Icons.place_rounded),
                      if (data.followersOnly) _MiniBadge(isDark: isDark, text: 'Takipçi', icon: Icons.verified_rounded),
                      if (data.requiresChannelFollow) _MiniBadge(isDark: isDark, text: 'Kanal Şart', icon: Icons.group_rounded),
                      if (data.hasPassword) _MiniBadge(isDark: isDark, text: 'Şifreli', icon: Icons.password_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final bool isDark;
  final String text;
  final IconData icon;

  const _MiniBadge({required this.isDark, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final bg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white60 : Colors.black45),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final bool locked;

  const _Pin({required this.isDark, required this.accent, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(isDark ? 0.22 : 0.14),
        border: Border.all(color: accent.withOpacity(0.45)),
      ),
      child: Icon(
        locked ? Icons.lock_rounded : Icons.place_rounded,
        size: 18,
        color: locked ? (isDark ? Colors.white70 : Colors.black54) : accent,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final bool isDark;
  final String text;
  final IconData icon;

  const _Tag({required this.isDark, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final bg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white60 : Colors.black45),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _GateBox extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  const _GateBox({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final bg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: isDark ? Colors.white60 : Colors.black45),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- VIBE CARD (senin eski hali) ----

class _VibeCard extends StatelessWidget {
  final bool isDark;
  final _Vibe data;
  final VoidCallback onTap;
  final VoidCallback onFollow;

  const _VibeCard({required this.isDark, required this.data, required this.onTap, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
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
              child: Icon(data.icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onFollow,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: Text(
                'Takip',
                style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ Mock Data ------------------

class _Vibe {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Vibe(this.title, this.subtitle, this.icon);
}

const _mockVibes = <_Vibe>[
  _Vibe('BMW Society', 'E60 • M Paket • Track days • Buluşmalar', Icons.directions_car_filled_rounded),
  _Vibe('JDM Nights', 'Civic • Supra • Skyline • Edit & Meet', Icons.bolt_rounded),
  _Vibe('Offroad Crew', '4x4 • Rota • Kamp • Çamur', Icons.terrain_rounded),
  _Vibe('Detailing Lab', 'Seramik • Pasta-cila • Ürün testleri', Icons.auto_fix_high_rounded),
  _Vibe('Supercar Spot', 'Macan/Cayenne • AMG • RS • Spot', Icons.local_fire_department_rounded),
];

/// Etkinlik gizliliği (senin anlattığın kurallara göre)
enum _EventVisibility {
  public,        // herkes görür + katılır
  private,       // gizli (link/paylaşım ile) — UI'da “Gizli”
  followersOnly, // sadece düzenleyiciyi takip edenler
  password,      // şifreli (organizer password belirler)
}

/// Etkinlik modeli (şimdilik UI/akış için yeterli)
class _Event {
  final String id;

  // içerik
  final String title;       // "BMW Night Meet"
  final String typeLabel;   // "Meet" / "Sergi" / "Drift" / "Drag" / "Cruise"
  final IconData icon;

  // organizatör
  final String organizerId;     // "u_1"
  final String organizerName;   // "Mert"
  final String channelName;     // "BMW Society" gibi (kanal event'i ise)
  final bool isChannelEvent;    // kanal için mi?

  // kısıtlar
  final _EventVisibility visibility;
  final bool requiresChannelFollow; // kanal event'iyse katılmak için kanalı takip şartı
  final String? password;           // visibility=password ise gerekli

  // zaman/konum (harita pin için)
  final String timeLabel;      // "Bugün 21:30"
  final String locationLabel;  // "Maslak • İstanbul"
  final double lat;
  final double lng;

  const _Event({
    required this.id,
    required this.title,
    required this.typeLabel,
    required this.icon,
    required this.organizerId,
    required this.organizerName,
    required this.channelName,
    required this.isChannelEvent,
    required this.visibility,
    required this.requiresChannelFollow,
    required this.password,
    required this.timeLabel,
    required this.locationLabel,
    required this.lat,
    required this.lng,
  });

  bool get isPrivate => visibility == _EventVisibility.private;
  bool get followersOnly => visibility == _EventVisibility.followersOnly;
  bool get hasPassword => visibility == _EventVisibility.password && (password?.isNotEmpty ?? false);
}

/// Etkinlikler mock listesi
const _mockEvents = <_Event>[
  _Event(
    id: 'e1',
    title: 'BMW Night Meet',
    typeLabel: 'Meet',
    icon: Icons.groups_rounded,
    organizerId: 'u_1',
    organizerName: 'Mert',
    channelName: 'BMW Society',
    isChannelEvent: true,
    visibility: _EventVisibility.public,
    requiresChannelFollow: true, // kanal event’i: önce kanalı takip et
    password: null,
    timeLabel: 'Bugün 21:30',
    locationLabel: 'Maslak • İstanbul',
    lat: 41.1096,
    lng: 29.0205,
  ),
  _Event(
    id: 'e2',
    title: 'JDM Underground Drift',
    typeLabel: 'Drift',
    icon: Icons.auto_awesome_motion_rounded,
    organizerId: 'u_2',
    organizerName: 'Kültigin',
    channelName: 'JDM Nights',
    isChannelEvent: true,
    visibility: _EventVisibility.password, // şifreli paylaşım
    requiresChannelFollow: true,
    password: 'JDM2026',
    timeLabel: 'Cmt 23:00',
    locationLabel: 'Tuzla • İstanbul',
    lat: 40.8183,
    lng: 29.3003,
  ),
  _Event(
    id: 'e3',
    title: 'Supercar Spot & Coffee',
    typeLabel: 'Sergi',
    icon: Icons.local_fire_department_rounded,
    organizerId: 'u_3',
    organizerName: 'Metehan',
    channelName: 'Supercar Spot',
    isChannelEvent: false, // kişi oluşturdu (kanal şartı yok)
    visibility: _EventVisibility.public,
    requiresChannelFollow: false,
    password: null,
    timeLabel: 'Paz 16:00',
    locationLabel: 'Nişantaşı • İstanbul',
    lat: 41.0485,
    lng: 28.9941,
  ),
  _Event(
    id: 'e4',
    title: 'Offroad Mud Run',
    typeLabel: 'Rota',
    icon: Icons.terrain_rounded,
    organizerId: 'u_4',
    organizerName: 'Haluk',
    channelName: 'Offroad Crew',
    isChannelEvent: true,
    visibility: _EventVisibility.followersOnly, // sadece takipçiler
    requiresChannelFollow: true,
    password: null,
    timeLabel: 'Pts 10:00',
    locationLabel: 'Şile • İstanbul',
    lat: 41.1732,
    lng: 29.6126,
  ),
  _Event(
    id: 'e5',
    title: 'Detailing Lab Workshop',
    typeLabel: 'Workshop',
    icon: Icons.auto_fix_high_rounded,
    organizerId: 'u_5',
    organizerName: 'Selim',
    channelName: 'Detailing Lab',
    isChannelEvent: true,
    visibility: _EventVisibility.private, // gizli (link ile)
    requiresChannelFollow: true,
    password: null,
    timeLabel: 'Sal 19:30',
    locationLabel: 'Kadıköy • İstanbul',
    lat: 40.9917,
    lng: 29.0297,
  ),
];
