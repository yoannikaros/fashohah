import 'package:dio/dio.dart';

/// Datasource untuk mengambil daftar provinsi dan kabkota dari equran.id API v2.
class PrayerRegionDatasource {
  PrayerRegionDatasource(this._dio);

  final Dio _dio;

  // Relative paths — baseUrl sudah di-set ke https://equran.id/api/v2
  static const _provinsiPath = '/shalat/provinsi';
  static const _kabkotaPath = '/shalat/kabkota';

  /// Ambil daftar provinsi. Returns nama provinsi sebagai flat list string.
  Future<List<String>> fetchProvinsi() async {
    final response = await _dio.get<Map<String, dynamic>>(_provinsiPath);
    final data = response.data;
    final code = data?['code'];
    if (data == null || code?.toString() != '200') {
      throw Exception('Gagal mengambil daftar provinsi (code=$code)');
    }
    final list = data['data'] as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  /// Ambil daftar kabupaten/kota untuk provinsi tertentu. Returns flat list string.
  Future<List<String>> fetchKabkota(String provinsi) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _kabkotaPath,
      data: {'provinsi': provinsi},
    );
    final data = response.data;
    final code = data?['code'];
    if (data == null || code?.toString() != '200') {
      throw Exception('Gagal mengambil daftar kabkota untuk $provinsi (code=$code)');
    }
    final list = data['data'] as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }
}
