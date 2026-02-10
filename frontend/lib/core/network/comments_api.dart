import 'package:dio/dio.dart';

class CommentDto {
  final String id;
  final String text;
  final DateTime createdAt;
  final String userName;

  CommentDto({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.userName,
  });

  factory CommentDto.fromJson(Map<String, dynamic> j) {
    return CommentDto(
      id: (j['id'] ?? '').toString(),
      text: (j['text'] ?? j['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
      userName: ((j['user']?['name'] ?? j['userName'] ?? 'demo') as String).toString(),
    );
  }
}

class CommentsApi {
  final Dio dio;
  CommentsApi(this.dio);

  Future<List<CommentDto>> listByArticle(String articleId) async {
    final res = await dio.get('/comments/articles/$articleId');
    final data = res.data;

    if (data is List) {
      return data.map((e) => CommentDto.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    // bazen {items:[...]} gibi dönerse
    final items = (data['items'] as List?) ?? const [];
    return items.map((e) => CommentDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<CommentDto> create(String articleId, String text) async {
    final res = await dio.post('/comments/articles/$articleId', data: {'text': text});
    return CommentDto.fromJson(Map<String, dynamic>.from(res.data));
  }
}
