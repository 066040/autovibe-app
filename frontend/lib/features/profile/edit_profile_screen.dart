import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/storage/prefs_provider.dart';
import '../../l10n/app_localizations.dart';

const _kProfileKey = 'profile_v1';
const _accent = Color(0xFF2D6BFF);

enum ProfileRole { reader, journalist, publisher }

class ProfileData {
  final String displayName;
  final String bio;
  final String website;
  final String avatar;
  final String cover;
  final ProfileRole role;

  const ProfileData({
    required this.displayName,
    required this.bio,
    required this.website,
    required this.avatar,
    required this.cover,
    required this.role,
  });

  static const empty = ProfileData(
    displayName: '',
    bio: 'Global automotive news profile',
    website: '',
    avatar: '',
    cover: '',
    role: ProfileRole.reader,
  );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'bio': bio,
        'website': website,
        'avatar': avatar,
        'cover': cover,
        'role': role.name,
      };

  static ProfileRole _parseRole(String? v) {
    for (final r in ProfileRole.values) {
      if (r.name == v) return r;
    }
    return ProfileRole.reader;
  }

  static ProfileData fromJson(Map<String, dynamic> j) {
    return ProfileData(
      displayName: (j['displayName'] ?? '') as String,
      bio: (j['bio'] ?? '') as String,
      website: (j['website'] ?? '') as String,
      avatar: (j['avatar'] ?? '') as String,
      cover: (j['cover'] ?? '') as String,
      role: _parseRole(j['role'] as String?),
    );
  }
}

final profileProvider = FutureProvider<ProfileData>((ref) async {
  final prefs = await ref.watch(prefsProvider.future);
  final raw = prefs.getString(_kProfileKey);
  if (raw == null || raw.trim().isEmpty) return ProfileData.empty;

  try {
    return ProfileData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return ProfileData.empty;
  }
});

final profileSaverProvider = Provider<_ProfileSaver>((ref) => _ProfileSaver(ref));

class _ProfileSaver {
  final Ref ref;
  _ProfileSaver(this.ref);

  Future<void> save(ProfileData data) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(_kProfileKey, jsonEncode(data.toJson()));
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  final _website = TextEditingController();
  final _avatar = TextEditingController();
  final _cover = TextEditingController();

  final _imagePicker = ImagePicker();

