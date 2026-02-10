import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLikedIdsKey = 'liked_ids_v1';

final likedControllerProvider =
    AsyncNotifierProvider<LikedController, Set<String>>(LikedController.new);

final likedByIdProvider = Provider.family<bool, String>((ref, id) {
  final set = ref.watch(likedControllerProvider).asData?.value ?? <String>{};
  return set.contains(id);
});

class LikedController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kLikedIdsKey);
    if (raw == null || raw.isEmpty) return <String>{};

    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _persist(Set<String> set) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLikedIdsKey, jsonEncode(set.toList()));
  }

  Future<void> toggle(String id) async {
    final current = state.asData?.value ?? <String>{};
    final next = {...current};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> clear() async {
    state = const AsyncData(<String>{});
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLikedIdsKey);
  }
}
