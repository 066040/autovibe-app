import 'package:dio/dio.dart';
import '../models/article.dart';

class ArticlesRepo {
  final Dio dio;
  ArticlesRepo(this.dio);

  Future<List<Article>> fetchArticles({int limit = 30, String? cursor}) async {
    final res = await dio.get(
      '/articles',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final raw = res.data;

    // Backend: { data: [...], nextCursor: "..." }
    final List list = (raw is Map && raw['data'] is List) ? raw['data'] as List : const [];

    return list
        .map((e) => Article.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
