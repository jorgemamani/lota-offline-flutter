import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../config/environment/environment.dart';
import '../../errors/app_exception.dart';
import '../domain/http_client.dart';

class ApiHttpClient implements IHttpClient {
  ApiHttpClient({required this.httpClient});

  final Dio httpClient;

  String get _authority => Environment.instance.config.apiBaseUrl;

  static const _getMethod = 'GET';
  static const _postMethod = 'POST';
  static const _putMethod = 'PUT';
  static const _deleteMethod = 'DELETE';

  Map<String, String> _buildHeaders({String? token}) => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<(T?, AppException?)> _request<T extends Object>({
    required String method,
    required String endpoint,
    String? token,
    DeserializeFromJson<T>? deserializeResponseFunction,
    Map<String, dynamic>? payload,
    Map<String, String>? queryParams,
  }) async {
    final headers = _buildHeaders(token: token);
    final path = '$_authority$endpoint';
    log('[$method] $path — params: $queryParams');

    Response response;
    try {
      switch (method) {
        case _getMethod:
          response = await httpClient.get(
            path,
            options: Options(headers: headers),
            queryParameters: queryParams,
          );
        case _postMethod:
          headers['Content-Type'] = 'application/json';
          response = await httpClient.post(
            path,
            options: Options(headers: headers),
            queryParameters: queryParams,
            data: json.encode(payload),
          );
        case _putMethod:
          headers['Content-Type'] = 'application/json';
          response = await httpClient.put(
            path,
            options: Options(headers: headers),
            data: json.encode(payload),
          );
        case _deleteMethod:
          response = await httpClient.delete(
            path,
            options: Options(headers: headers),
          );
        default:
          throw ArgumentError('HTTP method no soportado: $method');
      }
    } on DioException catch (e) {
      log('Error [$method] $path — $e');
      if (e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.connectionError) {
        return (null, const AppException(code: '502', message: 'Sin conexión a internet'));
      }
      return (null, _parseErrorResponse(e));
    }

    return _parseSuccessResponse(response, deserializeResponseFunction);
  }

  AppException _parseErrorResponse(DioException e) {
    switch (e.response?.statusCode) {
      case 500:
        return const AppException(message: 'Error del servidor. Intentá más tarde.');
      case 404:
        return const AppException(message: 'Recurso no encontrado.');
      case 401:
        return const AppException(code: '401', message: 'No autorizado.');
      default:
        try {
          final data = e.response?.data is String
              ? json.decode(e.response!.data as String) as Map<String, dynamic>
              : e.response?.data as Map<String, dynamic>?;
          return AppException(message: data?['message'] as String? ?? e.message ?? 'Error desconocido');
        } catch (_) {
          return AppException(message: e.message ?? 'Error desconocido');
        }
    }
  }

  (T?, AppException?) _parseSuccessResponse<T extends Object>(
    Response response,
    DeserializeFromJson<T>? deserialize,
  ) {
    final status = response.statusCode;

    if (status == HttpStatus.noContent || status == HttpStatus.accepted) {
      return (null, null);
    }

    if (status == HttpStatus.ok || status == HttpStatus.created) {
      try {
        final data = response.data is String
            ? json.decode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final result = deserialize != null ? deserialize(data) : null;
        return (result, null);
      } catch (e) {
        return (null, AppException(message: e.toString()));
      }
    }

    return (null, AppException(message: response.statusMessage ?? 'Error inesperado', code: '$status'));
  }

  @override
  Future<(T?, AppException?)> get<T extends Object>({
    required String endpoint,
    required DeserializeFromJson<T> deserializeResponseFunction,
    Map<String, String>? queryParams,
    String? token,
  }) =>
      _request(
        method: _getMethod,
        endpoint: endpoint,
        token: token,
        queryParams: queryParams,
        deserializeResponseFunction: deserializeResponseFunction,
      );

  @override
  Future<(List<T>?, AppException?)> getList<T extends Object>({
    required String endpoint,
    required DeserializeFromJson<T> deserializeResponseFunction,
    Map<String, String>? queryParams,
    String? token,
  }) async {
    final headers = _buildHeaders(token: token);
    final path = '$_authority$endpoint';

    Response response;
    try {
      response = await httpClient.get(
        path,
        options: Options(headers: headers),
        queryParameters: queryParams,
      );
    } on DioException catch (e) {
      return (null, _parseErrorResponse(e));
    }

    if (response.statusCode == HttpStatus.ok) {
      try {
        final raw = response.data is String ? json.decode(response.data as String) : response.data;
        final list = (raw as List).map((e) => deserializeResponseFunction(e as Map<String, dynamic>)).toList();
        return (list, null);
      } catch (e) {
        return (null, AppException(message: e.toString()));
      }
    }

    return (null, AppException(message: response.statusMessage ?? 'Error', code: '${response.statusCode}'));
  }

  @override
  Future<(T?, AppException?)> post<T extends Object>({
    required String endpoint,
    required Map<String, dynamic> payload,
    required DeserializeFromJson<T> deserializeResponseFunction,
    Map<String, String>? queryParams,
    String? token,
  }) =>
      _request(
        method: _postMethod,
        endpoint: endpoint,
        token: token,
        payload: payload,
        queryParams: queryParams,
        deserializeResponseFunction: deserializeResponseFunction,
      );

  @override
  Future<(T?, AppException?)> put<T extends Object>({
    required String endpoint,
    required Map<String, dynamic> payload,
    required DeserializeFromJson<T> deserializeResponseFunction,
    String? token,
  }) =>
      _request(
        method: _putMethod,
        endpoint: endpoint,
        token: token,
        payload: payload,
        deserializeResponseFunction: deserializeResponseFunction,
      );

  @override
  Future<(bool, AppException?)> delete({
    required String endpoint,
    String? token,
  }) async {
    final result = await _request<_VoidResult>(
      method: _deleteMethod,
      endpoint: endpoint,
      token: token,
    );
    return (result.$2 == null, result.$2);
  }
}

// Tipo interno para llamadas que no retornan cuerpo
class _VoidResult {}
