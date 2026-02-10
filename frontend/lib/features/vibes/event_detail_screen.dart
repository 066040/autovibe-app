import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EventDetailScreen extends StatelessWidget {
  final dynamic event; // _Event tipini import etmeden dynamic kullandım (çakışma olmasın diye)
  final bool isDark;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);
    final cardBg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    // event alanları: title, typeLabel, organizerName, channelName, timeLabel, locationLabel
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          '${event.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
        ),
        iconTheme: IconThemeData(color: textMain),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _toast(context, 'Paylaş: yakında (deep link)');
            },
            icon: Icon(Icons.share_rounded, color: textMain),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          // --- MAP PREVIEW (placeholder) ---
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.map_rounded, color: textSub),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Harita • Konum',
                        style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
                      ),
                    ),
                    _Pill(
                      isDark: isDark,
                      text: event.isPrivate == true ? 'Gizli' : 'Açık',
                      icon: event.isPrivate == true ? Icons.lock_rounded : Icons.public_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark ? const Color(0xFF0E1728) : const Color(0xFFEFF3FA),
                      border: Border.all(color: border),
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
                        Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withOpacity(isDark ? 0.22 : 0.14),
                              border: Border.all(color: accent.withOpacity(0.45)),
                            ),
                            child: Icon(
                              (event.isPrivate == true || event.hasPassword == true)
                                  ? Icons.lock_rounded
                                  : Icons.place_rounded,
                              size: 28,
                              color: (event.isPrivate == true || event.hasPassword == true)
                                  ? (isDark ? Colors.white70 : Colors.black54)
                                  : accent,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Text(
                            '${event.locationLabel}',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: textSub),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- INFO CARD ---
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.title}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textMain, height: 1.1),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(isDark: isDark, text: '${event.typeLabel}', icon: Icons.local_activity_rounded),
                    _Pill(isDark: isDark, text: '${event.timeLabel}', icon: Icons.schedule_rounded),
                    _Pill(isDark: isDark, text: '${event.channelName}', icon: Icons.group_rounded),
                    _Pill(isDark: isDark, text: '${event.organizerName}', icon: Icons.person_rounded),
                    if (event.followersOnly == true)
                      _Pill(isDark: isDark, text: 'Takipçilere', icon: Icons.verified_rounded),
                    if (event.requiresChannelFollow == true)
                      _Pill(isDark: isDark, text: 'Kanal şart', icon: Icons.group_add_rounded),
                    if (event.hasPassword == true)
                      _Pill(isDark: isDark, text: 'Şifreli', icon: Icons.password_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 18, color: textSub),
                    const SizedBox(width: 8),
                    Text(
                      'Katılanlar: ${_mockJoinCount(event.id)}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: textSub),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- ACTIONS ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _toast(context, 'Konuma Git: yakında (maps intent)'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Konuma Git',
                    style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _toast(context, 'Katıldın (mock)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Katıl', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _mockJoinCount(String id) {
    // mock: id’ye göre sabit sayı üretelim
    return 35 + id.codeUnits.fold(0, (a, b) => a + b) % 80;
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Pill extends StatelessWidget {
  final bool isDark;
  final String text;
  final IconData icon;

  const _Pill({required this.isDark, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final bg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA);
    final c = isDark ? Colors.white70 : Colors.black54;

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
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: c)),
        ],
      ),
    );
  }
}
