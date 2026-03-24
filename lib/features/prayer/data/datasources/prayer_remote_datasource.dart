import 'package:dio/dio.dart';

import '../models/prayer_day_model.dart';

class PrayerRemoteDatasource {
  PrayerRemoteDatasource(this._dio);

  final Dio _dio;

  // Method 11 = Muslim World League (standard internasional)
  // Method 20 = Kemenag RI (untuk Indonesia)
  static const _defaultMethod = 11;

  /// Ambil jadwal sholat 1 bulan dari Aladhan API.
  Future<List<PrayerDayModel>> getMonthCalendar({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    int method = _defaultMethod,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.aladhan.com/v1/calendar/$year/$month',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'method': method,
      },
    );

    final data = response.data;
    if (data == null || data['code'] != 200) {
      throw Exception(
        'Gagal mengambil jadwal sholat: ${data?['status'] ?? 'Unknown error'}',
      );
    }

    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => PrayerDayModel.fromAladhan(e as Map<String, dynamic>))
        .toList();
  }
}
