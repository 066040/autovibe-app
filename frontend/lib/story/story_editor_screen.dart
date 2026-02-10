import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'story_models.dart';
import 'story_viewer_screen.dart';

import 'editor/story_layer_models.dart';
import 'editor/draggable_layer.dart';

/// IG-like Story Editor (UI + interactions)
class StoryEditorScreen extends StatefulWidget {
  final StoryDraft draft;
  const StoryEditorScreen({super.key, required this.draft});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen>
    with WidgetsBindingObserver {
  // ===== MEDIA =====
  VideoPlayerController? _vp;
  bool _videoReady = false;
  bool _muted = false;

  // ===== LAYERS =====
  final List<StoryLayer> _layers = [];
  String? _selectedId;

  StoryLayer? get _selected {
    if (_selectedId == null) return null;
    try {
      return _layers.firstWhere((e) => e.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  void _select(String id) => setState(() => _selectedId = id);
  void _deselect() => setState(() => _selectedId = null);

  // ===== TRASH ZONE =====
  bool _trashVisible = false;
  bool _overTrash = false;
  Rect? _trashRect;
  final GlobalKey _trashKey = GlobalKey();

  void _updateTrashRect() {
    final box = _trashKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    _trashRect = pos & box.size;
  }

  void _scheduleTrashRectUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_trashVisible) _updateTrashRect();
    });
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      _layers.removeWhere((e) => e.id == _selectedId);
      _selectedId = null;
    });
  }

  // ===== CANVAS / SNAP GUIDES =====
  Size _canvasSize = Size.zero;
  bool _showHGuide = false;
  bool _showVGuide = false;
  double? _hGuideY;
  double? _vGuideX;
  static const double _snapThreshold = 10;

  Offset _applySnap(Offset p, StoryLayer layer) {
    if (_canvasSize == Size.zero) return p;

    final cx = _canvasSize.width / 2;
    final cy = _canvasSize.height / 2;

    final approxW = layer.type == StoryLayerType.image
        ? layer.baseWidth * layer.scale
        : 240 * layer.scale;
    final approxH = layer.type == StoryLayerType.image
        ? (layer.baseWidth * 0.75) * layer.scale
        : 110 * layer.scale;

    final centerX = p.dx + approxW / 2;
    final centerY = p.dy + approxH / 2;

    double dx = p.dx;
    double dy = p.dy;

    bool v = false, h = false;

    if ((centerX - cx).abs() <= _snapThreshold) {
      dx = cx - approxW / 2;
      v = true;
    }
    if ((centerY - cy).abs() <= _snapThreshold) {
      dy = cy - approxH / 2;
      h = true;
    }

    _showVGuide = v;
    _showHGuide = h;
    _vGuideX = v ? cx : null;
    _hGuideY = h ? cy : null;

    if (v || h) HapticFeedback.selectionClick();
    return Offset(dx, dy);
  }

  // ===== RIGHT MENU (the ⌄ list in video) =====
  bool _moreOpen = false;

  void _toggleMore() {
    setState(() => _moreOpen = !_moreOpen);
  }

  void _closeMore() {
    if (_moreOpen) setState(() => _moreOpen = false);
  }

  // ===== TEXT EDIT (IG-LIKE) =====
  final _textCtrl = TextEditingController();
  final _textFocus = FocusNode();
  bool _textEditing = false;
  Offset _textTapPos = Offset.zero;

  // IG-style font presets
  final List<_FontPreset> _presets = const [
    _FontPreset(
      keyId: 'modern',
      label: 'Modern',
      family: 'System',
      weight: FontWeight.w800,
      stroke: true,
      bg: false,
    ),
    _FontPreset(
      keyId: 'classic',
      label: 'Classic',
      family: 'System',
      weight: FontWeight.w600,
      stroke: false,
      bg: false,
    ),
    _FontPreset(
      keyId: 'signature',
      label: 'Signature',
      family: 'PlayfairDisplay',
      weight: FontWeight.w600,
      stroke: false,
      bg: false,
    ),
    _FontPreset(
      keyId: 'editor',
      label: 'Editor',
      family: 'Montserrat',
      weight: FontWeight.w700,
      stroke: false,
      bg: true,
    ),
    _FontPreset(
      keyId: 'poster',
      label: 'Poster',
      family: 'Oswald',
      weight: FontWeight.w900,
      stroke: true,
      bg: true,
    ),
    _FontPreset(
      keyId: 'bubble',
      label: 'Bubble',
      family: 'Poppins',
      weight: FontWeight.w800,
      stroke: false,
      bg: true,
    ),
  ];
  int _presetIndex = 1; // Classic

  // active style
  double _activeFontSize = 44;
  String _activeFontFamily = 'System';
  Color _activeColor = Colors.white;
  bool _activeBold = true;
  bool _activeBg = false;
  bool _activeStroke = false;
  StoryTextAlign _activeAlign = StoryTextAlign.center;

  // inline palette (video style)
  bool _paletteOpen = false;

  static const _palette = <Color>[
    Colors.white,
    Colors.black,
    Color(0xFFFFD400),
    Color(0xFF00D1FF),
    Color(0xFFFF2D55),
    Color(0xFFFF3B30),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
    Color(0xFFFF9500),
  ];

  void _applyPreset(int index) {
    final p = _presets[index];
    setState(() {
      _presetIndex = index;
      _activeFontFamily = p.family;
      _activeBold = p.weight.index >= FontWeight.w700.index;
      _activeStroke = p.stroke;
      _activeBg = p.bg;
    });

    final s = _selected;
    if (s != null && s.type == StoryLayerType.text) {
      setState(() {
        s.fontFamily = _activeFontFamily;
        s.bold = _activeBold;
        s.stroke = _activeStroke;
        s.hasBackground = _activeBg;
      });
    }
  }

  void _cycleAlign() {
    setState(() {
      _activeAlign = _activeAlign == StoryTextAlign.left
          ? StoryTextAlign.center
          : _activeAlign == StoryTextAlign.center
              ? StoryTextAlign.right
              : StoryTextAlign.left;
    });

    final s = _selected;
    if (s != null && s.type == StoryLayerType.text) {
      setState(() => s.align = _activeAlign);
    }
  }

  TextAlign _toAlign(StoryTextAlign a) {
    switch (a) {
      case StoryTextAlign.left:
        return TextAlign.left;
      case StoryTextAlign.center:
        return TextAlign.center;
      case StoryTextAlign.right:
        return TextAlign.right;
    }
  }

  void _startTextEditAt(Offset pos, {StoryLayer? existing}) {
    if (_textEditing) return;

    setState(() {
      _textTapPos = pos;
      _textEditing = true;
      _paletteOpen = false;
      _trashVisible = false;
      _overTrash = false;
      _moreOpen = false;
    });

    if (existing != null) {
      _selectedId = existing.id;
      _textCtrl.text = existing.text;
      _activeFontSize = existing.fontSize;
      _activeFontFamily = existing.fontFamily;
      _activeColor = existing.color;
      _activeBold = existing.bold;
      _activeBg = existing.hasBackground;
      _activeStroke = existing.stroke;
      _activeAlign = existing.align;

      final pi = _presets.indexWhere((p) =>
          p.family == _activeFontFamily &&
          p.stroke == _activeStroke &&
          p.bg == _activeBg);
      if (pi != -1) _presetIndex = pi;
    } else {
      _selectedId = null;
      _textCtrl.text = '';
    }

    Future.delayed(const Duration(milliseconds: 30), () {
      if (mounted) _textFocus.requestFocus();
    });
  }

  void _commitTextEdit() {
    final t = _textCtrl.text.trim();

    if (t.isEmpty) {
      if (_selectedId != null) _deleteSelected();
      setState(() {
        _textEditing = false;
        _paletteOpen = false;
      });
      _textFocus.unfocus();
      return;
    }

    setState(() {
      if (_selectedId != null) {
        final i = _layers.indexWhere((e) => e.id == _selectedId);
        if (i != -1) {
          final layer = _layers[i];
          layer.text = t;
          layer.fontSize = _activeFontSize;
          layer.fontFamily = _activeFontFamily;
          layer.color = _activeColor;
          layer.bold = _activeBold;
          layer.hasBackground = _activeBg;
          layer.stroke = _activeStroke;
          layer.align = _activeAlign;
        }
      } else {
        final layer = StoryLayer.text(
          id: StoryLayer.newId(),
          position: _textTapPos,
          text: t,
          fontSize: _activeFontSize,
          fontFamily: _activeFontFamily,
          color: _activeColor,
          bold: _activeBold,
          hasBackground: _activeBg,
          stroke: _activeStroke,
          align: _activeAlign,
        );
        _layers.add(layer);
        _selectedId = layer.id;
      }
      _textEditing = false;
      _paletteOpen = false;
    });

    _textFocus.unfocus();
  }

  void _setColor(Color c) {
    setState(() => _activeColor = c);
    final s = _selected;
    if (s != null && s.type == StoryLayerType.text) {
      setState(() => s.color = c);
    }
  }

  // ===== STICKERS (IG-LIKE SHEET) =====
  Future<void> _openStickerSheet() async {
    _closeMore();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),

                // search
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.white70, size: 20),
                      SizedBox(width: 10),
                      Text('Ara',
                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // quick buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _stChip('KONUM', Icons.location_on, onTap: () {}),
                    _stChip('BAHSETME', Icons.alternate_email, onTap: () {}),
                    _stChip('MÜZİK', Icons.music_note, onTap: () {}),
                    _stChip('FOTOĞRAF', Icons.photo, onTap: () async {
                      Navigator.pop(context);
                      await _addStickerImageFromGallery();
                    }),
                    _stChip('GIF', Icons.gif_box, onTap: () {}),
                    _stChip('SEN DE EKLE', Icons.add_box, onTap: () {}),
                    _stChip('ÇERÇEVELER', Icons.crop_square, onTap: () {}),
                    _stChip('ALTYAZILAR', Icons.closed_caption, onTap: () {}),
                    _stChip('SORULAR', Icons.question_answer, onTap: () {}),
                    _stChip('KESİMLER', Icons.cut, onTap: () {}),
                    _stChip('AVATAR', Icons.person, onTap: () {}),
                    _stChip('ANKET', Icons.poll, onTap: () {}),
                    _stChip('BAĞLANTI', Icons.link, onTap: () {}),
                    _stChip('#KONU ETİKETİ', Icons.tag, onTap: () {}),
                    _stChip('GERİ SAYIM', Icons.timer, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 14),

                // sticker grid preview
                SizedBox(
                  height: 190,
                  child: GridView.builder(
                    itemCount: 24,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemBuilder: (_, i) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.star,
                            color: Colors.white54, size: 18),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _stChip(String text, IconData icon,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStickerImageFromGallery() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;

    final size = MediaQuery.of(context).size;
    final layer = StoryLayer.image(
      id: StoryLayer.newId(),
      position: Offset(size.width * 0.25, size.height * 0.35),
      imagePath: x.path,
      baseWidth: 200,
    );

    setState(() {
      _layers.add(layer);
      _selectedId = layer.id;
    });
  }

  // ===== CAPTION =====
  final _captionCtrl = TextEditingController();

  // ===== MEDIA BACKGROUND =====
  Future<void> _initMedia() async {
    if (widget.draft.type != StoryMediaType.video) return;

    final f = File(widget.draft.filePath);
    if (!await f.exists()) return;

    _vp = VideoPlayerController.file(f);
    try {
      await _vp!.initialize();
      await _vp!.setLooping(true);
      await _vp!.setVolume(_muted ? 0 : 1);
      await _vp!.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  void _toggleMute() {
    if (_vp == null) return;
    setState(() => _muted = !_muted);
    _vp!.setVolume(_muted ? 0 : 1);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_vp != null && _vp!.value.isInitialized) {
      if (state == AppLifecycleState.resumed) {
        _vp!.play();
      } else if (state == AppLifecycleState.paused) {
        _vp!.pause();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initMedia();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textCtrl.dispose();
    _textFocus.dispose();
    _captionCtrl.dispose();
    _vp?.dispose();
    super.dispose();
  }

  Widget _buildMediaBackground() {
    final path = widget.draft.filePath;

    if (widget.draft.type == StoryMediaType.video) {
      if (!_videoReady || _vp == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _vp!.value.size.width,
          height: _vp!.value.size.height,
          child: VideoPlayer(_vp!),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, err, __) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          'Görsel yüklenemedi:\n$err',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ===== LAYER WIDGET =====
  Widget _buildLayerWidget(StoryLayer layer) {
    if (layer.type == StoryLayerType.image) {
      return Image.file(
        File(layer.imagePath),
        width: layer.baseWidth,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.error, color: Colors.white),
      );
    }

    final align = _toAlign(layer.align);
    final style = TextStyle(
      fontFamily: layer.fontFamily == 'System' ? null : layer.fontFamily,
      fontSize: layer.fontSize,
      color: layer.color,
      fontWeight: layer.bold ? FontWeight.w900 : FontWeight.w600,
      height: 1.08,
    );

    Widget w = Text(layer.text, textAlign: align, style: style);

    if (layer.stroke) {
      w = Stack(
        children: [
          Text(
            layer.text,
            textAlign: align,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4
                ..color = Colors.black,
              color: null,
            ),
          ),
          Text(layer.text, textAlign: align, style: style),
        ],
      );
    }

    if (layer.hasBackground) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(999),
        ),
        child: DefaultTextStyle.merge(
          style: style.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
          child: w,
        ),
      );
    }

    return w;
  }

  // ===== UI ATOMS =====
  Widget _toolCircle({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _pillButton({
    required Widget leading,
    required String text,
    required Color bg,
    required VoidCallback onTap,
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== MAIN BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMediaBackground(),

          // tap outside to close right menu
          if (_moreOpen && !_textEditing)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMore,
                child: const SizedBox(),
              ),
            ),

          // CANVAS
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) {
                _canvasSize = Size(box.maxWidth, box.maxHeight);

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (d) {
                    if (_textEditing) {
                      _commitTextEdit();
                      return;
                    }
                    _closeMore();

                    final safeTop = MediaQuery.of(context).padding.top;
                    final y = d.localPosition.dy;
                    final bottomUi = 170.0;

                    if (y > safeTop + 40 && y < box.maxHeight - bottomUi) {
                      // IG: boş alana dokun -> yazı
                      _startTextEditAt(d.localPosition);
                    } else {
                      _deselect();
                    }
                  },
                  child: Stack(
                    children: [
                      // LAYERS
                      for (final layer in _layers)
                        DraggableLayer(
                          pos: layer.position,
                          scale: layer.scale,
                          rotation: layer.rotation,
                          selected: _selectedId == layer.id,
                          onTap: () {
                            if (_textEditing) {
                              _commitTextEdit();
                              return;
                            }
                            _closeMore();
                            if (layer.type == StoryLayerType.text) {
                              _startTextEditAt(layer.position, existing: layer);
                            } else {
                              _select(layer.id);
                            }
                          },
                          onPos: (p) {
                            if (_selectedId != layer.id) _selectedId = layer.id;

                            final snapped = _applySnap(p, layer);

                            final center = snapped + const Offset(90, 50);
                            final over = _trashRect?.contains(center) ?? false;

                            setState(() {
                              layer.position = snapped;
                              _trashVisible = true;
                              _overTrash = over;
                            });

                            _scheduleTrashRectUpdate();
                          },
                          onDragEnd: () {
                            setState(() {
                              _trashVisible = false;
                              _showHGuide = false;
                              _showVGuide = false;
                              _hGuideY = null;
                              _vGuideX = null;
                            });

                            if (_overTrash) _deleteSelected();
                            _overTrash = false;
                          },
                          onScale: (s) => setState(() => layer.scale = s),
                          onRotation: (r) => setState(() => layer.rotation = r),
                          child: _buildLayerWidget(layer),
                        ),

                      // GUIDES
                      if (_showVGuide && _vGuideX != null)
                        Positioned(
                          left: _vGuideX!,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 1.2,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      if (_showHGuide && _hGuideY != null)
                        Positioned(
                          top: _hGuideY!,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1.2,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),

                      // TEXT EDIT OVERLAY
                      if (_textEditing) _buildTextEditOverlay(),

                      // TRASH BAR (IG-like)
                      if (_trashVisible)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 92,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                              child: Container(
                                key: _trashKey,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: _overTrash
                                      ? Colors.redAccent.withOpacity(0.95)
                                      : Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete,
                                        color: _overTrash
                                            ? Colors.white
                                            : Colors.white70),
                                    const SizedBox(width: 10),
                                    Text(
                                      _overTrash
                                          ? 'Bırak → Sil'
                                          : 'Silmek için aşağı sürükle',
                                      style: TextStyle(
                                        color: _overTrash
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // TOP BAR (IG)
          if (!_textEditing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      _toolCircle(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 22),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),

          // RIGHT TOOL RAIL (IG)
          if (!_textEditing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 12,
              child: Column(
                children: [
                  _toolCircle(
                    onTap: () {
                      final size = MediaQuery.of(context).size;
                      _startTextEditAt(
                        Offset(size.width * 0.35, size.height * 0.25),
                      );
                    },
                    child: const Text(
                      'Aa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (!_moreOpen) ...[
                    _toolCircle(
                      onTap: _openStickerSheet,
                      child: const Icon(Icons.emoji_emotions_outlined,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 10),
                    _toolCircle(
                      onTap: () {}, // music placeholder
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 10),
                    _toolCircle(
                      onTap: () {}, // mention placeholder
                      child: const Icon(Icons.alternate_email,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 10),
                    _toolCircle(
                      onTap: _toggleMute,
                      child: Icon(_muted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 10),
                    _toolCircle(
                      onTap: _toggleMore,
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 26),
                    ),
                  ] else ...[
                    _buildMoreMenu(),
                  ],
                ],
              ),
            ),

          // BOTTOM: caption + share buttons (IG)
          if (!_textEditing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // caption line
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _captionCtrl,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Bir açıklama ekle...',
                                  hintStyle: TextStyle(color: Colors.white60),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // share row
                      Row(
                        children: [
                          _pillButton(
                            leading: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 14),
                            ),
                            text: 'Hikayen',
                            bg: Colors.black.withOpacity(0.35),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StoryViewerScreen(items: [widget.draft]),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _pillButton(
                              leading: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star,
                                    color: Colors.white, size: 14),
                              ),
                              text: 'Yakın Arkadaş...',
                              bg: Colors.black.withOpacity(0.35),
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StoryViewerScreen(items: [widget.draft]),
                                ),
                              );
                            },
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6D28D9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== RIGHT “MORE” MENU (video’daki dikey liste) =====
  Widget _buildMoreMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _moreItem('Metin', Icons.text_fields, onTap: () {
            _toggleMore();
            final size = MediaQuery.of(context).size;
            _startTextEditAt(Offset(size.width * 0.35, size.height * 0.25));
          }),
          _moreItem('Çıkartmalar', Icons.emoji_emotions_outlined, onTap: () async {
            _toggleMore();
            await _openStickerSheet();
          }),
          _moreItem('Müzik', Icons.music_note, onTap: () {
            _toggleMore();
          }),
          _moreItem('Bahsetme', Icons.alternate_email, onTap: () {
            _toggleMore();
          }),
          _moreItem(_muted ? 'Ses Kapalı' : 'Ses Açık',
              _muted ? Icons.volume_off : Icons.volume_up, onTap: () {
            _toggleMute();
          }),
          _moreItem('Yeniden boyutlandır', Icons.crop_free, onTap: () {
            _toggleMore();
          }, highlighted: true),
          _moreItem('Efektler', Icons.auto_awesome, onTap: () {
            _toggleMore();
          }),
          _moreItem('Çiz', Icons.gesture, onTap: () {
            _toggleMore();
          }),
          _moreItem('Kaydet', Icons.download, onTap: () {
            _toggleMore();
          }),
          _moreItem('Daha Fazla', Icons.more_horiz, onTap: () {
            _toggleMore();
          }),
          const SizedBox(height: 2),
          _toolCircle(
            onTap: _toggleMore,
            child: const Icon(Icons.keyboard_arrow_up,
                color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _moreItem(String t, IconData icon,
      {required VoidCallback onTap, bool highlighted = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: highlighted ? const Color(0xFF2D6BFF) : Colors.white,
                size: 18),
            const SizedBox(width: 10),
            Text(
              t,
              style: TextStyle(
                color: highlighted ? const Color(0xFF2D6BFF) : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== IG-LIKE TEXT EDIT UI (video birebir mantık) =====
  Widget _buildTextEditOverlay() {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Positioned.fill(
      child: Stack(
        children: [
          // touch outside -> commit (IG)
          GestureDetector(
            onTap: _commitTextEdit,
            child: Container(color: Colors.transparent),
          ),

          // top right: Bitti
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: _commitTextEdit,
              child: const Text(
                'Bitti',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // left vertical font slider (video gibi)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 10,
            bottom: inset + 140,
            child: SizedBox(
              width: 36,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    min: 18,
                    max: 96,
                    value: _activeFontSize.clamp(18, 96),
                    onChanged: (v) {
                      setState(() => _activeFontSize = v);
                      final s = _selected;
                      if (s != null && s.type == StoryLayerType.text) {
                        setState(() => s.fontSize = v);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          // center text field
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _textCtrl,
                focusNode: _textFocus,
                autofocus: true,
                textAlign: _toAlign(_activeAlign),
                style: TextStyle(
                  fontSize: _activeFontSize,
                  color: _activeColor,
                  fontFamily:
                      _activeFontFamily == 'System' ? null : _activeFontFamily,
                  fontWeight: _activeBold ? FontWeight.bold : FontWeight.normal,
                  height: 1.06,
                ),
                decoration: const InputDecoration(border: InputBorder.none),
                maxLines: null,
                onSubmitted: (_) => _commitTextEdit(),
              ),
            ),
          ),

          // bottom panel above keyboard (video gibi)
          Positioned(
            left: 0,
            right: 0,
            bottom: inset,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // presets row (pills)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: _presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final p = _presets[i];
                          final sel = i == _presetIndex;
                          return GestureDetector(
                            onTap: () => _applyPreset(i),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: sel ? Colors.white : Colors.black45,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                p.label,
                                style: TextStyle(
                                  color: sel ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontFamily:
                                      p.family == 'System' ? null : p.family,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // tool bar (tek parça yuvarlak bar)
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          _barIcon(
                            child: const Text(
                              'Aa',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900),
                            ),
                            onTap: () {
                              setState(() => _activeBold = !_activeBold);
                              final s = _selected;
                              if (s != null && s.type == StoryLayerType.text) {
                                setState(() => s.bold = _activeBold);
                              }
                            },
                          ),
                          const SizedBox(width: 12),

                          // color wheel
                          _barIcon(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(colors: [
                                  Colors.red,
                                  Colors.yellow,
                                  Colors.green,
                                  Colors.cyan,
                                  Colors.blue,
                                  Colors.purple,
                                  Colors.red,
                                ]),
                              ),
                            ),
                            onTap: () =>
                                setState(() => _paletteOpen = !_paletteOpen),
                          ),
                          const SizedBox(width: 12),

                          // "//" icon (video’daki)
                          _barIcon(
                            child: const Text(
                              '//',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              // placeholder: IG'deki gibi "style varyant" hissi
                              HapticFeedback.selectionClick();
                            },
                          ),
                          const SizedBox(width: 12),

                          // dotted/shine icon (approx)
                          _barIcon(
                            child: const Icon(Icons.auto_awesome,
                                color: Colors.white, size: 20),
                            onTap: () {
                              HapticFeedback.selectionClick();
                            },
                          ),
                          const SizedBox(width: 12),

                          // align icon
                          _barIcon(
                            child: const Icon(Icons.format_align_center,
                                color: Colors.white, size: 20),
                            onTap: _cycleAlign,
                          ),
                          const Spacer(),

                          // background toggle (A in box vibe)
                          _barIcon(
                            child: const Icon(Icons.crop_16_9,
                                color: Colors.white, size: 20),
                            onTap: () {
                              setState(() => _activeBg = !_activeBg);
                              final s = _selected;
                              if (s != null && s.type == StoryLayerType.text) {
                                setState(() => s.hasBackground = _activeBg);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // palette row (inline)
                    if (_paletteOpen) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          itemCount: _palette.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final col = _palette[i];
                            final sel = col.value == _activeColor.value;
                            return GestureDetector(
                              onTap: () => _setColor(col),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: sel ? Colors.white : Colors.white24,
                                    width: sel ? 2.5 : 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Bahset / Konum row (video gibi)
                    Row(
                      children: [
                        _miniHint('Bahset', Icons.alternate_email),
                        const SizedBox(width: 18),
                        _miniHint('Konum', Icons.location_on),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barIcon({required Widget child, required VoidCallback onTap}) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(width: 34, height: 34, child: Center(child: child)),
    );
  }

  Widget _miniHint(String t, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          t,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _FontPreset {
  final String keyId;
  final String label;
  final String family;
  final FontWeight weight;
  final bool stroke;
  final bool bg;

  const _FontPreset({
    required this.keyId,
    required this.label,
    required this.family,
    required this.weight,
    required this.stroke,
    required this.bg,
  });
}
