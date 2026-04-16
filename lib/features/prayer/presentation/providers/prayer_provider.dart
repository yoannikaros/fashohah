import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/datasources/prayer_local_datasource.dart';
import '../../data/datasources/prayer_region_datasource.dart';
import '../../data/datasources/prayer_remote_datasource.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../../data/services/prayer_location_matcher.dart';
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
  return PrayerRemoteDatasource(ref.watch(equranDioProvider));
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepositoryImpl(
    remote: ref.watch(prayerRemoteDatasourceProvider),
    local: ref.watch(prayerLocalDatasourceProvider),
  );
});

// ─── Location Provider (GPS — dipakai untuk indikator UI) ─────────────────

final locationProvider = FutureProvider<LocationResult>((ref) async {
  return ref.watch(locationServiceProvider).getCurrentLocation();
});

// ─── Prayer Location Provider (kota untuk API sholat) ─────────────────────

/// Provider provinsi untuk jadwal sholat. Default: DKI Jakarta.
final prayerProvinsiProvider = StateProvider<String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return prefs.getString('prayer_provinsi') ?? 'DKI Jakarta';
});

/// Provider kabupaten/kota untuk jadwal sholat. Default: Kota Jakarta Pusat.
final prayerKabkotaProvider = StateProvider<String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  final saved = prefs.getString('prayer_kabkota');
  // Migrasi: nilai lama 'Kota Jakarta' tidak valid di API v2
  if (saved == null || saved == 'Kota Jakarta') return 'Kota Jakarta Pusat';
  return saved;
});

// ─── Prayer Providers ──────────────────────────────────────────────────────

/// Provider untuk jadwal hari ini.
/// Side-effect: menjadwalkan notifikasi 7 hari ke depan sesuai pengaturan.
final todayPrayerProvider = FutureProvider<PrayerDay?>((ref) async {
  final provinsi = ref.watch(prayerProvinsiProvider);
  final kabkota = ref.watch(prayerKabkotaProvider);
  final now = DateTime.now();

  // Ambil data bulan penuh (sudah cache-first)
  final month = await ref.watch(prayerRepositoryProvider).getMonthPrayer(
        year: now.year,
        month: now.month,
        provinsi: provinsi,
        kabkota: kabkota,
      );

  // API returned no data for this location (e.g. 404) — show fallback UI
  if (month.isEmpty) return null;

  final today = month.firstWhere(
    (d) => d.isToday,
    orElse: () => month.first,
  );

  // Filter 7 hari ke depan mulai hari ini
  final todayDate = DateTime(now.year, now.month, now.day);
  var nextDays = month
      .where((d) => !d.date.isBefore(todayDate))
      .take(7)
      .toList();

  // Jika sisa hari bulan ini < 7, tambahkan awal bulan berikutnya
  if (nextDays.length < 7) {
    final nextMonthDate = now.month == 12
        ? DateTime(now.year + 1, 1)
        : DateTime(now.year, now.month + 1);
    try {
      final nextMonth =
          await ref.watch(prayerRepositoryProvider).getMonthPrayer(
                year: nextMonthDate.year,
                month: nextMonthDate.month,
                provinsi: provinsi,
                kabkota: kabkota,
              );
      final needed = 7 - nextDays.length;
      nextDays = [...nextDays, ...nextMonth.take(needed)];
    } catch (_) {
      // Gagal fetch bulan berikutnya — tetap pakai data yang ada
    }
  }

  // Baca pengaturan notifikasi langsung dari SharedPreferences
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
  final provinsi = ref.watch(prayerProvinsiProvider);
  final kabkota = ref.watch(prayerKabkotaProvider);
  return ref.watch(prayerRepositoryProvider).getMonthPrayer(
        year: params.year,
        month: params.month,
        provinsi: provinsi,
        kabkota: kabkota,
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

// ─── Region Datasource ────────────────────────────────────────────────────────

final prayerRegionDatasourceProvider = Provider<PrayerRegionDatasource>((ref) {
  return PrayerRegionDatasource(ref.watch(equranDioProvider));
});

// ─── Auto Location Provider ───────────────────────────────────────────────────

/// GPS → reverse geocode → match ke daftar equran.id → set provinsi & kabkota.
/// Hanya berjalan di Android/iOS. Jika gagal, tidak mengubah nilai yang ada.
final prayerAutoLocationProvider = FutureProvider<void>((ref) async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final location = await ref.watch(locationProvider.future);
  if (location.isDefault) return;

  try {
    final placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    if (placemarks.isEmpty) return;

    final placemark = placemarks.first;

    // Ambil daftar provinsi dari equran.id
    final regionDs = ref.read(prayerRegionDatasourceProvider);
    final provinsiList = await regionDs.fetchProvinsi();

    // Match provinsi (administrativeArea dari geocoding)
    final provinsiQuery = placemark.administrativeArea ?? '';
    final matchedProvinsi =
        PrayerLocationMatcher.bestMatch(provinsiQuery, provinsiList);
    if (matchedProvinsi == null) return;

    // Ambil daftar kabkota untuk provinsi yang cocok
    final kabkotaList = await regionDs.fetchKabkota(matchedProvinsi);

    // Match kabkota (subAdministrativeArea atau locality dari geocoding)
    final kabkotaQuery =
        placemark.subAdministrativeArea ?? placemark.locality ?? '';
    final matchedKabkota =
        PrayerLocationMatcher.bestMatch(kabkotaQuery, kabkotaList);
    if (matchedKabkota == null) return;

    // Update providers jika berbeda
    if (ref.read(prayerProvinsiProvider) != matchedProvinsi) {
      ref.read(prayerProvinsiProvider.notifier).state = matchedProvinsi;
    }
    if (ref.read(prayerKabkotaProvider) != matchedKabkota) {
      ref.read(prayerKabkotaProvider.notifier).state = matchedKabkota;
    }

    // Simpan ke SharedPreferences agar persist antar sesi
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('prayer_provinsi', matchedProvinsi);
    await prefs.setString('prayer_kabkota', matchedKabkota);
  } catch (_) {
    // Gagal silently — tetap pakai nilai yang ada
  }
});
