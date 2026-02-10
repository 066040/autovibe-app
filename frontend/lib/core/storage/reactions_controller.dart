import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/reactions_api_provider.dart';

class ReactionsState {
  final Set<String> liked;
  final Set<String> saved;

  const ReactionsState({
    this.liked = const {},
    this.saved = const {},
  });

  ReactionsState copyWith({
    Set<String>? liked,
    Set<String>? saved,
  }) {
    return ReactionsState(
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
    );
  }
}

class ReactionsController extends Notifier<ReactionsState> {
  @override
  ReactionsState build() => const ReactionsState();

  Future<void> hydrate() async {
    final api = ref.read(reactionsApiProvider);
    final likes = await api.myLikes();
    final saved = await api.mySaved();

    state = ReactionsState(
      liked: likes.toSet(),
      saved: saved.toSet(),
    );
  }

  Future<void> toggleLike(String articleId) async {
    final api = ref.read(reactionsApiProvider);

    // optimistic UI
    final optimistic = Set<String>.from(state.liked);
    final wasLiked = optimistic.contains(articleId);
    if (wasLiked) {
      optimistic.remove(articleId);
    } else {
      optimistic.add(articleId);
    }
    state = state.copyWith(liked: optimistic);

    try {
      final res = await api.toggleLike(articleId);
      final liked = res['liked'] == true;

      final next = Set<String>.from(state.liked);
      if (liked) {
        next.add(articleId);
      } else {
        next.remove(articleId);
      }
      state = state.copyWith(liked: next);
    } catch (_) {
      // rollback
      final rollback = Set<String>.from(state.liked);
      if (wasLiked) {
        rollback.add(articleId);
      } else {
        rollback.remove(articleId);
      }
      state = state.copyWith(liked: rollback);
      rethrow;
    }
  }

  Future<void> toggleSaved(String articleId) async {
    final api = ref.read(reactionsApiProvider);

    // optimistic UI
    final optimistic = Set<String>.from(state.saved);
    final wasSaved = optimistic.contains(articleId);
    if (wasSaved) {
      optimistic.remove(articleId);
    } else {
      optimistic.add(articleId);
    }
    state = state.copyWith(saved: optimistic);

    try {
      final res = await api.toggleSaved(articleId);
      final saved = res['saved'] == true;

      final next = Set<String>.from(state.saved);
      if (saved) {
        next.add(articleId);
      } else {
        next.remove(articleId);
      }
      state = state.copyWith(saved: next);
    } catch (_) {
      // rollback
      final rollback = Set<String>.from(state.saved);
      if (wasSaved) {
        rollback.add(articleId);
      } else {
        rollback.remove(articleId);
      }
      state = state.copyWith(saved: rollback);
      rethrow;
    }
  }
}

final reactionsControllerProvider =
    NotifierProvider<ReactionsController, ReactionsState>(
  ReactionsController.new,
);
