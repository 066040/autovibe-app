import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/comments_api_provider.dart';
import '../network/comments_api.dart';

class CommentsState {
  final bool loading;
  final List<CommentDto> items;
  final String? error;

  const CommentsState({
    this.loading = false,
    this.items = const [],
    this.error,
  });

  CommentsState copyWith({
    bool? loading,
    List<CommentDto>? items,
    String? error,
  }) {
    return CommentsState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
    );
  }
}

class CommentsController extends AutoDisposeFamilyNotifier<CommentsState, String> {
  @override
  CommentsState build(String articleId) => const CommentsState();

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final api = ref.read(commentsApiProvider);
      final list = await api.listByArticle(arg);
      state = state.copyWith(loading: false, items: list);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    // optimistic placeholder
    state = state.copyWith(
      items: [
        CommentDto(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          text: t,
          createdAt: DateTime.now(),
          userName: 'demo',
        ),
        ...state.items,
      ],
    );

    try {
      final api = ref.read(commentsApiProvider);
      final created = await api.create(arg, t);

      // local placeholder’ı gerçek id ile değiştir
      final next = [...state.items];
      final idx = next.indexWhere((c) => c.id.startsWith('local_') && c.text == t);
      if (idx != -1) next[idx] = created;

      state = state.copyWith(items: next);
    } catch (e) {
      // hata olursa placeholder kalsın ya da kaldır (ben kaldırıyorum)
      final next = state.items.where((c) => !(c.id.startsWith('local_') && c.text == t)).toList();
      state = state.copyWith(items: next, error: e.toString());
    }
  }
}

final commentsControllerProvider =
    AutoDisposeNotifierProviderFamily<CommentsController, CommentsState, String>(CommentsController.new);
