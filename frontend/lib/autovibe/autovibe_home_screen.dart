import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'reels_screen.dart';

class AutoVibeHomeScreen extends StatelessWidget {
  const AutoVibeHomeScreen({super.key});

  // Demo verilerini biraz daha zenginleştirelim
  static final _demoFeed = <_FeedPost>[
    const _FeedPost(
      username: 'vibe_channel',
      location: 'İstanbul, Türkiye',
      timeAgo: '2s',
      caption: 'M3 E46 track day! Motorun sesini duymanız lazım 🏎️💨 #bmw #m3 #trackday',
      likes: 1243,
      comments: 45,
      imageUrl: 'https://images.unsplash.com/photo-1617788138017-80ad40651399?q=80&w=1000&auto=format&fit=crop',
      isVideo: true,
    ),
    const _FeedPost(
      username: 'autovibe_daily',
      location: 'Ankara',
      timeAgo: '15d',
      caption: 'Gece sürüşü terapisi. Şehir ışıkları ve boş yollar. 🌃',
      likes: 892,
      comments: 12,
      imageUrl: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?q=80&w=1000&auto=format&fit=crop',
      isVideo: false,
    ),
    const _FeedPost(
      username: 'garage_turkey',
      location: 'İzmir',
      timeAgo: '1g',
      caption: 'Detaylı yıkama sonrası seramik kaplama farkı ✨ Parlıyor!',
      likes: 3504,
      comments: 128,
      imageUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?q=80&w=1000&auto=format&fit=crop',
      isVideo: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Arkaplan rengini Instagram gibi (Light: Beyaz, Dark: Siyah) yapalım
    final bgColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      // AppBar'ı daha modern hale getiriyoruz
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Material 3 tint'i kapat
        title: Text(
          'AutoVibe',
          style: TextStyle(
            fontFamily: 'Cursive', // Varsa özel font (örn: Billabong)
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          _AppBarAction(icon: Icons.favorite_border_rounded, onTap: () {}),
          _AppBarAction(icon: Icons.chat_bubble_outline_rounded, onTap: () {}),
          const SizedBox(width: 8),
    ],
  ),body: RefreshIndicator(
  onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
  color: Colors.redAccent,
  child: ListView.builder(
    physics: const BouncingScrollPhysics(),
    itemCount: 1 + _demoFeed.length,
    itemBuilder: (context, i) {
      if (i == 0) return const _StoriesSection();
      final post = _demoFeed[i - 1];
      return _InstagramPostItem(
        post: post,
        onOpenReels: () => _openReels(context, initialIndex: i - 1),
        onOpenComments: () => _openCommentsSheet(context, post),
      );
    },
  ),
),
    );
  }

  void _openReels(BuildContext context, {required int initialIndex}) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ReelsScreen(initialIndex: initialIndex)),
    );
  }

  void _openCommentsSheet(BuildContext context, _FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(post: post),
    );
  }
}

/// ===============================
/// WIDGETS & COMPONENTS
/// ===============================

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 20,
      icon: Icon(icon, size: 26, color: Theme.of(context).colorScheme.onSurface),
    );
  }
}

// STORIES
class _StoriesSection extends StatelessWidget {
  const _StoriesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 106,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final isMe = i == 0;
          return _StoryItem(index: i, isMe: isMe);
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final int index;
  final bool isMe;

  const _StoryItem({required this.index, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Instagram Gradient Ring
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isMe
                    ? null // Kendimsem halka yok (veya gri)
                    : const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFFC32AA3), // Mor
                          Color(0xFFF46F30), // Turuncu
                          Color(0xFFFFC328), // Sarı
                        ],
                      ),
              ),
            ),
            // White Border spacing
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            // Avatar Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                      'https://i.pravatar.cc/150?u=${900 + index}'), // Random avatar
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // "Add Story" Badge
            if (isMe)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isMe ? 'Hikayen' : 'user_$index',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

