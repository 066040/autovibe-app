import 'package:dio/dio.dart';

class ArticleMini {
  final String id;
  final String title;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final String sourceName;

  ArticleMini({
    required this.id,
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.createdAt,
    required this.sourceName,
  });

  factory ArticleMini.fromJson(Map<String, dynamic> j) {
    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
    return ArticleMini(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
      imageUrl: (j['imageUrl'] == null || (j['imageUrl'] as String).trim().isEmpty)
          ? null
          : (j['imageUrl'] as String),
      publishedAt: _dt(j['publishedAt']),
      createdAt: _dt(j['createdAt']) ?? DateTime.now(),
      sourceName: ((j['source']?['name']) ?? '').toString(),
    );
  }
}

class ArticlesApi {
  final Dio dio;
  ArticlesApi(this.dio);

  Future<List<ArticleMini>> byIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final q = ids.join(',');
    final res = await dio.get('/articles/by-ids', queryParameters: {'ids': q});
    final list = (res.data as List);
    return list.map((e) => ArticleMini.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
