import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'news_controller.dart';
import 'models/news_item.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  static const _accent = Color(0xFF2D6BFF);

  int _tab = 0;
  String _query = '';

  final Set<String> _savedIds = <String>{};

  final _scroll = ScrollController();

  final sections = const <String>[
    'Öne Çıkanlar',
    'Türkiye',
    'Dünya',
    'Test',
    'Elektrikli',
    'Piyasa',
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Sona yaklaşınca pagination
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent <= 0) return;

    if (pos.pixels > pos.maxScrollExtent - 400) {
      final q = _buildQuery();
      ref.read(newsControllerProvider(q).notifier).fetchMore();
    }
  }

  NewsQuery _buildQuery() {
    final category = sections[_tab];
    return NewsQuery(
      category: category == 'Öne Çıkanlar' ? '' : category,
      q: _query.trim(),
    );
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    final q = _buildQuery();
    await ref.read(newsControllerProvider(q).notifier).refresh();
  }

  void _toggleSave(NewsItem it) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_savedIds.contains(it.id)) {
        _savedIds.remove(it.id);
        _toast('Kaydedilenlerden çıkarıldı');
      } else {
        _savedIds.add(it.id);
        _toast('Kaydedildi');
      }
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    final q = _buildQuery();
    final st = ref.watch(newsControllerProvider(q));
    final items = st.items;

    // Editör seçimi: ilk 1’den sonraki 6 tane (istersen sonra backend’den flag’li yaparız)
    final editorPicks = items.length > 1
    ? items.skip(1).take(6).toList()
    : const <NewsItem>[];

    // Akış: editör seçimi için ayırdıklarımızın sonrası
    final feedItems = items.length > 7
    ? items.skip(7).toList()
    : const <NewsItem>[];

    // spotlight: ilk item varsa onu al (istersen backend’de featured mantığı kurarız)
    final spotlight = st.items.isNotEmpty ? st.items.first : null;
    final listItems = st.items.length <= 1 ? const <NewsItem>[] : st.items.sublist(1);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // --- TOP BAR ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'News',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      _IconPill(
                        isDark: isDark,
                        icon: Icons.notifications_none_rounded,
                        onTap: () => _toast('Bildirimler: yakında'),
                      ),
                      const SizedBox(width: 10),
                      _IconPill(
                        isDark: isDark,
                        icon: Icons.tune_rounded,
                        onTap: () => _toast('Filtreler: yakında'),
                      ),
                    ],
                  ),
                ),
              ),

              // --- SEARCH ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: _SearchBar(
                    isDark: isDark,
                    value: _query,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () => setState(() => _query = ''),
                  ),
                ),
              ),

              // --- TABS ---
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) {
                      final selected = _tab == i;
                      return InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _tab = i);
                          // tab değişince liste başına dön
                          _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? _accent.withOpacity(isDark ? 0.22 : 0.12)
                                : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? _accent.withOpacity(0.55)
                                  : (isDark ? Colors.white.withOpacity(0.10) : Colors.black12),
                            ),
                          ),
                          child: Text(
                            sections[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: sections.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // --- ERROR ---
              if (st.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _EmptyState(
                      isDark: isDark,
                      title: 'Hata',
                      subtitle: st.error!,
                    ),
                  ),
                ),

              // --- LOADING (ilk yükleme) ---
              if (st.loading && st.items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _EmptyState(
                      isDark: isDark,
                      title: 'Yükleniyor…',
                      subtitle: 'Haberler getiriliyor',
                    ),
                  ),
                ),

              // --- HERO SPOTLIGHT ---
              if (!st.loading && spotlight != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _HeroSpotlight(
                      isDark: isDark,
                      item: spotlight,
                      isSaved: _savedIds.contains(spotlight.id),
                      onToggleSave: () => _toggleSave(spotlight),
                      onShare: () => _toast('Paylaş: yakında'),
                      onTap: () => _openDetail(context, spotlight),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
              ],
if (!st.loading && editorPicks.isNotEmpty) ...[
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _SectionHeader(
        isDark: isDark,
        title: 'Editörün seçimi',
        actionText: 'Tümü',
        onAction: () => _toast('Editörün seçimi: yakında'),
      ),
    ),
  ),
  SliverToBoxAdapter(
    child: SizedBox(
      height: 310,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) {
          final it = editorPicks[i];
          return _EditorPickCard(
            isDark: isDark,
            item: it,
            isSaved: _savedIds.contains(it.id),
            onToggleSave: () => _toggleSave(it),
            onShare: () => _toast('Paylaş: yakında'),
            onTap: () => _openDetail(context, it),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: editorPicks.length,
      ),
    ),
  ),
],
              // --- LIST HEADER ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SectionHeader(
                    isDark: isDark,
                    title: 'Akış',
                    actionText: 'Yenile',
                    onAction: _refresh,
                  ),
                ),
              ),

              if (!st.loading && listItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _EmptyState(
                      isDark: isDark,
                      title: 'Sonuç yok',
                      subtitle: 'Filtreyi değiştir veya aramayı temizle.',
                    ),
                  ),
                )
              else
                SliverList.separated(
                  itemBuilder: (_, i) {
                    final it = feedItems[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _NewsRow(
                        isDark: isDark,
                        item: it,
                        isSaved: _savedIds.contains(it.id),
                        onToggleSave: () => _toggleSave(it),
                        onShare: () => _toast('Paylaş: yakında'),
                        onTap: () => _openDetail(context, it),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: feedItems.length,
                ),

              // --- LOADING MORE FOOTER ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: st.loadingMore
                      ? _LoadingPill(isDark: isDark)
                      : (st.nextCursor == null && st.items.isNotEmpty)
                          ? _EndPill(isDark: isDark)
                          : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, NewsItem it) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(
          item: it,
          isSaved: _savedIds.contains(it.id),
          onToggleSave: () => _toggleSave(it),
        ),
      ),
    );
  }
}

