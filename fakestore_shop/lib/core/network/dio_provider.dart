import 'package:dio/dio.dart';
import 'api_paths.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiPaths.baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      requestBody: false,
      responseBody: false,
    ),
  );

  return dio;
}
