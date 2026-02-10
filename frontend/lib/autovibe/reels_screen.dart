import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/reactions_controller.dart';
import 'reels_comments_sheet.dart'; 

class ReelsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const ReelsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  late final PageController _controller;
  late int _index;
  int? _poppedIndex;

final List<_ReelItem> _items = const [
  _ReelItem(
    id: 'reel_0',
    articleId: 'cmkiznjwd0003qohmhch22u7y',
    channel: 'vibe_channel',
    caption: 'M3 E46 track day 🔥',
    music: 'AutoVibe • Engine Symphony',
    location: 'İstanbul',
    likes: 12400,
    comments: 312,
    shares: 98,
  ),
  _ReelItem(
    id: 'reel_1',
    articleId: 'cmkiznjwk0004qohmmzsi0lp1',
    channel: 'autovibe_daily',
    caption: 'Gece sürüşü • city lights',
    music: 'AutoVibe • Midnight Drive',
    location: 'Ankara',
    likes: 0,
    comments: 14,
    shares: 220,
  ),
  _ReelItem(
    id: 'reel_2',
    articleId: 'cmkiznjwo0005qohms47tph56',
    channel: 'garage_turkey',
    caption: 'Detaylı yıkama sonrası ✨',
    music: 'AutoVibe • Clean Vibes',
    location: 'İzmir',
    likes: 9800,
    comments: 210,
    shares: 44,
  ),
];

  bool _showBigHeart = false;
  bool _showPlayHint = true;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _items.length - 1);
    _controller = PageController(initialPage: _index);
    Future.delayed(const Duration(milliseconds: 1300), () {
  if (mounted) setState(() => _showPlayHint = false);
});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _likeFromDoubleTap(int i) async {
  await ref.read(reactionsControllerProvider.notifier).toggleLike(_items[i].articleId);

  setState(() => _showBigHeart = true);
  await Future.delayed(const Duration(milliseconds: 520));
  if (mounted) setState(() => _showBigHeart = false);
}

  String _fmtCount(int n) {
  if (n >= 1000000) {
    final v = (n / 1000000);
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)}M';
  }
  if (n >= 1000) {
    final v = (n / 1000);
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)}K';
  }
  return '$n';
}

  void _openComments(BuildContext context, _ReelItem item) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => ReelsCommentsSheet(articleId: item.articleId),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: _items.length,
        onPageChanged: (v) {
  setState(() {
    _index = v;
    _showPlayHint = true;
  });
  Future.delayed(const Duration(milliseconds: 900), () {
    if (mounted) setState(() => _showPlayHint = false);
  });
},
        itemBuilder: (context, i) {
          final item = _items[i];
          final reactions = ref.watch(reactionsControllerProvider);
          final isLiked = reactions.liked.contains(item.articleId);
          final isSaved = reactions.saved.contains(item.articleId);

          return Stack(
            fit: StackFit.expand,
            children: [
              // MEDIA (placeholder)
              GestureDetector(
  onTap: () => setState(() => _showPlayHint = !_showPlayHint),
  onDoubleTap: () => _likeFromDoubleTap(i),
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey.shade900,
          Colors.black,
          Colors.grey.shade900,
        ],
      ),
    ),
    child: Center(
      child: AnimatedOpacity(
        opacity: _showPlayHint ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Icon(
          Icons.play_circle_fill_rounded,
          size: 74,
          color: Colors.white.withOpacity(0.35),
        ),
      ),
    ),
  ),
),
              // BIG HEART (double tap)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showBigHeart ? 1 : 0,
                  duration: const Duration(milliseconds: 140),
                  child: Center(
                    child: AnimatedScale(
                      scale: _showBigHeart ? 1 : 0.9,
                      duration: const Duration(milliseconds: 140),
                      child: Icon(
                        Icons.favorite,
                        size: 96,
                        color: Colors.white.withOpacity(.85),
                      ),
                    ),
                  ),
                ),
              ),

              // TOP BAR (tam üste çivili)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                      children: [
                        _GlassIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Reels',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        _GlassIconButton(
                          icon: Icons.more_vert_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // RIGHT ACTIONS
              Positioned(
                right: 10,
                bottom: 150,
                child: Column(
                  children: [
                    _ActionButton(
  icon: isLiked ? Icons.favorite : Icons.favorite_border,
  countText: _fmtCount(item.likes + (isLiked ? 1 : 0)),
  color: isLiked ? Colors.red : Colors.white,
  scale: _poppedIndex == i ? 1.18 : 1.0,
  onTap: () => ref
    .read(reactionsControllerProvider.notifier)
    .toggleLike(item.articleId),
),

const SizedBox(height: 14),
_ActionButton(
  icon: Icons.mode_comment_outlined,
  countText: _fmtCount(item.comments),
  onTap: () => _openComments(context, item),
),
const SizedBox(height: 14),
_ActionButton(
  icon: Icons.send_outlined,
  countText: _fmtCount(item.shares),
  onTap: () {},
),
const SizedBox(height: 14),
_ActionButton(
  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
  countText: isSaved ? 'Kaydedildi' : 'Kaydet',
  onTap: () => ref
      .read(reactionsControllerProvider.notifier)
      .toggleSaved(item.articleId),
),
                ],
                ),
              ),

              // BOTTOM INFO
              Positioned(
                left: 12,
                right: 90,
                bottom: 22,
                child: _BottomInfo(item: item),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomInfo extends StatelessWidget {
  final _ReelItem item;
  const _BottomInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white12,
              child: Text('V', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Text(
              item.channel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.12),
              ),
              child: Text(
                item.location,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          item.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.graphic_eq_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.music,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String countText;
  final VoidCallback onTap;
  final Color? color;
  final double scale;

  const _ActionButton({
    required this.icon,
    required this.countText,
    required this.onTap,
    this.color,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;

    return SizedBox(
      width: 64,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 140),
              child: Icon(icon, color: c, size: 30),
            ),
            const SizedBox(height: 6),

            // sayı değişince animasyonla akacak
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(anim);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: Text(
                countText,
                key: ValueKey(countText),
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withOpacity(0.10),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String name;
  final String text;
  final DateTime time;
  const _CommentRow({required this.name, required this.text, required this.time});

  String _fmt(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          child: Text(name.isNotEmpty ? name.characters.first.toUpperCase() : 'U'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
                    Text(_fmt(time), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReelItem {
  final String id;        // UI için (reel_0 vs)
  final String articleId; // backend için (cmk...)
  final String channel;
  final String caption;
  final String music;
  final String location;
  final int likes;
  final int comments;
  final int shares;

  const _ReelItem({
    required this.id,
    required this.articleId,
    required this.channel,
    required this.caption,
    required this.music,
    required this.location,
    required this.likes,
    required this.comments,
    required this.shares,
  });
}
