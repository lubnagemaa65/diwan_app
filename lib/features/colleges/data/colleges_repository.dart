import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/college_model.dart';

class CollegesRepository {
  /// مهم: مرّر الـ Dio المضبوط (baseUrl + توكن) وليس Dio() فارغ.
  CollegesRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  // الباك اند يرجع 10 عناصر فقط افتراضياً، فنطلب عدداً أكبر.
  static const int _limit = 1000;

  Future<List<CollegeModel>> fetchColleges() async {
    try {
      final response = await _dio.get(
        ApiConstants.colleges,
        queryParameters: {'limit': _limit},
      );
      final list = _extractList(response.data);
      return list
          .map((e) => CollegeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> createCollege(String name) async {
    try {
      await _dio.post(ApiConstants.colleges, data: {'name': name});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> updateCollege(String id, String name) async {
    try {
      // الباك اند يستخدم PATCH وليس PUT
      await _dio.patch(ApiConstants.collegeById(id), data: {'name': name});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> deleteCollege(String id) async {
    try {
      await _dio.delete(ApiConstants.collegeById(id));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException e) {
    if (e.error is ApiException) {
      return e.error as ApiException;
    }

    final responseData = e.response?.data;
    if (responseData is Map && responseData['message'] != null) {
      return ApiException(
        responseData['message'].toString(),
        statusCode: e.response?.statusCode,
      );
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
        return ApiException(
          e.message ?? 'حدث خطأ غير متوقع',
          statusCode: e.response?.statusCode,
        );
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
