import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../prayer/presentation/providers/prayer_provider.dart';
import '../../data/models/auth_models.dart';

// ─── Auth Notifier ──────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthUser?> {
  static const _key = 'auth_user_json';
  static const _baseUrl = 'http://192.168.1.5:8000';

  final SharedPreferences _prefs;

  AuthNotifier(this._prefs) : super(null) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final jsonStr = _prefs.getString(_key);
    state = AuthUser.tryFromStorage(jsonStr);
  }

  /// Buat Dio khusus auth (tanpa Bearer token)
  Dio _makeDio() => Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ));

  /// Login → kembalikan pesan error jika gagal, null jika sukses
  Future<String?> login(String email, String password) async {
    final dio = _makeDio();
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth.php',
        queryParameters: {'action': 'login'},
        data: {'email': email, 'password': password},
      );
      final body = response.data!;
      if (body['status'] != 'ok') {
        return (body['message'] as String?) ?? 'Login gagal';
      }
      final user = AuthUser.fromJson(body['data'] as Map<String, dynamic>);
      state = user;
      await _prefs.setString(_key, jsonEncode(user.toJson()));
      return null;
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      return msg ?? 'Koneksi gagal. Coba lagi.';
    } catch (_) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  /// Register → auto-login setelah berhasil
  Future<String?> register({
    required String nama,
    required String namaPanggilan,
    required String email,
    required String password,
    required String pin,
  }) async {
    final dio = _makeDio();
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth.php',
        queryParameters: {'action': 'register'},
        data: {
          'nama': nama,
          'nama_panggilan': namaPanggilan,
          'email': email,
          'password': password,
          'pin': pin,
        },
      );
      final body = response.data!;
      if (body['status'] != 'ok') {
        return (body['message'] as String?) ?? 'Daftar gagal';
      }
      // Auto-login
      return await login(email, password);
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      return msg ?? 'Koneksi gagal. Coba lagi.';
    } catch (_) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  /// Logout — kirim request ke server lalu hapus state lokal
  Future<void> logout() async {
    final token = state?.token;
    if (token != null) {
      try {
        final dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));
        await dio.post<void>(
          '/api/auth.php',
          queryParameters: {'action': 'logout'},
        );
      } catch (_) {
        // Tetap logout lokal meskipun request gagal
      }
    }
    state = null;
    await _prefs.remove(_key);
  }

  /// Refresh status premium dari server
  Future<void> refreshPremiumStatus() async {
    final token = state?.token;
    if (token == null) return;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.get<Map<String, dynamic>>(
        '/api/payment.php',
        queryParameters: {'action': 'status'},
      );
      final body = response.data!;
      if (body['status'] == 'ok') {
        final data = body['data'] as Map<String, dynamic>;
        final updated = state!.copyWith(
          isPremium: data['is_premium'] == true || data['is_premium'] == 1,
          premiumSince: data['premium_since'] as String?,
        );
        state = updated;
        await _prefs.setString(_key, jsonEncode(updated.toJson()));
      }
    } catch (_) {}
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthUser?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs);
});

/// true jika user sudah login
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

/// true jika user adalah premium subscriber
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(authProvider)?.isPremium ?? false;
});