// -------------------- DETAIL --------------------

class NewsDetailScreen extends StatelessWidget {
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const NewsDetailScreen({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Haber'),
        actions: [
          IconButton(
            onPressed: onToggleSave,
            icon: Icon(isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paylaş: yakında'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: const Icon(Icons.share_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            item.category.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaPill(text: item.source, isDark: isDark),
              const SizedBox(width: 8),
              _MetaPill(text: item.timeAgo, isDark: isDark),
              const Spacer(),
              Icon(isSaved ? Icons.bookmark_rounded : Icons.bookmark_border,
                  color: isDark ? Colors.white54 : Colors.black54),
            ],
          ),
          const SizedBox(height: 14),
          _DetailHero(isDark: isDark, imageUrl: item.imageUrl),
          const SizedBox(height: 14),
          Text(
            item.summary.isEmpty ? 'Özet yok.' : item.summary,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- WIDGETS --------------------

class _SearchBar extends StatelessWidget {
  final bool isDark;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.isDark,
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: isDark ? Colors.white60 : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value)
                ..selection = TextSelection.collapsed(offset: value.length),
              onChanged: onChanged,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Haberlerde ara…',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (value.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white60 : Colors.black45),
              ),
            ),
          ],
        ],
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

class _SectionHeader extends StatelessWidget {
  final bool isDark;
  final String title;
  final String actionText;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.isDark,
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                actionText,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _HeroSpotlight extends StatelessWidget {
  final bool isDark;
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const _HeroSpotlight({
    required this.isDark,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
    required this.onShare,
    required this.onTap,
  });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F4F7),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _MetaPill(text: item.category, isDark: isDark),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Row(
                      children: [
                        _ActionIcon(
                          isDark: isDark,
                          icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          onTap: onToggleSave,
                        ),
                        const SizedBox(width: 8),
                        _ActionIcon(
                          isDark: isDark,
                          icon: Icons.share_outlined,
                          onTap: onShare,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Text(
                      'Öne çıkan görsel',
                      style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white60 : Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MetaPill(text: item.source, isDark: isDark),
                const SizedBox(width: 8),
                _MetaPill(text: item.timeAgo, isDark: isDark),
                const Spacer(),
                Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.isDark, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black12),
        ),
        child: Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;
  final bool isDark;

  const _MetaPill({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            height: 1.0,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  final bool isDark;
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const _NewsRow({
    required this.isDark,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
    required this.onShare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeColor = isDark ? Colors.white60 : Colors.black45;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ANA İÇERİK (zamanla çakışmasın diye üstten boşluk bıraktık)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- IMG (HİÇ DOKUNMADIK) ---
                  Container(
                    width: 86,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'IMG',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // --- CONTENT ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kaynak – tek satır
                        Text(
                          item.source,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Başlık – max 2 satır
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            height: 1.15,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Özet – max 2 satır
                        if (item.summary.trim().isNotEmpty)
                          Text(
                            item.summary.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.8,
                              height: 1.2,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // --- ACTIONS ---
                  Column(
                    children: [
                      _TinyIcon(
                        isDark: isDark,
                        icon: isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        onTap: onToggleSave,
                      ),
                      const SizedBox(height: 6),
                      _TinyIcon(
                        isDark: isDark,
                        icon: Icons.share_outlined,
                        onTap: onShare,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ ZAMAN: EN ÜSTTE (Stack'in SONUNDA)
            Positioned(
              left: 14,
              top: 8,
              child: Text(
                item.timeAgo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: timeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _TinyIcon({required this.isDark, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        child: Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final bool isDark;
  final String? imageUrl;

  const _DetailHero({required this.isDark, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F4F7),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Text(
        imageUrl == null ? 'Haber görseli (yakında)' : 'Görsel URL var (sonra bağlarız)',
        style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white60 : Colors.black45),
      ),
    );
  }
}

class _EditorPickCard extends StatelessWidget {
  final bool isDark;
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const _EditorPickCard({
    required this.isDark,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
    required this.onShare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.06),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Büyük görsel alanı
            Container(
              height: 145,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F4F7),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'Görsel',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ),

                  // Sol üst: zaman (pill yok)
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Text(
                      item.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ),

                  // Sağ üst aksiyonlar
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Row(
                      children: [
                        _ActionIcon(
                          isDark: isDark,
                          icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          onTap: onToggleSave,
                        ),
                        const SizedBox(width: 8),
                        _ActionIcon(
                          isDark: isDark,
                          icon: Icons.share_outlined,
                          onTap: onShare,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Kaynak tek satır
            Text(
              item.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),

            const SizedBox(height: 6),

            // Başlık 2 satır
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15.5,
                height: 1.15,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            // Özet 2 satır
            if (item.summary.trim().isNotEmpty)
              Text(
                item.summary.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.8,
                  height: 1.2,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _EmptyState({required this.isDark, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontWeight: FontWeight.w700, height: 1.25, color: isDark ? Colors.white60 : Colors.black54),
          ),
        ],
      ),
    );
  }
}
class _ThumbWithTime extends StatelessWidget {
  final bool isDark;
  final String timeText;

  const _ThumbWithTime({
    required this.isDark,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 64,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'IMG',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 6,
            child: Text(
              timeText,
              style: TextStyle(
                fontSize: 11,
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
class _SourceLine extends StatelessWidget {
  final bool isDark;
  final String text;

  const _SourceLine({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 12.2,
        height: 1.0,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  final bool isDark;
  const _LoadingPill({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 10),
          Text(
            'Daha fazla yükleniyor…',
            style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _EndPill extends StatelessWidget {
  final bool isDark;
  const _EndPill({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Text(
        'Hepsi bu kadar 👌',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}
