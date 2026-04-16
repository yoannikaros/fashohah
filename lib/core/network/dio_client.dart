import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/device_id_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class DioClient {
  DioClient._();

  static Dio create({
    required String baseUrl,
    String? token,
    String? deviceId,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          if (deviceId != null) 'X-Device-ID': deviceId,
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
      ),
    );

    return dio;
  }
}

// ─── Al-Qur'an API (tidak memerlukan auth) ──────────────────────────────────
final equranDioProvider = Provider<Dio>((ref) {
  return DioClient.create(baseUrl: 'https://equran.id/api/v2');
});

// ─── Fashohah API (dengan auth token + device ID) ───────────────────────────
final fashohahApiDioProvider = Provider<Dio>((ref) {
  final authUser = ref.watch(authProvider);
  final deviceId = ref.watch(deviceIdProvider);

  return DioClient.create(
    baseUrl: 'http://192.168.1.5:8000',
    token: authUser?.token,
    deviceId: deviceId,
  );
});
