import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  final double latitude;
  final double longitude;

  /// True jika menggunakan lokasi default (GPS tidak tersedia).
  final bool isDefault;
}

/// Service untuk mendapatkan lokasi pengguna.
/// Jika GPS tidak tersedia → gunakan lokasi terakhir atau default (Jakarta).
class LocationService {
  LocationService(this._prefs);

  final SharedPreferences _prefs;

  static const _latKey = 'last_lat';
  static const _lngKey = 'last_lng';

  // Default: Jakarta, Indonesia
  static const _defaultLat = -6.2088;
  static const _defaultLng = 106.8456;

  Future<LocationResult> getCurrentLocation() async {
    // Windows: langsung coba tanpa permission check
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _tryGetPosition();
    }

    // Android/iOS: request permission dulu
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallbackLocation();
      }
    }

    return _tryGetPosition();
  }

  Future<LocationResult> _tryGetPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Simpan ke cache
      await _prefs.setDouble(_latKey, position.latitude);
      await _prefs.setDouble(_lngKey, position.longitude);

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isDefault: false,
      );
    } catch (_) {
      return _fallbackLocation();
    }
  }

  LocationResult _fallbackLocation() {
    final lat = _prefs.getDouble(_latKey);
    final lng = _prefs.getDouble(_lngKey);

    if (lat != null && lng != null) {
      return LocationResult(latitude: lat, longitude: lng, isDefault: false);
    }

    return const LocationResult(
      latitude: _defaultLat,
      longitude: _defaultLng,
      isDefault: true,
    );
  }

  /// Set lokasi manual (untuk setting oleh user).
  Future<void> setManualLocation(double lat, double lng) async {
    await _prefs.setDouble(_latKey, lat);
    await _prefs.setDouble(_lngKey, lng);
  }
}
