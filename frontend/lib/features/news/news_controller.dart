import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_provider.dart';
import 'models/news_item.dart';
import 'news_repo.dart';

final newsRepoProvider = Provider<NewsRepo>((ref) {
  return NewsRepo(ref.watch(dioProvider));
});

class NewsQuery {
  final String category; // "" => tümü
  final String q;        // "" => aramasız
  const NewsQuery({this.category = '', this.q = ''});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsQuery &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          q == other.q;

  @override
  int get hashCode => category.hashCode ^ q.hashCode;
}

class NewsState {
  final List<NewsItem> items;
  final bool loading;
  final bool loadingMore;
  final String? nextCursor;
  final String? error;

  const NewsState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.nextCursor,
    this.error,
  });

  NewsState copyWith({
    List<NewsItem>? items,
    bool? loading,
    bool? loadingMore,
    String? nextCursor,
    String? error,
  }) {
    return NewsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      nextCursor: nextCursor ?? this.nextCursor,
      error: error,
    );
  }
}

final newsControllerProvider =
    NotifierProviderFamily<NewsController, NewsState, NewsQuery>(NewsController.new);

class NewsController extends FamilyNotifier<NewsState, NewsQuery> {
  static const _pageSize = 20;

  @override
  NewsState build(NewsQuery arg) {
    state = const NewsState(loading: true);
    _fetchInitial();
    return state;
  }

  Future<void> refresh() async {
    state = const NewsState(loading: true);
    await _fetchInitial();
  }

  Future<void> fetchMore() async {
    if (state.loadingMore) return;
    if (state.nextCursor == null) return;

    state = state.copyWith(loadingMore: true, error: null);

    try {
      final repo = ref.read(newsRepoProvider);
      final page = await repo.fetchNews(
        limit: _pageSize,
        category: arg.category.isEmpty ? null : arg.category,
        q: arg.q.isEmpty ? null : arg.q,
        cursor: state.nextCursor,
      );

      state = state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> _fetchInitial() async {
    try {
      final repo = ref.read(newsRepoProvider);
      final page = await repo.fetchNews(
        limit: _pageSize,
        category: arg.category.isEmpty ? null : arg.category,
        q: arg.q.isEmpty ? null : arg.q,
      );

      state = state.copyWith(
        items: page.items,
        nextCursor: page.nextCursor,
        loading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