  ProfileRole _role = ProfileRole.reader;
  bool _loaded = false;
  bool _saving = false;
  bool _busyMedia = false;

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _website.dispose();
    _avatar.dispose();
    _cover.dispose();
    super.dispose();
  }

  void _loadOnce(ProfileData d) {
    if (_loaded) return;
    _loaded = true;
    _displayName.text = d.displayName;
    _bio.text = d.bio;
    _website.text = d.website;
    _avatar.text = d.avatar;
    _cover.text = d.cover;
    _role = d.role;
  }

  bool _isUrl(String s) {
    final v = s.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  ImageProvider? _imgProvider(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    if (_isUrl(s)) return NetworkImage(s);
    final f = File(s);
    if (f.existsSync()) return FileImage(f);
    return null;
  }

  Future<String?> _pickImagePath() async {
    if (kIsWeb) return null;
    if (Platform.isAndroid || Platform.isIOS) {
      final x = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 95);
      return x?.path;
    }
    final res = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (res == null) return null;
    return res.files.single.path;
  }

  Future<String?> _crop({
    required String sourcePath,
    required bool square,
    required String title,
  }) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: _accent,
          aspectRatioPresets: square
              ? [CropAspectRatioPreset.square]
              : [CropAspectRatioPreset.original, CropAspectRatioPreset.ratio16x9],
          lockAspectRatio: square,
        ),
        IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: square,
          resetAspectRatioEnabled: !square,
        ),
      ],
    );
    return cropped?.path;
  }

  Future<String> _persistToAppDir(String sourcePath, {required String prefix}) async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${dir.path}/profile_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${mediaDir.path}/$prefix-$ts.jpg';
    final bytes = await File(sourcePath).readAsBytes();
    await File(outPath).writeAsBytes(bytes);
    return outPath;
  }

  Future<void> _pickCropSetAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    if (_busyMedia) return;
    _busyMedia = true;
    try {
      final picked = await _pickImagePath();
      if (picked == null || picked.trim().isEmpty) return;
      final cropped = await _crop(sourcePath: picked, square: true, title: l10n.avatarCropTitle);
      if (cropped == null || cropped.trim().isEmpty) return;
      final savedPath = await _persistToAppDir(cropped, prefix: 'avatar');
      if (!mounted) return;
      setState(() => _avatar.text = savedPath);
    } finally {
      _busyMedia = false;
    }
  }

  Future<void> _pickCropSetCover() async {
    final l10n = AppLocalizations.of(context)!;
    if (_busyMedia) return;
    _busyMedia = true;
    try {
      final picked = await _pickImagePath();
      if (picked == null || picked.trim().isEmpty) return;
      final cropped = await _crop(sourcePath: picked, square: false, title: l10n.coverCropTitle);
      if (cropped == null || cropped.trim().isEmpty) return;
      final savedPath = await _persistToAppDir(cropped, prefix: 'cover');
      if (!mounted) return;
      setState(() => _cover.text = savedPath);
    } finally {
      _busyMedia = false;
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final saver = ref.read(profileSaverProvider);
      await saver.save(
        ProfileData(
          displayName: _displayName.text.trim(),
          bio: _bio.text.trim(),
          website: _website.text.trim(),
          avatar: _avatar.text.trim(),
          cover: _cover.text.trim(),
          role: _role,
        ),
      );
      ref.invalidate(profileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          l10n.editProfileTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: (_saving || _busyMedia) ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    l10n.save,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (d) {
          _loadOnce(d);

          final coverImg = _imgProvider(_cover.text);
          final avatarImg = _imgProvider(_avatar.text);

          return Stack(
            children: [
              // background gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF070B14),
                        const Color(0xFF0B1220),
                        const Color(0xFF0A1020),
                        _accent.withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  // Cover + avatar card
                  _GlassCard(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 170,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withOpacity(0.06),
                                image: coverImg != null
                                    ? DecorationImage(image: coverImg, fit: BoxFit.cover)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: coverImg == null
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.55), size: 28),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n.coverPath,
                                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: _MiniAction(
                                icon: Icons.camera_alt_outlined,
                                label: 'Kapak Değiştir',
                                onTap: (_saving || _busyMedia) ? null : _pickCropSetCover,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GestureDetector(
                                  onTap: (_saving || _busyMedia) ? null : _pickCropSetAvatar,
                                  child: Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [_accent.withOpacity(0.9), _accent.withOpacity(0.35)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accent.withOpacity(0.25),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        )
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(0.06),
                                      backgroundImage: avatarImg,
                                      child: avatarImg != null
                                          ? null
                                          : Icon(Icons.person, color: Colors.white.withOpacity(0.65), size: 34),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 2, bottom: 2),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                                  ),
                                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayName.text.trim().isEmpty ? l10n.carNewsAccount : _displayName.text.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _bio.text.trim().isEmpty ? l10n.aboutHint : _bio.text.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withOpacity(0.70), height: 1.15, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Form
                  _GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _NeoField(
                            controller: _displayName,
                            label: l10n.displayName,
                            hint: l10n.displayNameHint,
                            icon: Icons.badge_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          _NeoField(
                            controller: _bio,
                            label: l10n.about,
                            hint: l10n.aboutHint,
                            icon: Icons.notes_outlined,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          _NeoField(
                            controller: _website,
                            label: l10n.website,
                            hint: 'https://…',
                            icon: Icons.link_outlined,
                            keyboardType: TextInputType.url,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),

                          // role pills
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.role,
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _RolePill(
                                selected: _role == ProfileRole.reader,
                                text: l10n.reader,
                                icon: Icons.person_outline,
                                onTap: () => setState(() => _role = ProfileRole.reader),
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: _RolePill(
                                selected: _role == ProfileRole.journalist,
                                text: l10n.journalist,
                                icon: Icons.edit_note_outlined,
                                onTap: () => setState(() => _role = ProfileRole.journalist),
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: _RolePill(
                                selected: _role == ProfileRole.publisher,
                                text: l10n.publisher,
                                icon: Icons.campaign_outlined,
                                onTap: () => setState(() => _role = ProfileRole.publisher),
                              )),
                            ],
                          ),

                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Media paths (debug/opsiyonel)
                  _GlassCard(
                    child: Column(
                      children: [
                        _PathRow(
                          title: l10n.avatarPath,
                          value: _avatar.text.trim(),
                          onClear: () => setState(() => _avatar.text = ''),
                        ),
                        const Divider(height: 18, color: Colors.white12),
                        _PathRow(
                          title: l10n.coverPath,
                          value: _cover.text.trim(),
                          onClear: () => setState(() => _cover.text = ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Sticky save button
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _BigCTA(
                  loading: _saving,
                  disabled: _saving || _busyMedia,
                  text: l10n.saveProfile,
                  onTap: _save,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _NeoField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _NeoField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220).withOpacity(0.50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.72)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w500),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final bool selected;
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _RolePill({
    required this.selected,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _accent.withOpacity(0.20) : Colors.white.withOpacity(0.06);
    final br = selected ? _accent.withOpacity(0.55) : Colors.white.withOpacity(0.10);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: br),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white.withOpacity(selected ? 0.95 : 0.75)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onClear;

  const _PathRow({
    required this.title,
    required this.value,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final has = value.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                has ? value : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: has ? onClear : null,
          child: const Text('Temizle', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MiniAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BigCTA extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final String text;
  final VoidCallback onTap;

  const _BigCTA({
    required this.loading,
    required this.disabled,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
