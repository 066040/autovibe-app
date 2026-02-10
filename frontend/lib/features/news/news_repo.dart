import 'package:dio/dio.dart';
import 'models/news_item.dart';

class NewsPage {
  final List<NewsItem> items;
  final String? nextCursor;
  const NewsPage({required this.items, required this.nextCursor});
}

class NewsRepo {
  final Dio dio;
  NewsRepo(this.dio);

  Future<NewsPage> fetchNews({
    required int limit,
    String? category,
    String? q,
    String? cursor,
  }) async {
    final res = await dio.get(
      '/news',
      queryParameters: {
        'limit': limit,
        if (category != null && category.isNotEmpty) 'category': category,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final data = (res.data as Map).cast<String, dynamic>();
    final itemsRaw = (data['items'] as List).cast<Map<String, dynamic>>();

    final items = itemsRaw.map(NewsItem.fromJson).toList();
    final nextCursor = data['nextCursor'] as String?;

    return NewsPage(items: items, nextCursor: nextCursor);
  }
}
