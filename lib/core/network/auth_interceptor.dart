import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor مركزي:
/// 1. يضيف Authorization: Bearer <token> لكل طلب.
/// 2. عند استلام 401 يحاول تجديد التوكن عبر Refresh Token مرة واحدة،
///    ثم يعيد تنفيذ الطلب الأصلي تلقائيًا.
/// 3. عند فشل التجديد ينظّف الجلسة ويستدعي [onSessionExpired].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, this.onSessionExpired});

  final Dio dio;
  final Future<void> Function()? onSessionExpired;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // لا نضيف التوكن لطلبات تسجيل الدخول/استعادة كلمة المرور
    final isAuthFreeRoute = options.path.contains(ApiConstants.login) ||
        options.path.contains(ApiConstants.forgotPassword) ||
        options.path.contains(ApiConstants.resetPassword);

    if (!isAuthFreeRoute) {
      final token = await SecureStorageService.instance.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    final isAuthFreeRoute = err.requestOptions.path.contains(ApiConstants.login);

    if (statusCode == 401 && !isAuthFreeRoute && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _refreshToken();
        _isRefreshing = false;

        if (refreshed) {
          // أعد تنفيذ الطلب الأصلي مع التوكن الجديد
          final retryResponse = await _retry(err.requestOptions);
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        _isRefreshing = false;
      }

      // فشل التجديد => انتهت الجلسة فعليًا
      await SecureStorageService.instance.clearSession();
      if (onSessionExpired != null) {
        await onSessionExpired!();
      }
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await SecureStorageService.instance.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] ?? response.data['token'];
      final newRefreshToken = response.data['refreshToken'];

      if (newAccessToken == null) return false;

      await SecureStorageService.instance.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await SecureStorageService.instance.saveRefreshToken(newRefreshToken);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await SecureStorageService.instance.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
