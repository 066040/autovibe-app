// lib/story/story_camera_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'story_editor_screen.dart';
import 'story_models.dart';

enum _CaptureTab { post, story, reels }
enum _LeftMode { create, boomerang, layout }

class StoryCameraScreen extends StatefulWidget {
  const StoryCameraScreen({super.key});

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<StoryCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;

  // IG benzeri “mute” (UI) – controller enableAudio runtime değişmez,
  // ama giriş ekranında birebir ikon davranışı için state tutuyoruz.
  bool _mutedUi = true;

  // Zoom & Flash
  FlashMode _flashMode = FlashMode.off;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseScale = 1.0;

  // Focus
  Offset? _focusPoint;
  Timer? _focusResetTimer;

  // Video Timer
  DateTime? _recStartTime;
  Timer? _recTimer;
  static const Duration _maxVideoDuration = Duration(seconds: 15);

  // UI State (IG)
  _CaptureTab _tab = _CaptureTab.story;
  _LeftMode _leftMode = _LeftMode.create;

  // Animasyon
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  // alt sekme indicator animasyonu
  late final AnimationController _tabAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..value = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initCameraFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _recTimer?.cancel();
    _focusResetTimer?.cancel();
    _pulseController.dispose();
    _tabAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraFlow();
    }
  }

  // ---------------- KAMERA KURULUMU ----------------

  Future<void> _initCameraFlow() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || microphoneStatus.isDenied) {
      _showError('Kamera ve mikrofon izni gerekli.');
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showError('Cihazda kamera bulunamadı.');
        return;
      }

      if (_controller == null) {
        final backIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
        _cameraIndex = backIndex != -1 ? backIndex : 0;
      }

      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      _showError('Kamera başlatılamadı: $e');
    }
  }

  Future<void> _startCamera(CameraDescription cameraDescription) async {
    final prev = _controller;
    if (prev != null) await prev.dispose();

    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.veryHigh,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    _controller = controller;

    try {
      await controller.initialize();
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = 1.0;
      await controller.setZoomLevel(_currentZoom);
      await controller.setFlashMode(_flashMode);

      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } on CameraException catch (e) {
      debugPrint('Camera Exception: ${e.description}');
      _showError('Kamera hatası.');
    } catch (e) {
      debugPrint('Error: $e');
      _showError('Kamera başlatılamadı.');
    }
  }

  // ---------------- AKSİYONLAR ----------------

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording || _isProcessing) return;
    setState(() => _isCameraInitialized = false);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_cameraIndex]);
  }

  void _toggleFlash() {
    if (_controller == null) return;
    const modes = [FlashMode.off, FlashMode.auto, FlashMode.always, FlashMode.torch];
    final i = modes.indexOf(_flashMode);
    final next = (i + 1) % modes.length;
    setState(() => _flashMode = modes[next]);
    _controller!.setFlashMode(_flashMode);
  }

  void _toggleMutedUi() {
    setState(() => _mutedUi = !_mutedUi);
    HapticFeedback.selectionClick();
  }

  Future<void> _onTapFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_isCameraInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    setState(() => _focusPoint = offset);

    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
    } catch (_) {}

    _focusResetTimer?.cancel();
    _focusResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _focusPoint = null);
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentZoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null) return;
    double scale = _baseScale * details.scale;
    if (scale < _minZoom) scale = _minZoom;
    if (scale > _maxZoom) scale = _maxZoom;

    if (scale != _currentZoom) {
      _currentZoom = scale;
      await _controller!.setZoomLevel(scale);
    }
  }

  // ---------------- ÇEKİM (FOTO & VIDEO) ----------------

  Future<void> _takePhoto() async {
    if (_leftMode == _LeftMode.create) {
      _showError('Oluştur modu yakında.');
      return;
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile file = await c.takePicture();
      if (!mounted) return;
      _goToEditor(file.path, StoryMediaType.photo);
    } catch (_) {
      _showError('Fotoğraf çekilemedi.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _startVideoRecording() async {
    if (_leftMode == _LeftMode.create) return;

    final c = _controller;
    if (c == null || !c.value.isInitialized || _isProcessing) return;

    try {
      await c.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recStartTime = DateTime.now();
      });

      _recTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted) return;
        final duration = DateTime.now().difference(_recStartTime!);
        if (duration >= _maxVideoDuration) {
          _stopVideoRecording();
        } else {
          setState(() {});
        }
      });

      HapticFeedback.lightImpact();
    } catch (_) {
      _showError('Video başlatılamadı.');
    }
  }

  Future<void> _stopVideoRecording() async {
    final c = _controller;
    if (c == null || !_isRecording) return;

    _recTimer?.cancel();
    _recTimer = null;

    setState(() => _isProcessing = true);

    try {
      final XFile file = await c.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _recStartTime = null;
      });

      if (!mounted) return;
      _goToEditor(file.path, StoryMediaType.video);
    } catch (_) {
      _showError('Video kaydedilemedi.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    try {
      final picker = ImagePicker();
      final XFile? media = await picker.pickMedia();
      if (media != null && mounted) {
        final path = media.path.toLowerCase();
        final isVideo = path.endsWith('.mp4') || path.endsWith('.mov');
        _goToEditor(media.path, isVideo ? StoryMediaType.video : StoryMediaType.photo);
      }
    } catch (_) {
      _showError('Galeri açılamadı.');
    }
  }

  void _goToEditor(String path, StoryMediaType type) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => StoryEditorScreen(
          draft: StoryDraft(type: type, filePath: path),
        ),
      ),
    );
  }

  void _openSettingsSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                _SheetTile(
                  icon: Icons.flash_on,
                  title: 'Flaş',
                  subtitle: _flashMode.name,
                  onTap: () {
                    Navigator.pop(context);
                    _toggleFlash();
                  },
                ),
                _SheetTile(
                  icon: Icons.hdr_strong,
                  title: 'Efektler',
                  subtitle: 'Yakında',
                  onTap: () => Navigator.pop(context),
                ),
                _SheetTile(
                  icon: Icons.tune,
                  title: 'Gelişmiş',
                  subtitle: 'Yakında',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          _buildGestureLayer(),

          // IG UI overlays
          _buildTopBar(),
          _buildLeftModes(),
          _buildBottomBar(),

          if (!_isCameraInitialized || _isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return Container(color: Colors.black);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        var scale = size.aspectRatio * c.value.aspectRatio;
        if (scale < 1) scale = 1 / scale;

        return Transform.scale(
          scale: scale,
          child: Center(child: CameraPreview(c)),
        );
      },
    );
  }

  Widget _buildGestureLayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onTapDown: (details) => _onTapFocus(details, constraints),
          child: Stack(
            children: [
              if (_focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx * constraints.maxWidth - 25,
                  top: _focusPoint!.dy * constraints.maxHeight - 25,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // sağdaki ince “zoom track” hissi (IG gibi)
              Positioned(
                right: 14,
                top: MediaQuery.of(context).padding.top + 86,
                bottom: MediaQuery.of(context).padding.bottom + 170,
                child: Opacity(
                  opacity: 0.55,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.14,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: top + 10,
      left: 10,
      right: 10,
      child: Row(
        children: [
          _TopIconButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          _TopIconButton(
            icon: _mutedUi ? Icons.volume_off : Icons.volume_up,
            onTap: _toggleMutedUi,
          ),
          const SizedBox(width: 10),
          _TopIconButton(
            icon: Icons.settings,
            onTap: _openSettingsSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftModes() {
    final isCompact = _tab == _CaptureTab.reels;
    final left = 16.0;
    final top = MediaQuery.of(context).padding.top + 120;

    return Positioned(
      left: left,
      top: top,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeftModeTile(
            selected: _leftMode == _LeftMode.create,
            icon: Icons.text_fields,
            label: 'Oluştur',
            compact: isCompact,
            onTap: () => setState(() => _leftMode = _LeftMode.create),
          ),
          const SizedBox(height: 14),
          _LeftModeTile(
            selected: _leftMode == _LeftMode.boomerang,
            icon: Icons.all_inclusive,
            label: 'Boomerang',
            compact: isCompact,
            onTap: () => setState(() => _leftMode = _LeftMode.boomerang),
          ),
          const SizedBox(height: 14),
          _LeftModeTile(
            selected: _leftMode == _LeftMode.layout,
            icon: Icons.grid_view_rounded,
            label: 'Yerleşim',
            compact: isCompact,
            onTap: () => setState(() => _leftMode = _LeftMode.layout),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => HapticFeedback.selectionClick(),
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomPad + 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // capture row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // gallery
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.2),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                  ),
                ),

                const Spacer(),

                // main capture
                _IGCaptureButton(
                  isRecording: _isRecording,
                  pulseAnimation: _pulseController,
                  progress: _getVideoProgress(),
                  onTap: _takePhoto,
                  onLongPressStart: _startVideoRecording,
                  onLongPressEnd: _stopVideoRecording,
                ),

                const Spacer(),

                // lens/effects (iki yuvarlak)
                Row(
                  children: [
                    _SmallCircle(
                      child: const Icon(Icons.blur_on, color: Colors.white, size: 18),
                      onTap: () => _showError('Efektler yakında.'),
                    ),
                    const SizedBox(width: 10),
                    _SmallCircle(
                      child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 18),
                      onTap: () => _showError('Filtreler yakında.'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // bottom tabs (POST / STORY / REELS)
          _BottomTabs(
            tab: _tab,
            onChanged: (t) {
              if (_tab == t) return;
              setState(() => _tab = t);
              _tabAnim.forward(from: 0);
              HapticFeedback.selectionClick();
            },
          ),

          const SizedBox(height: 8),

          // camera switch (IG’de sağ altta)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: GestureDetector(
                onTap: _switchCamera,
                child: const Icon(Icons.cameraswitch, color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getVideoProgress() {
    if (_recStartTime == null) return 0.0;
    final ms = DateTime.now().difference(_recStartTime!).inMilliseconds;
    return (ms / _maxVideoDuration.inMilliseconds).clamp(0.0, 1.0);
  }
}

// ---------------- WIDGETS ----------------

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _LeftModeTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback onTap;

  const _LeftModeTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : Colors.white70;
    final textColor = selected ? Colors.white : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          if (!compact) ...[
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SmallCircle({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _IGCaptureButton extends StatelessWidget {
  final bool isRecording;
  final Animation<double> pulseAnimation;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _IGCaptureButton({
    required this.isRecording,
    required this.pulseAnimation,
    required this.progress,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          double scale = 1.0;
          if (isRecording) {
            scale = 1.0 + (pulseAnimation.value * 0.10);
          }

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 84,
              height: 84,
              child: CustomPaint(
                painter: _IGButtonPainter(
                  isRecording: isRecording,
                  progress: progress,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IGButtonPainter extends CustomPainter {
  final bool isRecording;
  final double progress;

  _IGButtonPainter({required this.isRecording, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // dış halka
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius - 2, ringPaint);

    // iç dolgu
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (isRecording) {
      // recording = daha küçük karemsi
      final inner = radius * 0.50;
      final rect = Rect.fromCenter(center: center, width: inner * 2, height: inner * 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), Paint()..color = Colors.white);

      // progress arc (kırmızı hissi vermek yerine IG gibi beyaz kalsın; istersen kırmızı yaparız)
      final progressPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 3),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    } else {
      final inner = radius * 0.82;
      canvas.drawCircle(center, inner, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IGButtonPainter oldDelegate) {
    return isRecording != oldDelegate.isRecording || progress != oldDelegate.progress;
  }
}

class _BottomTabs extends StatelessWidget {
  final _CaptureTab tab;
  final ValueChanged<_CaptureTab> onChanged;

  const _BottomTabs({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (_CaptureTab.post, 'GÖNDERİ'),
      (_CaptureTab.story, 'HİKAYE'),
      (_CaptureTab.reels, 'REELS VİDEOSU'),
    ];

    return SizedBox(
      height: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final it in items) ...[
            GestureDetector(
              onTap: () => onChanged(it.$1),
              child: _TabText(
                text: it.$2,
                selected: tab == it.$1,
              ),
            ),
            if (it != items.last) const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}

class _TabText extends StatelessWidget {
  final String text;
  final bool selected;
  const _TabText({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 160),
      style: TextStyle(
        color: selected ? Colors.white : Colors.white38,
        fontSize: selected ? 14 : 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: 0.6,
      ),
      child: Text(text),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
    );
  }
}
