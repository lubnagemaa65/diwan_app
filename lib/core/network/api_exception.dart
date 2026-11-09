import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خطأ موحّد يُعرض للمستخدم (رسالة جاهزة للعرض في SnackBar أو ErrorStateWidget).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final req = e.requestOptions;
        final is401 = e.response?.statusCode == 401;
        final isAuthCall = req.path.startsWith('/auth/');
        if (is401 && !isAuthCall && req.extra['retried'] != true) {
          final ok = await _refresh();
          if (ok) {
            req.extra['retried'] = true;
            final token = await _storage.read(key: _accessKey);
            req.headers['Authorization'] = 'Bearer $token';
            try {
              return handler.resolve(await dio.fetch(req));
            } on DioException catch (err) {
              return handler.next(err);
            }
          }
        }
        handler.next(e);
      },
    ));
  }

  static final ApiClient instance = ApiClient._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.66:3000/v1',
  );
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'current_user_json';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio dio;

  // ---------------- التوكنات والجلسة ----------------

  /// [tokens] هو الكائن الراجع من الباك اند: {access: {token, expires}, refresh: {token, expires}}
  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    final access = tokens['access']?['token'];
    final refresh = tokens['refresh']?['token'];
    if (access != null)
      await _storage.write(key: _accessKey, value: access.toString());
    if (refresh != null)
      await _storage.write(key: _refreshKey, value: refresh.toString());
  }

  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<bool> hasToken() async =>
      (await _storage.read(key: _accessKey)) != null;

  Future<void> saveUserJson(String json) =>
      _storage.write(key: _userKey, value: json);

  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }

  Future<bool> _refresh() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) return false;
    try {
      // Dio منفصل لتجنّب الدخول في حلقة مع الـ interceptor
      final res = await Dio(BaseOptions(baseUrl: baseUrl))
          .post('/auth/refresh-tokens', data: {'refreshToken': refresh});
      await saveTokens(Map<String, dynamic>.from(res.data as Map));
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  // ---------------- معالجة الأخطاء ----------------

  /// يلفّ أي طلب ويحوّل أخطاء Dio إلى [ApiException] برسالة مفهومة.
  static Future<T> guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  static ApiException _toException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(), statusCode: status);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
            'تعذّر الاتصال بالخادم، تحقق من الشبكة وعنوان الخادم',
            statusCode: status);
      default:
        return ApiException('حدث خطأ غير متوقع', statusCode: status);
    }
  }
}
