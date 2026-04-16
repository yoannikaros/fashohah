import 'package:dio/dio.dart';

import '../../domain/entities/prayer_day.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../datasources/prayer_local_datasource.dart';
import '../datasources/prayer_remote_datasource.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  PrayerRepositoryImpl({
    required this.remote,
    required this.local,
  });

  final PrayerRemoteDatasource remote;
  final PrayerLocalDatasource local;

  @override
  Future<List<PrayerDay>> getMonthPrayer({
    required int year,
    required int month,
    required String provinsi,
    required String kabkota,
  }) async {
    // 1. Cache valid untuk lokasi ini → return lokal (offline mode works)
    if (local.isCacheValid(year, month, provinsi: provinsi, kabkota: kabkota)) {
      final cached = local.getMonth(year, month);
      if (cached != null && cached.isNotEmpty) return List<PrayerDay>.from(cached);
    }

    // 2. Coba fetch dari remote
    try {
      final result = await remote.getMonthCalendar(
        year: year,
        month: month,
        provinsi: provinsi,
        kabkota: kabkota,
      );
      await local.saveMonth(year, month, result, provinsi: provinsi, kabkota: kabkota);
      return List<PrayerDay>.from(result);
    } catch (e) {
      // 3. Remote gagal → gunakan cache lama jika ada (offline mode)
      final cached = local.getMonth(year, month);
      if (cached != null && cached.isNotEmpty) return List<PrayerDay>.from(cached);

      // 4. API endpoint tidak ditemukan (404) → kembalikan list kosong,
      //    UI akan fallback ke HijriCalculator
      if (e is DioException && e.response?.statusCode == 404) {
        return const [];
      }

      // 5. Tidak ada cache sama sekali → rethrow dengan pesan yang jelas
      final msg = e.toString();
      final isNetwork = msg.contains('SocketException') ||
          msg.contains('Connection refused') ||
          msg.contains('Network') ||
          msg.contains('timeout');
      if (isNetwork) {
        throw Exception(
          'Tidak ada koneksi internet dan belum ada data offline. '
          'Harap connect ke internet untuk pertama kali.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<PrayerDay?> getTodayPrayer({
    required String provinsi,
    required String kabkota,
  }) async {
    final now = DateTime.now();
    final month = await getMonthPrayer(
      year: now.year,
      month: now.month,
      provinsi: provinsi,
      kabkota: kabkota,
    );
    return month.firstWhere(
      (d) => d.isToday,
      orElse: () => month.first,
    );
  }

  @override
  Future<bool> isMonthCached(int year, int month) async {
    return local.isMonthCached(year, month);
  }

  @override
  Future<void> clearOldCache() async {
    await local.clearOldCache();
  }
}
