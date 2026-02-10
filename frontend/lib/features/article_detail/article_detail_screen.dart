import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/article.dart';
import '../../core/storage/saved_controller.dart';

import '../../core/network/api_config.dart'; // sende kullanılıyor diye bıraktım (istersen kaldırabiliriz)
import '../../autovibe/reels_comments_sheet.dart'; // ✅ doğru sheet

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  int _delta = 0; // ✅ bu detail ekranında yapılan yorum değişimi (artış)

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _copyShare(BuildContext context, Article a) async {
    final text = (a.url ?? '').trim().isNotEmpty ? a.url!.trim() : a.title;
    await Clipboard.setData(ClipboardData(text: text));
    _toast(context, 'Kopyalandı');
  }

  Future<void> _openComments(BuildContext context, Article a) async {
    final id = a.id.trim();
    if (id.isEmpty) {
      _toast(context, 'Yorumlar için içerik id bulunamadı');
      return;
    }

    // ✅ Sheet kapanınca int delta döndürebiliriz. Yoksa null gelir.
    final int? delta = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => ReelsCommentsSheet(articleId: id),
    );

    if (!mounted) return;
    if (delta != null && delta != 0) {
      setState(() => _delta += delta);
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_delta);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final img = (a.imageUrl ?? '').trim();
    final meta = <String>[];

    if ((a.sourceName ?? '').trim().isNotEmpty) meta.add(a.sourceName!.trim());
    final dateText = _formatDate(a.publishedAt);
    if (dateText.isNotEmpty) meta.add(dateText);

    final isSaved = ref.watch(savedByIdProvider(a.id));
    final savedCtrl = ref.read(savedControllerProvider.notifier);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Haber'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_delta),
          ),
          actions: [
            IconButton(
              onPressed: () => _openComments(context, a), // ✅ burası düzeldi
              icon: const Icon(Icons.mode_comment_outlined),
              tooltip: 'Yorumlar',
            ),
            IconButton(
              onPressed: () => savedCtrl.toggle(a),
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              tooltip: isSaved ? 'Kaydedildi' : 'Kaydet',
            ),
            IconButton(
              onPressed: () => _copyShare(context, a),
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Paylaş / Kopyala',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (img.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (img.isNotEmpty) const SizedBox(height: 12),

            Text(
              a.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),

            if (meta.isNotEmpty)
              Text(
                meta.join(' • '),
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
              ),

            const SizedBox(height: 14),

            if ((a.summary ?? '').trim().isNotEmpty)
              Text(
                a.summary!.trim(),
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),

            const SizedBox(height: 18),

            if ((a.url ?? '').trim().isNotEmpty)
              Card(
                elevation: 0,
                child: ListTile(
                  title: const Text('Kaynak linki', style: TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(a.url!.trim(), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.copy),
                  onTap: () => _copyShare(context, a),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
