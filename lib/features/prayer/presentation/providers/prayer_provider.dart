import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/datasources/prayer_local_datasource.dart';
import '../../data/datasources/prayer_remote_datasource.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../../domain/entities/prayer_day.dart';
import '../../domain/repositories/prayer_repository.dart';

// Kunci SharedPreferences notifikasi — harus konsisten dengan settings_provider
String _notifKey(String name) => 'notif_${name.toLowerCase()}';

// ─── Infrastructure Providers ──────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref.watch(sharedPreferencesProvider));
});

final prayerLocalDatasourceProvider =
    Provider<PrayerLocalDatasource>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final prayerRemoteDatasourceProvider =
    Provider<PrayerRemoteDatasource>((ref) {
  return PrayerRemoteDatasource(
    ref.watch(equranDioProvider), // pakai Dio yang sama, beda base URL ditangani di datasource
  );
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepositoryImpl(
    remote: ref.watch(prayerRemoteDatasourceProvider),
    local: ref.watch(prayerLocalDatasourceProvider),
  );
});

// ─── Location Provider ─────────────────────────────────────────────────────

final locationProvider = FutureProvider<LocationResult>((ref) async {
  return ref.watch(locationServiceProvider).getCurrentLocation();
});

// ─── Prayer Providers ──────────────────────────────────────────────────────

/// Provider untuk jadwal hari ini.
/// Side-effect: menjadwalkan notifikasi 7 hari ke depan sesuai pengaturan.
final todayPrayerProvider = FutureProvider<PrayerDay?>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final now = DateTime.now();

  // Ambil data bulan penuh (sudah cache-first)
  final month = await ref.watch(prayerRepositoryProvider).getMonthPrayer(
        year: now.year,
        month: now.month,
        latitude: location.latitude,
        longitude: location.longitude,
      );

  final today = month.firstWhere(
    (d) => d.isToday,
    orElse: () => month.first,
  );

  // Filter 7 hari ke depan mulai hari ini
  final todayDate = DateTime(now.year, now.month, now.day);
  final nextDays = month
      .where((d) => !d.date.isBefore(todayDate))
      .take(7)
      .toList();

  // Baca pengaturan notifikasi langsung dari SharedPreferences
  // (menghindari circular import dengan settings_provider)
  final prefs = ref.read(sharedPreferencesProvider);
  final masterEnabled = prefs.getBool('notif_master') ?? true;
  final prayerEnabled = {
    for (final name in notifPrayerNames)
      name: prefs.getBool(_notifKey(name)) ?? (name != 'Imsak'),
  };

  await NotificationService.instance.scheduleWeekPrayers(
    days: nextDays,
    masterEnabled: masterEnabled,
    prayerEnabled: prayerEnabled,
  );

  return today;
});

/// Provider untuk jadwal 1 bulan.
final monthPrayerProvider =
    FutureProvider.family<List<PrayerDay>, ({int year, int month})>(
        (ref, params) async {
  final location = await ref.watch(locationProvider.future);
  return ref.watch(prayerRepositoryProvider).getMonthPrayer(
        year: params.year,
        month: params.month,
        latitude: location.latitude,
        longitude: location.longitude,
      );
});

/// Tracking bulan yang sedang ditampilkan di kalender.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final selectedMonthPrayerProvider =
    FutureProvider<List<PrayerDay>>((ref) async {
  final selected = ref.watch(selectedMonthProvider);
  return ref.watch(
    monthPrayerProvider((year: selected.year, month: selected.month)).future,
  );
});
