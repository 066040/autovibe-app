import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_provider.dart';
import 'comments_api.dart';

final commentsApiProvider = Provider<CommentsApi>((ref) {
  return CommentsApi(ref.watch(dioProvider));
});
