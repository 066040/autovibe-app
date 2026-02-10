import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_provider.dart';
import 'reactions_api.dart';

final reactionsApiProvider = Provider<ReactionsApi>((ref) {
  return ReactionsApi(ref.watch(dioProvider));
});
