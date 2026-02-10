import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_provider.dart';

class ReelsCommentsSheet extends ConsumerStatefulWidget {
  final String articleId;
  const ReelsCommentsSheet({super.key, required this.articleId});

  @override
  ConsumerState<ReelsCommentsSheet> createState() => _ReelsCommentsSheetState();
}

class _ReelsCommentsSheetState extends ConsumerState<ReelsCommentsSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool _loading = true;
  bool _posting = false;
  bool _loadingMore = false;

  String? _nextCursor;
  final List<CommentVm> _items = [];

  // reply state
  CommentVm? _replyTo;

  // delta for comment count (create +1, delete -1)
  int _delta = 0;

  Dio get _dio => ref.read(dioProvider);

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _nextCursor = null;
      _items.clear();
    });

    try {
      final res = await _dio.get(
        '/comments/articles/${widget.articleId}/comments',
        queryParameters: {'limit': 30},
      );

      final data = (res.data as Map<String, dynamic>);
      final list = (data['data'] as List).cast<dynamic>();
      final next = data['nextCursor'] as String?;

      final parsed = list
        .map((e) => CommentVm.fromJson((e as Map).cast<String, dynamic>()))
        .toList();


      setState(() {
        _items.addAll(parsed);
        _nextCursor = next;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Yorumlar alınamadı: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    if (_nextCursor == null) return;

    setState(() => _loadingMore = true);

    try {
      final res = await _dio.get(
        '/comments/articles/${widget.articleId}/comments',
        queryParameters: {'limit': 30, 'cursor': _nextCursor},
      );

      final data = (res.data as Map<String, dynamic>);
      final list = (data['data'] as List).cast<dynamic>();
      final next = data['nextCursor'] as String?;

      final parsed = list
        .map((e) => CommentVm.fromJson((e as Map).cast<String, dynamic>()))
        .toList();


      setState(() {
        _items.addAll(parsed);
        _nextCursor = next;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
      _toast('Daha fazla yüklenemedi: $e');
    }
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _posting = true);
    HapticFeedback.selectionClick();

    try {
      final payload = <String, dynamic>{'text': text};
      if (_replyTo != null) payload['parentId'] = _replyTo!.id;

      final res = await _dio.post(
        '/comments/articles/${widget.articleId}/comments',
        data: payload,
      );

      final created = CommentVm.fromJson((res.data as Map).cast<String, dynamic>());

      setState(() {
        _controller.clear();
        _posting = false;
        _delta += 1;

        // Yeni yorum/reply'i en üste al (reply ise yine en üste ama parent altında görünmesi için flatten'de çözüyoruz)
        _items.insert(0, created);
        _replyTo = null;
      });

      _focus.unfocus();
    } catch (e) {
      setState(() => _posting = false);
      _toast('Gönderilemedi: $e');
    }
  }

  Future<void> _toggleLike(CommentVm c) async {
    final idx = _items.indexWhere((x) => x.id == c.id);
    if (idx < 0) return;

    final before = _items[idx];
    final nextLiked = !before.liked;
    final nextCount = (before.likesCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 30);

    setState(() {
      _items[idx] = before.copyWith(liked: nextLiked, likesCount: nextCount);
    });

    HapticFeedback.selectionClick();

    try {
      if (nextLiked) {
        final res = await _dio.post('/comments/${c.id}/like');
        final m = (res.data as Map).cast<String, dynamic>();
        final likesCount = (m['likesCount'] as int?) ?? nextCount;
        final liked = (m['liked'] as bool?) ?? true;

        setState(() {
          final cur = _items[idx];
          _items[idx] = cur.copyWith(liked: liked, likesCount: likesCount);
        });
      } else {
        final res = await _dio.delete('/comments/${c.id}/like');
        final m = (res.data as Map).cast<String, dynamic>();
        final likesCount = (m['likesCount'] as int?) ?? nextCount;
        final liked = (m['liked'] as bool?) ?? false;

        setState(() {
          final cur = _items[idx];
          _items[idx] = cur.copyWith(liked: liked, likesCount: likesCount);
        });
      }
    } catch (e) {
      setState(() => _items[idx] = before);
      _toast('Beğeni başarısız: $e');
    }
  }

  Future<void> _deleteComment(CommentVm c) async {
    // UI confirm
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yorumu sil?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(_, true), child: const Text('Sil')),
        ],
      ),
    );

    if (ok != true) return;

    HapticFeedback.selectionClick();

    // optimistic remove (comment + its replies)
    final toRemove = <String>{c.id};
    for (final x in _items) {
      if (x.parentId == c.id) toRemove.add(x.id);
    }

    final removedCount = _items.where((x) => toRemove.contains(x.id)).length;
    final before = List<CommentVm>.from(_items);

    setState(() {
      _items.removeWhere((x) => toRemove.contains(x.id));
      _delta -= 1; // sadece top-level count etkisi istiyorsan -1 yeter; reply silmeyi de saymak istersen removedCount ile ayarla
      if (_replyTo?.id == c.id) _replyTo = null;
    });

    try {
      await _dio.delete('/comments/${c.id}');
      // backend reply’leri de siliyorsa bitti. Silmiyorsa biz UI’de zaten kaldırdık.
    } catch (e) {
      // rollback
      setState(() {
        _items
          ..clear()
          ..addAll(before);
        _delta += 1;
      });
      _toast('Silinemedi: $e');
    }
  }

  void _setReply(CommentVm c) {
    setState(() => _replyTo = c);
    _focus.requestFocus();
    HapticFeedback.selectionClick();
  }

  void _clearReply() {
    setState(() => _replyTo = null);
    HapticFeedback.selectionClick();
  }

  void _close() {
    Navigator.of(context).pop(_delta);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // replies indented görünmesi için düzleştiriyoruz
  List<_FlatRow> _flatten(List<CommentVm> raw) {
    // aynı id tekrar varsa son eklenen öne gelsin
    final byId = <String, CommentVm>{};
    for (final c in raw) {
      byId[c.id] = c;
    }
    final list = byId.values.toList();

    // en yeni üste: createdAt desc (yoksa id sırası)
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    final parents = <CommentVm>[];
    final children = <String, List<CommentVm>>{};

    for (final c in list) {
      final p = (c.parentId ?? '').trim();
      if (p.isEmpty) {
        parents.add(c);
      } else {
        (children[p] ??= []).add(c);
      }
    }

    for (final entry in children.entries) {
      entry.value.sort((a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    }

    final out = <_FlatRow>[];
    for (final p in parents) {
      out.add(_FlatRow(comment: p, depth: 0));
      final kids = children[p.id] ?? const [];
      for (final k in kids) {
        out.add(_FlatRow(comment: k, depth: 1));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;

    final flat = _flatten(_items);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Yorumlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadFirst,
                    tooltip: 'Yenile',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    onPressed: _close,
                    tooltip: 'Kapat',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // LIST
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : flat.isEmpty
                      ? _EmptyState(isDark: isDark, onWrite: () => _focus.requestFocus())
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 160) {
                              _loadMore();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            itemCount: flat.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              if (_loadingMore && i == flat.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final row = flat[i];
                              final c = row.comment;

                              return _CommentTile(
                                isDark: isDark,
                                c: c,
                                depth: row.depth,
                                onLike: () => _toggleLike(c),
                                onReply: () => _setReply(c),
                                onDelete: c.canDelete ? () => _deleteComment(c) : null,
                              );
                            },
                          ),
                        ),
            ),

            const Divider(height: 1),

            // REPLY BAR
            if (_replyTo != null)
              _ReplyBar(
                isDark: isDark,
                name: _replyTo!.userName,
                text: _replyTo!.text,
                onClose: _clearReply,
              ),

            // COMPOSER
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _posting ? null : _post(),
                      decoration: InputDecoration(
                        hintText: _replyTo == null ? 'Yorum yaz...' : 'Yanıt yaz...',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.10) : Colors.black12,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.10) : Colors.black12,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: ElevatedButton(
                      onPressed: _posting ? null : _post,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _posting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatRow {
  final CommentVm comment;
  final int depth;
  _FlatRow({required this.comment, required this.depth});
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onWrite;
  const _EmptyState({required this.isDark, required this.onWrite});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mode_comment_outlined, size: 42, color: fg.withOpacity(0.55)),
            const SizedBox(height: 10),
            Text(
              'Henüz yorum yok',
              style: TextStyle(fontWeight: FontWeight.w900, color: fg),
            ),
            const SizedBox(height: 6),
            Text(
              'İlk yorumu sen yaz 😄',
              style: TextStyle(fontWeight: FontWeight.w700, color: fg.withOpacity(0.7)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onWrite,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Yorum yaz'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final bool isDark;
  final String name;
  final String text;
  final VoidCallback onClose;

  const _ReplyBar({
    required this.isDark,
    required this.name,
    required this.text,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
        border: Border(
          top: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6BFF).withOpacity(0.85),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name’e yanıt',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: fg.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Yanıtı iptal et',
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final bool isDark;
  final CommentVm c;
  final int depth;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _CommentTile({
    required this.isDark,
    required this.c,
    required this.depth,
    required this.onLike,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;

    final leftPad = depth == 0 ? 0.0 : 26.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPad),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF2D6BFF).withOpacity(isDark ? 0.25 : 0.12),
                border: Border.all(color: const Color(0xFF2D6BFF).withOpacity(0.35)),
              ),
              alignment: Alignment.center,
              child: Text(
                (c.userName.isNotEmpty ? c.userName[0] : 'U').toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w900, color: fg),
              ),
            ),
            const SizedBox(width: 10),

            // body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.userName,
                          style: TextStyle(fontWeight: FontWeight.w900, color: fg),
                        ),
                      ),
                      Text(
                        c.timeText ?? '',
                        style: TextStyle(fontWeight: FontWeight.w800, color: fg.withOpacity(0.55), fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        tooltip: 'Seçenekler',
                        onSelected: (v) {
                          if (v == 'reply') onReply();
                          if (v == 'delete' && onDelete != null) onDelete!();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'reply', child: Text('Yanıtla')),
                          if (onDelete != null)
                            const PopupMenuItem(value: 'delete', child: Text('Sil')),
                        ],
                        icon: Icon(Icons.more_vert_rounded, color: fg.withOpacity(0.7), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.text,
                    style: TextStyle(fontWeight: FontWeight.w700, color: fg.withOpacity(0.88)),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      InkWell(
                        onTap: onLike,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                c.liked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: c.liked ? const Color(0xFFE53935) : fg.withOpacity(0.55),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${c.likesCount}',
                                style: TextStyle(fontWeight: FontWeight.w800, color: fg.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onReply,
                        child: const Text('Yanıtla'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- VM --------------------

class CommentVm {
  final String id;
  final String text;
  final int likesCount;
  final bool liked;
  final String userName;

  // reply support
  final String? parentId;

  // delete permission (backend’den gelirse en iyisi)
  final bool canDelete;

  // createdAt (UI sıralama + saat)
  final DateTime? createdAt;
  final String? timeText;

  CommentVm({
    required this.id,
    required this.text,
    required this.likesCount,
    required this.liked,
    required this.userName,
    required this.parentId,
    required this.canDelete,
    required this.createdAt,
    required this.timeText,
  });

  CommentVm copyWith({
    String? text,
    int? likesCount,
    bool? liked,
    String? userName,
    String? parentId,
    bool? canDelete,
    DateTime? createdAt,
    String? timeText,
  }) {
    return CommentVm(
      id: id,
      text: text ?? this.text,
      likesCount: likesCount ?? this.likesCount,
      liked: liked ?? this.liked,
      userName: userName ?? this.userName,
      parentId: parentId ?? this.parentId,
      canDelete: canDelete ?? this.canDelete,
      createdAt: createdAt ?? this.createdAt,
      timeText: timeText ?? this.timeText,
    );
  }

  factory CommentVm.fromJson(Map<String, dynamic> j) {
    final user = (j['user'] as Map?)?.cast<String, dynamic>() ?? {};

    DateTime? created;
    String? timeText;
    final rawCreated = j['createdAt'];
    if (rawCreated != null) {
      try {
        created = DateTime.parse(rawCreated.toString()).toLocal();
        final h = created.hour.toString().padLeft(2, '0');
        final m = created.minute.toString().padLeft(2, '0');
        timeText = '$h:$m';
      } catch (_) {}
    }

    // canDelete backend’de yoksa false kalır.
    final canDelete = (j['canDelete'] as bool?) ?? false;

    return CommentVm(
      id: (j['id'] ?? '').toString(),
      text: (j['text'] ?? '').toString(),
      likesCount: (j['likesCount'] ?? 0) is int ? (j['likesCount'] ?? 0) as int : int.tryParse('${j['likesCount']}') ?? 0,
      liked: (j['liked'] ?? false) as bool,
      userName: (user['name'] ?? 'User').toString(),
      parentId: (j['parentId'] ?? '').toString().trim().isEmpty ? null : (j['parentId'] ?? '').toString(),
      canDelete: canDelete,
      createdAt: created,
      timeText: timeText,
    );
  }
}
