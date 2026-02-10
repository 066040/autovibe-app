import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_provider.dart';
import 'articles_api.dart';

final articlesApiProvider = Provider<ArticlesApi>((ref) {
  return ArticlesApi(ref.watch(dioProvider));
});
