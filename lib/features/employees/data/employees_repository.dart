import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/employee_model.dart';

class EmployeesRepository {
  /// مهم: مرّر الـ Dio المضبوط (baseUrl + توكن) وليس Dio() فارغ.
  EmployeesRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  // الباك اند يرجع 10 عناصر فقط افتراضياً، فنطلب عدداً أكبر.
  static const int _limit = 1000;

  Future<List<EmployeeModel>> fetchEmployees({String? collegeId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.employees,
        queryParameters: {
          'limit': _limit,
          if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
        },
      );
      final list = _extractList(response.data);
      return list
          .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// [userId] و[collegeId] مطلوبان في الباك اند (أرقام)، والمستخدم لازم
  /// يكون موجوداً وغير مرتبط بموظف آخر.
  Future<void> createEmployee({
    required String firstName,
    required String fatherName,
    required String familyName,
    String? userId,
    String? collegeId,
  }) async {
    final uid = int.tryParse(userId ?? '');
    final cid = int.tryParse(collegeId ?? '');
    if (uid == null) {
      throw ApiException('يجب اختيار مستخدم لربطه بالموظف.');
    }
    if (cid == null) {
      throw ApiException('يجب اختيار الكلية.');
    }
    try {
      await _dio.post(ApiConstants.employees, data: {
        'firstName': firstName.trim(),
        'fatherName': fatherName.trim(),
        // familyName في التطبيق = lastName في الباك اند
        'lastName': familyName.trim(),
        'userId': uid,
        'collegeId': cid,
      });
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// الباك اند لا يسمح بتغيير userId عند التعديل.
  Future<void> updateEmployee(
    String id, {
    required String firstName,
    required String fatherName,
    required String familyName,
    String? collegeId,
  }) async {
    try {
      await _dio.patch(ApiConstants.employeeById(id), data: {
        'firstName': firstName.trim(),
        'fatherName': fatherName.trim(),
        'lastName': familyName.trim(),
        if (int.tryParse(collegeId ?? '') != null)
          'collegeId': int.parse(collegeId!),
      });
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      await _dio.delete(ApiConstants.employeeById(id));
    } on DioException catch (e) {
      throw _toApiException(e);
    }
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

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return [];
  }
}
