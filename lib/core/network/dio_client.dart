import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DioClient {
  DioClient._();

  static Dio create({required String baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
      ),
    ]);

    return dio;
  }
}

final equranDioProvider = Provider<Dio>((ref) {
  return DioClient.create(baseUrl: 'https://equran.id/api/v2');
});
