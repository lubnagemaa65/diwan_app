import 'package:dio/dio.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/features/auth/models/user_model.dart';

/// استثناء المصادقة (محتفظ به بنفس الاسم القديم لعدم كسر الشاشات التي
/// تلتقطه عبر `on AuthException catch (e)`).
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      // شكل رد الباك اند: { user: {...}, tokens: { access: {token}, refresh: {token} } }
      final tokens = data['tokens'];
      final accessToken =
          tokens is Map ? (tokens['access']?['token'] ?? '').toString() : '';
      final userJson = data['user'];

      if (accessToken.isEmpty || userJson is! Map) {
        throw AuthException('استجابة غير متوقعة من السيرفر.');
      }

      await ApiClient.instance.saveTokens(Map<String, dynamic>.from(tokens));

      final role = _roleFromApi(userJson['role']?.toString());

      final user = AppUser(
        name: (userJson['name'] ?? userJson['email'] ?? '—').toString(),
        email: (userJson['email'] ?? '').toString(),
        role: role,
        token: accessToken,
      );

      return user;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw AuthException(
              'تعذّر الاتصال بالخادم، تحقق من الشبكة وعنوان الخادم');
        default:
          throw AuthException('البريد الإلكتروني أو كلمة المرور غير صحيحة');
      }
    }
  }

  /// ملاحظة: الباك اند يرسل رابط إعادة التعيين عبر البريد (SMTP)، وهو غير
  /// مضبوط حالياً في .env، لذلك سيفشل الطلب بخطأ من السيرفر حتى تُضبط SMTP.
  Future<void> forgotPassword({required String email}) async {
    try {
      await ApiClient.instance.dio
          .post('/auth/forgot-password', data: {'email': email.trim()});
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('تعذّر إرسال رابط إعادة التعيين، حاول لاحقاً');
    }
  }

  Future<void> logout() async {
    try {
      final rt = await ApiClient.instance.refreshToken;
      if (rt != null) {
        await ApiClient.instance.dio
            .post('/auth/logout', data: {'refreshToken': rt});
      }
    } catch (_) {
      // نتجاهل أخطاء الشبكة عند تسجيل الخروج
    }
    await ApiClient.instance.clearTokens();
  }

  UserRole _roleFromApi(String? v) {
    switch (v?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'TECHNICIAN':
        return UserRole.technician;
      case 'EMPLOYEE':
        return UserRole.employee;
      default:
        throw AuthException('دور المستخدم غير معروف');
    }
  }
}
