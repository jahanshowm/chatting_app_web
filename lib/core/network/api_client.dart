import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/config/app_env.dart';
import 'package:randomchat_admin/core/network/api_exception.dart';
import 'package:randomchat_admin/core/network/api_message_util.dart';
import 'package:randomchat_admin/core/network/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppEnv.apiBaseUrl}/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<T> getData<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final response = await _request(() => _dio.get(path, queryParameters: queryParameters));
    return _parseData(response, fromJson);
  }

  Future<List<T>> getListData<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final response = await _request(() => _dio.get(path, queryParameters: queryParameters));
    final envelope = _parseEnvelope(response);
    if (envelope is! List) {
      throw const ApiException('응답 형식이 올바르지 않습니다.');
    }
    return envelope.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<T> postData<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final response = await _request(() => _dio.post(path, data: data));
    return _parseData(response, fromJson);
  }

  Future<T> patchData<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final response = await _request(() => _dio.patch(path, data: data));
    return _parseData(response, fromJson);
  }

  Future<T> deleteData<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.delete(path, data: data, queryParameters: queryParameters),
    );
    return _parseData(response, fromJson);
  }

  Future<T> postFormData<T>(
    String path, {
    required FormData formData,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
    return _parseData(response, fromJson);
  }

  Future<T> patchFormData<T>(
    String path, {
    required FormData formData,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.patch(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
    return _parseData(response, fromJson);
  }

  Future<Response<dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  T _parseData<T>(Response<dynamic> response, T Function(Map<String, dynamic> json)? fromJson) {
    final envelope = _parseEnvelope(response);
    if (fromJson == null) return envelope as T;
    if (envelope == null) throw const ApiException('응답 데이터가 없습니다.');
    if (envelope is Map<String, dynamic>) return fromJson(envelope);
    throw const ApiException('응답 형식이 올바르지 않습니다.');
  }

  dynamic _parseEnvelope(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const ApiException('서버 응답 형식이 올바르지 않습니다.');
    }
    final success = body['success'] as bool? ?? false;
    if (!success) {
      throw ApiException(parseApiErrorMessage(body), statusCode: response.statusCode);
    }
    return body['data'];
  }

  ApiException _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final parsed = parseApiErrorMessage(data, fallback: '');
      if (parsed.isNotEmpty) {
        return ApiException(parsed, statusCode: e.response?.statusCode);
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('서버 응답 시간이 초과되었습니다.');
      case DioExceptionType.connectionError:
        return const ApiException('서버에 연결할 수 없습니다.');
      default:
        return ApiException(e.message ?? '네트워크 오류가 발생했습니다.', statusCode: e.response?.statusCode);
    }
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(tokenStorageProvider)));
