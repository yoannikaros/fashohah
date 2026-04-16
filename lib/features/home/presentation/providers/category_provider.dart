import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/models/api_category_model.dart';

final apiCategoryProvider =
    FutureProvider<List<ApiCategory>>((ref) async {
  final dio = ref.watch(fashohahApiDioProvider);
  final response =
      await dio.get('/api.php', queryParameters: {'action': 'kategori'});

  final data = response.data as Map<String, dynamic>;
  if (data['status'] != 'ok') throw Exception('Gagal memuat kategori');

  final list = data['data'] as List<dynamic>;
  return list
      .map((e) => ApiCategory.fromJson(e as Map<String, dynamic>))
      .toList();
});
