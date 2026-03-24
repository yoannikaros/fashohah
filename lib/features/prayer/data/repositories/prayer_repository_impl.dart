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
    required double latitude,
    required double longitude,
  }) async {
    // 1. Cache valid → return lokal (offline mode works)
    if (local.isCacheValid(year, month)) {
      final cached = local.getMonth(year, month);
      if (cached != null && cached.isNotEmpty) return List<PrayerDay>.from(cached);
    }

    // 2. Coba fetch dari remote
    try {
      final remote = await this.remote.getMonthCalendar(
            year: year,
            month: month,
            latitude: latitude,
            longitude: longitude,
          );
      await local.saveMonth(year, month, remote);
      return List<PrayerDay>.from(remote);
    } catch (e) {
      // 3. Remote gagal → gunakan cache lama jika ada (offline mode)
      final cached = local.getMonth(year, month);
      if (cached != null && cached.isNotEmpty) return List<PrayerDay>.from(cached);

      // 4. Tidak ada cache sama sekali → rethrow
      throw Exception(
        'Tidak ada koneksi internet dan belum ada data offline. '
        'Harap connect ke internet untuk pertama kali. ($e)',
      );
    }
  }

  @override
  Future<PrayerDay?> getTodayPrayer({
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.now();
    final month = await getMonthPrayer(
      year: now.year,
      month: now.month,
      latitude: latitude,
      longitude: longitude,
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
