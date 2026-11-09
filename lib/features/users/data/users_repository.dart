import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/user_model.dart';

class UsersRepository {
  /// مهم: مرّر الـ Dio المضبوط (baseUrl + توكن) وليس Dio() فارغ.
  UsersRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  // الباك اند يرجع 10 عناصر فقط افتراضياً، فنطلب عدداً أكبر.
  static const int _limit = 1000;

  Future<List<UserModel>> fetchUsers() async {
    try {
      final response = await _dio
          .get(ApiConstants.users, queryParameters: {'limit': _limit});
      final list = _extractList(response.data);
      return list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// الباك اند يتطلب كلمة مرور عند إنشاء مستخدم (8 أحرف على الأقل،
  /// تحتوي رقماً وحرفاً واحداً على الأقل).
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      await _dio.post(ApiConstants.users, data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': ApiMappers.roleToApi(role),
      });
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// الباك اند يسمح بتعديل name / email / password فقط (وليس الدور).
  /// أعطِ [password] فقط إذا أراد المستخدم تغييرها.
  Future<void> updateUser(
    String id, {
    String? name,
    String? email,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
    if (password != null && password.isNotEmpty) body['password'] = password;

    if (body.isEmpty) return;

    try {
      // الباك اند يستخدم PATCH وليس PUT
      await _dio.patch(ApiConstants.userById(id), data: body);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete(ApiConstants.userById(id));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    if (e.error is ApiException) {
      return e.error as ApiException;
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        message = 'تعذّر الاتصال بالخادم، تحقق من الشبكة وعنوان الخادم';
        break;
      default:
        message = e.message ?? 'حدث خطأ غير متوقع.';
    }

    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is String && msg.isNotEmpty) message = msg;
    }

    return ApiException(message, statusCode: statusCode);
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return [];
  }
}
