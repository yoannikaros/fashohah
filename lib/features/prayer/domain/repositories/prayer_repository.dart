import '../entities/prayer_day.dart';

abstract interface class PrayerRepository {
  /// Ambil jadwal 1 bulan. Cek cache lokal dulu, fetch remote jika perlu.
  Future<List<PrayerDay>> getMonthPrayer({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
  });

  /// Shortcut untuk hari ini.
  Future<PrayerDay?> getTodayPrayer({
    required double latitude,
    required double longitude,
  });

  /// Cek apakah data bulan ini sudah ada di cache lokal.
  Future<bool> isMonthCached(int year, int month);

  /// Hapus cache lama (opsional, untuk maintenance).
  Future<void> clearOldCache();
}
