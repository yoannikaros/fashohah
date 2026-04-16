import 'package:dio/dio.dart';

import '../models/prayer_day_model.dart';

class PrayerRemoteDatasource {
  PrayerRemoteDatasource(this._dio);

  final Dio _dio;

  // Relative path — baseUrl sudah di-set ke https://equran.id/api/v2
  static const _path = '/shalat';

  /// Ambil jadwal sholat 1 bulan dari equran.id API v2.
  Future<List<PrayerDayModel>> getMonthCalendar({
    required int year,
    required int month,
    required String provinsi,
    required String kabkota,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path,
      data: {
        'provinsi': provinsi,
        'kabkota': kabkota,
        'bulan': month,   // int, bukan string
        'tahun': year,    // int, bukan string
      },
    );

    final data = response.data;
    final code = data?['code'];
    if (data == null || code?.toString() != '200') {
      throw Exception(
        'Gagal mengambil jadwal sholat (code=$code): ${data?['message'] ?? 'Unknown error'}',
      );
    }

    final rawData = data['data'];
    final jadwal = rawData is Map
        ? (rawData['jadwal'] as List<dynamic>)
        : (rawData as List<dynamic>);
    return jadwal
        .map((e) => PrayerDayModel.fromEquran(
              e as Map<String, dynamic>,
              year,
              month,
            ))
        .toList();
  }
}
