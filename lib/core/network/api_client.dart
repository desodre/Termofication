// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'https://terminfication-api-943377901075.southamerica-east1.run.app';

  static String get _defaultBaseUrl {
    // URL de Produção hospedada no Google Cloud Run
    const productionUrl = 'https://terminfication-api-943377901075.southamerica-east1.run.app';

    // Para forçar a produção em todos os testes, apenas comente o bloco de debug abaixo:
    // if (!kReleaseMode) {
    //   if (kIsWeb) return 'http://127.0.0.1:8000';
    //   try {
    //     if (Platform.isAndroid || Platform.isIOS) return 'http://192.168.0.104:8000';
    //   } catch (_) {}
    //   return 'http://127.0.0.1:8000';
    // }

    return productionUrl;
  }

  final Dio _dio;

  ApiClient({String? baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? _defaultBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Tempo limite de conexão esgotado.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String? detailMsg;
        if (error.response?.data is Map) {
          final data = error.response!.data as Map;
          if (data['detail'] is String) {
            detailMsg = data['detail'] as String;
          } else if (data['detail'] is List) {
            try {
              detailMsg = (data['detail'] as List).first['msg'] as String;
            } catch (_) {}
          }
        }
        if (statusCode == 422) {
          return InvalidWordException(detailMsg ?? 'Palavra inválida ou de tamanho incorreto.');
        }
        return ServerException(detailMsg ?? 'Erro no servidor ($statusCode).');
      default:
        return NetworkException('Erro de rede: ${error.message}');
    }
  }
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class InvalidWordException implements Exception {
  final String message;
  InvalidWordException(this.message);
  @override
  String toString() => message;
}
