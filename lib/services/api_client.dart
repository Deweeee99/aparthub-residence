import 'package:dio/dio.dart';

import 'app_debug_logger.dart';

class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ),
          );

  static const baseUrl = 'https://airaai.my.id/admin/api';

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    String? token,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send('GET', path, token: token, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    String? token,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      'POST',
      path,
      data: data,
      token: token,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    String? token,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      'PATCH',
      path,
      data: data,
      token: token,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> _send(
    String method,
    String path, {
    Object? data,
    String? token,
    Map<String, dynamic>? queryParameters,
  }) async {
    appDebugLog(
      'ApiClient',
      '$method $path started${token == null || token.isEmpty ? '' : ' with token ${maskToken(token)}'}',
    );

    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      appDebugLog(
        'ApiClient',
        '$method $path success (${response.statusCode ?? 'no-status'})',
      );
      return response;
    } on DioException catch (error) {
      appDebugLog(
        'ApiClient',
        '$method $path failed (${error.response?.statusCode ?? 'no-status'}) ${error.message ?? 'unknown error'}',
      );
      rethrow;
    } catch (error) {
      appDebugLog('ApiClient', '$method $path failed ($error)');
      rethrow;
    }
  }
}
