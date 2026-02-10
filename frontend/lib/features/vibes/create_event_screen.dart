import 'package:flutter/material.dart';

enum EventType { meet, sergi, drift, drag, cruise, rota, workshop }
enum EventVisibility { public, private, followersOnly, password }

class CreateEventDraft {
  String title = '';
  EventType type = EventType.meet;
  String channelName = '';
  bool isChannelEvent = true;

  EventVisibility visibility = EventVisibility.public;
  bool requiresChannelFollow = true;
  String password = '';

  String timeLabel = 'Bugün 21:30';
  String locationLabel = 'Konum seç (yakında)';

  double lat = 41.015; // mock Istanbul
  double lng = 28.979;

  CreateEventDraft();
}

class CreateEventScreen extends StatefulWidget {
  final bool isDark;
  final List<String> myChannels; // mock: kullanıcının sahip/takip ettiği kanallar
  const CreateEventScreen({
    super.key,
    required this.isDark,
    required this.myChannels,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  static const accent = Color(0xFF2D6BFF);

  final d = CreateEventDraft();
  final _titleCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);
    final cardBg = widget.isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = widget.isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final textMain = widget.isDark ? Colors.white : Colors.black;
    final textSub = widget.isDark ? Colors.white70 : Colors.black54;
    final can = _canSubmit();
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textMain),
        title: Text('Etkinlik Oluştur', style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
        actions: [
TextButton(
  onPressed: () {
    if (!can) {
      _toast(_whyDisabled());
      return;
    }
    Navigator.pop(context, _buildResult());
  },
  child: Text(
    'Oluştur',
    style: TextStyle(
      fontWeight: FontWeight.w900,
      color: can ? accent : textSub,
    ),
  ),
),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          _Card(
            bg: cardBg,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Başlık', style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
                const SizedBox(height: 8),
                _Input(
                  isDark: widget.isDark,
                  controller: _titleCtrl,
                  hint: 'Örn: BMW Night Meet',
                  onChanged: (v) => setState(() => d.title = v.trim()),
                ),
                const SizedBox(height: 12),

                Text('Etkinlik türü', style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EventType.values.map((t) {
                    final sel = d.type == t;
                    return _Pill(
                      isDark: widget.isDark,
                      selected: sel,
                      text: _typeLabel(t),
                      onTap: () => setState(() => d.type = t),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _Card(
            bg: cardBg,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kanal / Organizasyon', style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _Toggle(
                        isDark: widget.isDark,
                        title: 'Kanal etkinliği',
                        subtitle: 'Kanal üzerinden duyurulsun',
                        value: d.isChannelEvent,
                        onChanged: (v) => setState(() {
                          d.isChannelEvent = v;
                          if (!v) {
                            d.channelName = '';
                            d.requiresChannelFollow = false;
                          } else {
                            d.requiresChannelFollow = true;
                          }
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (d.isChannelEvent) ...[
                  Text('Kanal seç', style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
                  const SizedBox(height: 8),
                  _Dropdown(
                    isDark: widget.isDark,
                    value: d.channelName.isEmpty ? null : d.channelName,
                    items: widget.myChannels,
                    hint: 'Kanal seç…',
                    onChanged: (v) => setState(() => d.channelName = v ?? ''),
                  ),
                  const SizedBox(height: 10),

                  _Toggle(
                    isDark: widget.isDark,
                    title: 'Kanal takip şartı',
                    subtitle: 'Katılmak için kanalı takip etsin',
                    value: d.requiresChannelFollow,
                    onChanged: (v) => setState(() => d.requiresChannelFollow = v),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          _Card(
            bg: cardBg,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gizlilik', style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EventVisibility.values.map((v) {
                    final sel = d.visibility == v;
                    return _Pill(
                      isDark: widget.isDark,
                      selected: sel,
                      text: _visLabel(v),
                      onTap: () => setState(() => d.visibility = v),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),

                if (d.visibility == EventVisibility.password) ...[
                  Text('Şifre', style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
                  const SizedBox(height: 8),
                  _Input(
                    isDark: widget.isDark,
                    controller: null,
                    hint: 'Örn: JDM2026',
                    obscure: true,
                    onChanged: (v) => setState(() => d.password = v.trim()),
                  ),
                  const SizedBox(height: 6),
Text(
  d.password.trim().isEmpty
      ? 'En az 4 karakter gir.'
      : (d.password.trim().length < 4 ? 'Şifre çok kısa (min 4).' : 'Şifre tamam ✅'),
  style: TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 12,
    color: d.password.trim().length >= 4
        ? (widget.isDark ? Colors.white70 : Colors.black54)
        : (widget.isDark ? Colors.white54 : Colors.black45),
  ),
),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          _Card(
            bg: cardBg,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zaman & Konum', style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
                const SizedBox(height: 10),

                _RowButton(
                  isDark: widget.isDark,
                  title: 'Tarih/Saat',
                  value: d.timeLabel,
                  icon: Icons.schedule_rounded,
                  onTap: () => _toast('Şimdilik mock. Sonra date-time picker bağlanacak.'),
                ),
                const SizedBox(height: 10),
                _RowButton(
                  isDark: widget.isDark,
                  title: 'Konum',
                  value: d.locationLabel,
                  icon: Icons.place_rounded,
                  onTap: () => _toast('Şimdilik mock. Sonra haritadan pin seçilecek.'),
                ),

                const SizedBox(height: 10),
                Text(
                  'Not: Harita sağlayıcısını sonra takacağız. Şu an sadece akış ve kurallar.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    if (d.title.trim().length < 3) return false;
    if (d.isChannelEvent && d.channelName.trim().isEmpty) return false;
    if (d.visibility == EventVisibility.password && d.password.trim().length < 4) return false;
    return true;
  }

  Map<String, dynamic> _buildResult() {
    // Bu ekran _Event classını import etmiyor.
    // VibesScreen tarafında kendi _Event modeline map ederek ekleyeceğiz.
    return {
      'title': d.title.trim(),
      'typeLabel': _typeLabel(d.type),
      'channelName': d.isChannelEvent ? d.channelName : 'Bağımsız',
      'isChannelEvent': d.isChannelEvent,
      'visibility': d.visibility.name,
      'requiresChannelFollow': d.isChannelEvent ? d.requiresChannelFollow : false,
      'password': d.visibility == EventVisibility.password ? d.password.trim() : null,
      'timeLabel': d.timeLabel,
      'locationLabel': d.locationLabel,
      'lat': d.lat,
      'lng': d.lng,
    };
  }

  String _typeLabel(EventType t) {
    switch (t) {
      case EventType.meet:
        return 'Meet';
      case EventType.sergi:
        return 'Sergi';
      case EventType.drift:
        return 'Drift';
      case EventType.drag:
        return 'Drag';
      case EventType.cruise:
        return 'Cruise';
      case EventType.rota:
        return 'Rota';
      case EventType.workshop:
        return 'Workshop';
    }
  }

  String _visLabel(EventVisibility v) {
    switch (v) {
      case EventVisibility.public:
        return 'Herkese Açık';
      case EventVisibility.private:
        return 'Gizli';
      case EventVisibility.followersOnly:
        return 'Takipçilere';
      case EventVisibility.password:
        return 'Şifreli';
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
  String _whyDisabled() {
    if (d.title.trim().length < 3) return 'Başlık en az 3 karakter olmalı.';
    if (d.isChannelEvent && d.channelName.trim().isEmpty) return 'Kanal etkinliği için kanal seçmelisin.';
    if (d.visibility == EventVisibility.password && d.password.trim().length < 4) {
    return 'Şifreli etkinlikte şifre en az 4 karakter olmalı.';
    }
    return 'Bilgileri kontrol et.';
  }
}

class _Card extends StatelessWidget {
  final Color bg;
  final Color border;
  final Widget child;

  const _Card({required this.bg, required this.border, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _Input extends StatelessWidget {
  final bool isDark;
  final TextEditingController? controller;
  final String hint;
  final bool obscure;
  final ValueChanged<String> onChanged;

  const _Input({
    required this.isDark,
    required this.controller,
    required this.hint,
    this.obscure = false,
    required this.onChanged,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final bool isDark;
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.isDark,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final bg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA);
    final text = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF0E1728) : Colors.white,
          iconEnabledColor: text,
          hint: Text(hint, style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontWeight: FontWeight.w800)),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontWeight: FontWeight.w700, color: textSub)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final bool isDark;
  final bool selected;
  final String text;
  final VoidCallback onTap;

  const _Pill({
    required this.isDark,
    required this.selected,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);
    final border = selected ? accent.withOpacity(0.55) : (isDark ? Colors.white.withOpacity(0.10) : Colors.black12);
    final bg = selected ? accent.withOpacity(isDark ? 0.22 : 0.12) : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA));
    final c = isDark ? Colors.white : Colors.black;

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
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, color: c)),
      ),
    );
  }
}

class _RowButton extends StatelessWidget {
  final bool isDark;
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _RowButton({
    required this.isDark,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black12;
    final bg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6FA);
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: textSub),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: textMain)),
            ),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: textSub)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: textSub),
          ],
        ),
      ),
    );
  }
}
