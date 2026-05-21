import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

final apiClientProvider = Provider((ref) => ApiClient(ref));

class ApiClient {
  static const _baseUrl = 'http://10.0.2.2:3000/api'; //http://192.168.1.7:3000/api
  late final Dio _dio;
  final Ref _ref;

  ApiClient(this._ref) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = _ref.read(secureStorageProvider);
        final token = await storage.read(key: 'jwt_token');
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // Handle unauthorized (e.g. logout)
          _ref.read(authStateProvider.notifier).logout();
        }
        return handler.next(e);
      },
    ));
  }

  Future<Response> post(String path, dynamic data) => _dio.post(path, data: data);
  Future<Response> get(String path, {Map<String, dynamic>? params}) => 
      _dio.get(path, queryParameters: params);
  Future<Response> put(String path, dynamic data) => _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
}
