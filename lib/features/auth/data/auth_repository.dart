import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../models/user_model.dart';

/// نتيجة عملية تسجيل الدخول
class LoginResult {
  final UserModel user;
  final String accessToken;
  final String? refreshToken;

  LoginResult(
      {required this.user, required this.accessToken, this.refreshToken});
}

/// طبقة الوصول للبيانات الخاصة بالمصادقة (Login / Forgot Password / Logout)
/// متصلة بالباك اند الحقيقي فقط (تمت إزالة كل البيانات الوهمية).
class AuthRepository {
  /// مهم: مرّر الـ Dio المضبوط (baseUrl) وليس Dio() فارغ.
  AuthRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // الباك اند لا يوفّر endpoint لـ /me، لذلك نحفظ المستخدم محلياً عند الدخول
  // لاستعادة الجلسة، ونحفظ نسخة من refresh token لاستخدامها عند تسجيل الخروج.
  static const FlutterSecureStorage _store = FlutterSecureStorage();
  static const String _userKey = 'session_user_json';
  static const String _refreshKey = 'session_refresh_copy';

  Future<LoginResult> login(
      {required String email, required String password}) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email.trim(), 'password': password},
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      // شكل الرد في الباك اند:
      // { user: {...}, tokens: { access: {token, expires}, refresh: {token, expires} } }
      final tokens = data['tokens'];
      final accessToken = tokens is Map
          ? (tokens['access'] is Map
              ? (tokens['access']['token'] ?? '').toString()
              : '')
          : '';
      final refreshToken = tokens is Map && tokens['refresh'] is Map
          ? (tokens['refresh']['token'] as dynamic)?.toString()
          : null;
      final userJson = data['user'];

      if (accessToken.isEmpty || userJson is! Map) {
        throw ApiException('استجابة غير متوقعة من السيرفر.');
      }

      await SecureStorageService.instance.saveAccessToken(accessToken);
      if (refreshToken != null) {
        await SecureStorageService.instance.saveRefreshToken(refreshToken);
        await _store.write(key: _refreshKey, value: refreshToken);
      }

      final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
      await _store.write(key: _userKey, value: jsonEncode(user.toJson()));

      return LoginResult(
          user: user, accessToken: accessToken, refreshToken: refreshToken);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// ملاحظة: الباك اند يرسل رابط إعادة التعيين عبر البريد (SMTP)، وهو غير
  /// مضبوط حالياً في .env، لذلك سيفشل الطلب بخطأ من السيرفر حتى تضبط SMTP.
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio
          .post(ApiConstants.forgotPassword, data: {'email': email.trim()});
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// لا يوجد /me في الباك اند: نعيد المستخدم المحفوظ محلياً عند تسجيل الدخول.
  /// يجب استدعاؤها فقط إذا كان هناك access token محفوظ (تحقق منه في الـ Provider).
  Future<UserModel?> fetchCurrentUser() async {
    try {
      final raw = await _store.read(key: _userKey);
      if (raw == null) return null;
      return UserModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    // إبطال الـ refresh token في السيرفر (بأفضل جهد، لا نعطّل الخروج إن فشل)
    try {
      final refresh = await _store.read(key: _refreshKey);
      if (refresh != null) {
        // لا يوجد ثابت logoutEndpoint في ApiConstants، لذلك نرسل الطلب إلى
        // المسار المتاح الذي يعرّفه الباك اند عند الحاجة، أو نتجاهل الخطأ.
        const logoutPath = '/logout';
        if (logoutPath.isNotEmpty) {
          await _dio.post(logoutPath, data: {'refreshToken': refresh});
        }
      }
    } catch (_) {}

    await _store.delete(key: _userKey);
    await _store.delete(key: _refreshKey);
    await SecureStorageService.instance.clearSession();
  }

  ApiException _toApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;

    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(),
          statusCode: e.response?.statusCode);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
          'تعذّر الاتصال بالخادم، تحقق من الشبكة وعنوان الخادم',
          statusCode: e.response?.statusCode,
        );
      default:
        return ApiException(e.message ?? 'حدث خطأ غير متوقع',
            statusCode: e.response?.statusCode);
    }
  }
}
