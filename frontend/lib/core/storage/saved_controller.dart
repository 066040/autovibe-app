import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';

const _kSavedArticlesKey = 'saved_articles_v1';

final savedControllerProvider =
    AsyncNotifierProvider<SavedController, List<Article>>(SavedController.new);

final savedByIdProvider = Provider.family<bool, String>((ref, id) {
  final list = ref.watch(savedControllerProvider).asData?.value ?? const <Article>[];
  return list.any((a) => a.id == id);
});

class SavedController extends AsyncNotifier<List<Article>> {
  @override
  Future<List<Article>> build() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSavedArticlesKey);
    if (raw == null || raw.isEmpty) return const <Article>[];

    try {
      final arr = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return arr.map((m) => Article.fromJson(m)).toList();
    } catch (_) {
      return const <Article>[];
    }
  }

  Future<void> _persist(List<Article> list) async {
    final p = await SharedPreferences.getInstance();
    final arr = list.map((a) => a.toJson()).toList();
    await p.setString(_kSavedArticlesKey, jsonEncode(arr));
  }

  /// ArticleDetailScreen senden bunu çağırıyor: savedCtrl.toggle(a)
  Future<void> toggle(Article a) async {
    final current = state.asData?.value ?? const <Article>[];
    final exists = current.any((x) => x.id == a.id);

    final next = exists
        ? current.where((x) => x.id != a.id).toList()
        : <Article>[a, ...current]; // en başa ekle

    state = AsyncData(next);
    await _persist(next);
  }

  /// SavedScreen senden bunu çağırıyor: remove(a.id)
  Future<void> remove(String id) async {
    final current = state.asData?.value ?? const <Article>[];
    final next = current.where((x) => x.id != id).toList();
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> clear() async {
    state = const AsyncData(<Article>[]);
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSavedArticlesKey);
  }
}
