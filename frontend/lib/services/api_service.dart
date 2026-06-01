import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import '../core/constants.dart';
import '../core/exceptions.dart';

class ApiService extends GetxService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl:        AgroConfig.backendBaseUrl,
      connectTimeout: AgroConfig.httpConnectTimeout,
      receiveTimeout: AgroConfig.httpReceiveTimeout,
      headers:        {'Content-Type': 'application/json'},
    ));
    _addInterceptors();
  }

  void _addInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AgroStorageKeys.authToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) => handler.next(response),
      onError: (error, handler) {
        final agro = _mapError(error);
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          error:   agro,
          message: agro.message,
        ));
      },
    ));
  }

  AgroException _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NoConnectionException();
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        final msg  = error.response?.data?['detail'] as String?
            ?? 'Error del servidor';
        return BackendException(msg, statusCode: code);
      default:
        return AgroException(
          'Error inesperado: ${error.message}',
          technicalDetail: error.toString(),
        );
    }
  }

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? params}) =>
      _dio.get<T>(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> postMultipart<T>(String path, FormData formData) =>
      _dio.post<T>(path, data: formData);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  void updateBaseUrl(String newUrl) => _dio.options.baseUrl = newUrl;
}