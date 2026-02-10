import 'package:dio/dio.dart';

class ReactionsApi {
  final Dio dio;
  ReactionsApi(this.dio);

  Future<Map<String, dynamic>> toggleLike(String articleId) async {
    final res = await dio.post(
      '/likes/toggle',
      data: {'articleId': articleId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> toggleSaved(String articleId) async {
    final res = await dio.post(
      '/saved/toggle',
      data: {'articleId': articleId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<String>> myLikes() async {
    final res = await dio.get('/me/likes');
    return (res.data as List).cast<String>();
  }

  Future<List<String>> mySaved() async {
    final res = await dio.get('/me/saved');
    return (res.data as List).cast<String>();
  }
}
