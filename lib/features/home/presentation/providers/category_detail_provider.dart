import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/models/api_category_detail_model.dart';

final categoryDetailProvider =
    FutureProvider.family<ApiCategoryDetail, int>((ref, id) async {
  final dio = ref.watch(fashohahApiDioProvider);
  final response = await dio.get<Map<String, dynamic>>(
    '/api.php',
    queryParameters: {'kategori_id': id},
  );

  final data = response.data;
  if (data == null || data['status'] != 'ok') {
    throw Exception('Gagal memuat detail kategori');
  }

  return ApiCategoryDetail.fromJson(data['data'] as Map<String, dynamic>);
});