// POST ITEM (INSTAGRAM STYLE)
class _InstagramPostItem extends StatefulWidget {
  final _FeedPost post;
  final VoidCallback onOpenReels;
  final VoidCallback onOpenComments;

  const _InstagramPostItem({
    required this.post,
    required this.onOpenReels,
    required this.onOpenComments,
  });

  @override
  State<_InstagramPostItem> createState() => _InstagramPostItemState();
}

class _InstagramPostItemState extends State<_InstagramPostItem>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  late AnimationController _heartAnimCtrl;
  late Animation<double> _heartAnim;
  bool _showBigHeart = false;

  @override
  void initState() {
    super.initState();
    _heartAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _heartAnim = Tween(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartAnimCtrl, curve: Curves.elasticOut),
    );

    _heartAnimCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 100), () {
           if(mounted) setState(() => _showBigHeart = false);
           _heartAnimCtrl.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _heartAnimCtrl.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    setState(() {
      _isLiked = true;
      _showBigHeart = true;
    });
    _heartAnimCtrl.forward();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.post;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${p.username}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (p.location.isNotEmpty)
                      Text(
                        p.location,
                        style: TextStyle(
                            fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
                splashRadius: 20,
              ),
            ],
          ),
        ),

        // 2. MEDIA (Edge-to-Edge)
        GestureDetector(
          onDoubleTap: _handleDoubleTap,
          onTap: widget.onOpenReels, // Tek tıkla reels aç
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5, // Instagram Portrait Ratio
                child: Image.network(
                  p.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(color: Colors.grey.shade900); // Placeholder
                  },
                  errorBuilder: (ctx, _, __) => Container(color: Colors.grey.shade900),
                ),
              ),
              // Big Heart Animation
              if (_showBigHeart)
                ScaleTransition(
                  scale: _heartAnim,
                  child: const Icon(Icons.favorite, color: Colors.white, size: 100),
                ),
              // Video Icon (Reels Indicator)
              if (p.isVideo)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),

        // 3. ACTION BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              _ActionIcon(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? const Color(0xFFFF3040) : null,
                onTap: () {
                  setState(() => _isLiked = !_isLiked);
                  if (_isLiked) HapticFeedback.selectionClick();
                },
              ),
              const SizedBox(width: 16),
              _ActionIcon(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: widget.onOpenComments,
              ),
              const SizedBox(width: 16),
              _ActionIcon(
                icon: Icons.send_rounded,
                onTap: () {}, // DM / Share
              ),
              const Spacer(),
              _ActionIcon(
                icon: Icons.bookmark_border_rounded,
                onTap: () {}, // Save
              ),
            ],
          ),
        ),

        // 4. LIKES & CAPTION
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p.likes} beğenme',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  children: [
                    TextSpan(
                      text: p.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(text: p.caption),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (p.comments > 0)
                GestureDetector(
                  onTap: widget.onOpenComments,
                  child: Text(
                    '${p.comments} yorumun tümünü gör',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                p.timeAgo,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 28, // Instagram icons are slightly larger
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// COMMENTS SHEET
class _CommentsSheet extends StatelessWidget {
  final _FeedPost post;
  const _CommentsSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text("Yorumlar", style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: 10,
                itemBuilder: (_, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${i + 100}'),
                    radius: 16,
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                      children: [
                        TextSpan(
                            text: 'user_comment_$i ',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: 'Harika bir paylaşım! 🔥'),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                ),
              ),
            ),
            // Comment Input Area
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 18, child: Text("Sen")),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Yorum ekle...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Paylaş"),
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// MODEL
class _FeedPost {
  final String username;
  final String location;
  final String timeAgo;
  final String caption;
  final int likes;
  final int comments;
  final String imageUrl;
  final bool isVideo;

  const _FeedPost({
    required this.username,
    required this.location,
    required this.timeAgo,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.imageUrl,
    required this.isVideo,
  });
}