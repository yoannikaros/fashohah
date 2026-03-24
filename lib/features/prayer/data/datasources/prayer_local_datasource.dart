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

  /// Simpan jadwal 1 bulan ke Hive.
  Future<void> saveMonth(
    int year,
    int month,
    List<PrayerDayModel> days,
  ) async {
    final jsonList = days.map((d) => d.toJson()).toList();
    await _box.put(_key(year, month), jsonEncode(jsonList));

    // Simpan timestamp untuk tracking kapan data di-fetch
    await _metaBox.put(
      '${_key(year, month)}_fetchedAt',
      DateTime.now().toIso8601String(),
    );
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

  /// Cek apakah cache masih valid (< 7 hari untuk bulan berjalan, permanent untuk bulan lalu).
  bool isCacheValid(int year, int month) {
    final now = DateTime.now();
    // Bulan lalu atau lebih → cache permanent (tidak perlu refresh)
    if (year < now.year || (year == now.year && month < now.month)) {
      return isMonthCached(year, month);
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
