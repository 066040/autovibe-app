import 'package:flutter/material.dart';

import '../story/story_camera_screen.dart';
import '../story/story_route.dart';
import 'autovibe_home_screen.dart';

class AutoVibePager extends StatefulWidget {
  const AutoVibePager({super.key});

  @override
  State<AutoVibePager> createState() => _AutoVibePagerState();
}

class _AutoVibePagerState extends State<AutoVibePager> {
  late final PageController _pc;

  bool _opening = false;
  bool _ignoreNextPageChange = false;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: 1); // Home
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _openCameraOverlay() async {
    if (_opening) return;
    _opening = true;

    // ✅ Kamera açmadan önce her zaman Home’a geri dön
    if (_pc.hasClients) {
      _ignoreNextPageChange = true; // jumpToPage onPageChanged tetikleyecek
      _pc.jumpToPage(1);
    }

    try {
      // ✅ root overlay kamera aç
      await Navigator.of(context, rootNavigator: true).push(
        storyCameraRoute(const StoryCameraScreen()),
      );
    } finally {
      _opening = false;

      // küçük bir tick sonra tekrar onPageChanged dinle
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ignoreNextPageChange = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pc,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (i) {
        if (_ignoreNextPageChange) return;

        // sola kaydırınca kamera overlay aç
        if (i == 0) {
          _openCameraOverlay();
        }
      },
      children: const [
        // Kamera sayfası yok: sadece swipe tetikleyici
        SizedBox.shrink(),
        AutoVibeHomeScreen(),
      ],
    );
  }
}
