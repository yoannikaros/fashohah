import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/prayer_day_model.dart';

/// Local datasource menggunakan Hive.
/// Key: "{year}-{month}" → Value: JSON encoded list of PrayerDayModel.
class PrayerLocalDatasource {
  static const _boxName = 'prayer_times';
  static const _metaBoxName = 'prayer_meta';

  late Box<String> _box;
  late Box<String> _metaBox;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    _metaBox = await Hive.openBox<String>(_metaBoxName);
  }

  String _key(int year, int month) => '$year-$month';

  /// Simpan jadwal 1 bulan ke Hive, beserta info lokasi.
  Future<void> saveMonth(
    int year,
    int month,
    List<PrayerDayModel> days, {
    String provinsi = '',
    String kabkota = '',
  }) async {
    final jsonList = days.map((d) => d.toJson()).toList();
    await _box.put(_key(year, month), jsonEncode(jsonList));

    // Simpan timestamp dan lokasi untuk validasi cache
    final prefix = _key(year, month);
    await _metaBox.put('${prefix}_fetchedAt', DateTime.now().toIso8601String());
    await _metaBox.put('${prefix}_provinsi', provinsi);
    await _metaBox.put('${prefix}_kabkota', kabkota);
  }

  /// Baca jadwal 1 bulan dari Hive. Return null jika belum ada.
  List<PrayerDayModel>? getMonth(int year, int month) {
    final raw = _box.get(_key(year, month));
    if (raw == null) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PrayerDayModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Cek apakah data bulan sudah di-cache.
  bool isMonthCached(int year, int month) {
    return _box.containsKey(_key(year, month));
  }

  /// Cek apakah cache masih valid untuk lokasi tertentu.
  /// Bulan lalu → permanent (kecuali lokasi berbeda).
  /// Bulan ini/depan → valid 7 hari dan lokasi harus cocok.
  bool isCacheValid(int year, int month, {String provinsi = '', String kabkota = ''}) {
    if (!isMonthCached(year, month)) return false;

    // Validasi lokasi — jika berbeda dari cache, paksa re-fetch
    if (provinsi.isNotEmpty || kabkota.isNotEmpty) {
      final prefix = _key(year, month);
      final cachedProvinsi = _metaBox.get('${prefix}_provinsi') ?? '';
      final cachedKabkota = _metaBox.get('${prefix}_kabkota') ?? '';
      if (cachedProvinsi != provinsi || cachedKabkota != kabkota) return false;
    }

    final now = DateTime.now();
    // Bulan lalu atau lebih → cache permanent (lokasi sudah cocok di atas)
    if (year < now.year || (year == now.year && month < now.month)) {
      return true;
    }

    // Bulan ini atau depan → cache valid 7 hari
    final fetchedRaw = _metaBox.get('${_key(year, month)}_fetchedAt');
    if (fetchedRaw == null) return false;

    final fetchedAt = DateTime.tryParse(fetchedRaw);
    if (fetchedAt == null) return false;

    return now.difference(fetchedAt).inDays < 7;
  }

  /// Hapus data bulan lama (> 2 bulan yang lalu) untuk hemat storage.
  Future<void> clearOldCache() async {
    final now = DateTime.now();
    final keysToDelete = <String>[];

    for (final key in _box.keys) {
      final parts = key.toString().split('-');
      if (parts.length != 2) continue;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year == null || month == null) continue;

      final diff = (now.year - year) * 12 + (now.month - month);
      if (diff > 2) keysToDelete.add(key.toString());
    }

    for (final key in keysToDelete) {
      await _box.delete(key);
      await _metaBox.delete('${key}_fetchedAt');
    }
  }
}
