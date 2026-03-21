import '../../errors/app_exception.dart';

typedef DeserializeFromJson<T> = T Function(Map<String, dynamic> json);

abstract class IHttpClient {
  Future<(T?, AppException?)> get<T extends Object>({
    required String endpoint,
    required DeserializeFromJson<T> deserializeResponseFunction,
    Map<String, String>? queryParams,
    String? token,
  });

  Future<(List<T>?, AppException?)> getList<T extends Object>({
    required String endpoint,
    required DeserializeFromJson<T> deserializeResponseFunction,
    Map<String, String>? queryParams,
    String? token,
  });

  Future<(T?, AppException?)> post<T extends Object>({
    required String endpoint,
    required Map<String, dynamic> payload,
    required DeserializeFromJson<T> deserializeResponseFunction,
    Map<String, String>? queryParams,
    String? token,
  });

  Future<(T?, AppException?)> put<T extends Object>({
    required String endpoint,
    required Map<String, dynamic> payload,
    required DeserializeFromJson<T> deserializeResponseFunction,
    String? token,
  });

  Future<(bool, AppException?)> delete({
    required String endpoint,
    String? token,
  });
}
