import 'package:flutter/material.dart';

class EventsMapScreen extends StatelessWidget {
  final List<dynamic> events; // _Event import etmiyoruz diye dynamic
  final bool isDark;

  const EventsMapScreen({
    super.key,
    required this.events,
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textMain),
        title: Text(
          'Etkinlik Haritası',
          style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
        ),
      ),
      body: Column(
        children: [
          // --- MAP AREA (placeholder) ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E1728) : const Color(0xFFEFF3FA),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: accent.withOpacity(isDark ? 0.20 : 0.12),
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: const Text(
                        'AUTOvibe MAP • placeholder',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),

                  // Sahte pinler
                  ...List.generate(events.take(8).length, (i) {
                    final e = events[i];
                    final locked = (e.isPrivate == true) || (e.hasPassword == true);

                    return Positioned(
                      left: 30.0 + (i % 4) * 85.0,
                      top: 80.0 + (i ~/ 4) * 110.0,
                      child: _Pin(
                        accent: accent,
                        locked: locked,
                        isDark: isDark,
                      ),
                    );
                  }),

                  Positioned(
                    right: 14,
                    top: 14,
                    child: Column(
                      children: [
                        _FabPill(
                          isDark: isDark,
                          icon: Icons.my_location_rounded,
                          onTap: () => _toast(context, 'Konum: yakında'),
                        ),
                        const SizedBox(height: 10),
                        _FabPill(
                          isDark: isDark,
                          icon: Icons.tune_rounded,
                          onTap: () => _toast(context, 'Filtre: yakında'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTTOM LIST PREVIEW ---
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(Icons.local_activity_rounded, color: textSub),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${events.length} etkinlik • Pinlere tıklayınca detay açılacak',
                    style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
                  ),
                ),
                TextButton(
                  onPressed: () => _toast(context, 'Liste görünümü: yakında'),
                  child: Text(
                    'Liste',
                    style: TextStyle(fontWeight: FontWeight.w900, color: textSub),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Pin extends StatelessWidget {
  final Color accent;
  final bool locked;
  final bool isDark;

  const _Pin({required this.accent, required this.locked, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(isDark ? 0.22 : 0.14),
        border: Border.all(color: accent.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 2,
            color: accent.withOpacity(0.18),
          ),
        ],
      ),
      child: Icon(
        locked ? Icons.lock_rounded : Icons.place_rounded,
        size: 22,
        color: locked ? (isDark ? Colors.white70 : Colors.black54) : accent,
      ),
    );
  }
}

class _FabPill extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _FabPill({required this.isDark, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final bg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}
