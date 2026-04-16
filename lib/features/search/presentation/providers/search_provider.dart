import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/models/search_models.dart';

final searchProvider =
    FutureProvider.autoDispose.family<SearchResults, String>((ref, query) async {
  if (query.trim().length < 2) return SearchResults.empty;

  final dio = ref.watch(fashohahApiDioProvider);
  final response = await dio.get<Map<String, dynamic>>(
    '/api.php',
    queryParameters: {'action': 'cari', 'q': query.trim()},
  );

  final data = response.data;
  if (data == null || data['status'] != 'ok') return SearchResults.empty;

  return SearchResults.fromJson(data['data'] as Map<String, dynamic>);
});
