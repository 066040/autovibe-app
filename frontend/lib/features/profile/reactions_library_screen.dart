import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/articles_api.dart';
import '../../core/network/articles_api_provider.dart';
import '../../core/storage/reactions_controller.dart';

class ReactionsLibraryScreen extends ConsumerStatefulWidget {
  const ReactionsLibraryScreen({super.key});

  @override
  ConsumerState<ReactionsLibraryScreen> createState() => _ReactionsLibraryScreenState();
}

class _ReactionsLibraryScreenState extends ConsumerState<ReactionsLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<List<ArticleMini>> _load(bool liked) async {
    final reactions = ref.read(reactionsControllerProvider);
    final ids = liked ? reactions.liked.toList() : reactions.saved.toList();
    // stabil order
    ids.sort();
    final api = ref.read(articlesApiProvider);
    return api.byIds(ids);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kütüphane'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Beğenilenler'),
            Tab(text: 'Kaydedilenler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ArticlesList(
            future: _load(true),
            emptyText: 'Henüz beğendiğin bir içerik yok.',
            accent: cs.primary,
          ),
          _ArticlesList(
            future: _load(false),
            emptyText: 'Henüz kaydettiğin bir içerik yok.',
            accent: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _ArticlesList extends StatelessWidget {
  final Future<List<ArticleMini>> future;
  final String emptyText;
  final Color accent;

  const _ArticlesList({
    required this.future,
    required this.emptyText,
    required this.accent,
  });

  String _two(int n) => n < 10 ? '0$n' : '$n';

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    return '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArticleMini>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Hata: ${snap.error}'),
            ),
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final a = items[i];
            final meta = [
              if (a.sourceName.isNotEmpty) a.sourceName,
              if (_fmtDate(a.publishedAt).isNotEmpty) _fmtDate(a.publishedAt),
            ].join(' • ');

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // şimdilik URL kopyalama / açma sonraya. istersen article_detail route’una da bağlarız.
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('URL: ${a.url}')),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withOpacity(0.12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.play_circle_fill_rounded, size: 34, color: accent.withOpacity(0.7)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
