import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../models/user_model.dart';

/// نتيجة عملية تسجيل الدخول
class LoginResult {
  final UserModel user;
  final String accessToken;
  final String? refreshToken;

  LoginResult({required this.user, required this.accessToken, this.refreshToken});
}

/// طبقة الوصول للبيانات الخاصة بالمصادقة (Login / Forgot Password / Logout)
/// كل الاتصال بالباك إند يمرّ من هنا فقط، بحيث تبقى الـ Providers خالية من تفاصيل الشبكة
class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<LoginResult> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          message: response.data is Map
              ? (response.data['message'] ?? 'فشل تسجيل الدخول').toString()
              : 'فشل تسجيل الدخول، تحقق من البيانات المدخلة',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final accessToken = (data['accessToken'] ?? data['token'] ?? '').toString();
      final refreshToken = data['refreshToken']?.toString();
      final userJson = (data['user'] ?? data) as Map<String, dynamic>;

      if (accessToken.isEmpty) {
        throw ApiException(message: 'استجابة غير متوقعة من السيرفر.');
      }

      await SecureStorageService.instance.saveAccessToken(accessToken);
      if (refreshToken != null) {
        await SecureStorageService.instance.saveRefreshToken(refreshToken);
      }

      final user = UserModel.fromJson(userJson);
      return LoginResult(user: user, accessToken: accessToken, refreshToken: refreshToken);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<UserModel?> fetchCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    await SecureStorageService.instance.clearSession();
  }
}
