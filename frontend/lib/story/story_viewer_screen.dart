import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'story_models.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryDraft> items;
  const StoryViewerScreen({super.key, required this.items});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _i = 0;
  VideoPlayerController? _vp;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _vp?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _vp?.dispose();
    _vp = null;

    final item = widget.items[_i];
    if (item.type == StoryMediaType.video) {
      final vp = VideoPlayerController.file(File(item.filePath));
      _vp = vp;
      await vp.initialize();
      await vp.setLooping(true);
      await vp.play();
    }
    if (mounted) setState(() {});
  }

  void _next() async {
    if (_i >= widget.items.length - 1) {
      Navigator.pop(context);
      return;
    }
    _i++;
    await _load();
  }

  void _prev() async {
    if (_i <= 0) return;
    _i--;
    await _load();
  }

  void _pause() {
    _holding = true;
    _vp?.pause();
    setState(() {});
  }

  void _resume() {
    _holding = false;
    _vp?.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_i];
    final isVideo = item.type == StoryMediaType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (d) {
          if (d.delta.dy > 12) Navigator.pop(context);
        },
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          if (d.localPosition.dx < w * 0.35) {
            _prev();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          children: [
            Positioned.fill(
              child: isVideo ? _buildVideo() : _buildImage(item.filePath),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const CircleAvatar(radius: 14, backgroundColor: Colors.white24),
                    const SizedBox(width: 8),
                    const Text(
                      'autonews',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    const Text('• şimdi', style: TextStyle(color: Colors.white70)),
                    const Spacer(),
                    if (_holding)
                      const Text('Duraklatıldı', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    return FittedBox(
      fit: BoxFit.cover,
      child: Image.file(File(path)),
    );
  }

  Widget _buildVideo() {
    final vp = _vp;
    if (vp == null || !vp.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: vp.value.size.width,
        height: vp.value.size.height,
        child: VideoPlayer(vp),
      ),
    );
  }
}
