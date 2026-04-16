import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/prayer/presentation/providers/prayer_provider.dart';

// ─── Device ID Provider ──────────────────────────────────────────────────────

/// UUID v4 persisten — dibuat sekali, disimpan di SharedPreferences.
/// Digunakan sebagai X-Device-ID header untuk tracking konten premium (guest).
final deviceIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  const key = 'device_id';
  var id = prefs.getString(key);
  if (id == null) {
    id = _generateUuidV4();
    prefs.setString(key, id);
  }
  return id;
});

String _generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  // Set version 4
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Set variant bits
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(List<int> b) =>
      b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  return [
    hex(bytes.sublist(0, 4)),
    hex(bytes.sublist(4, 6)),
    hex(bytes.sublist(6, 8)),
    hex(bytes.sublist(8, 10)),
    hex(bytes.sublist(10, 16)),
  ].join('-');
}
