import 'package:dio/dio.dart';

/// نوع موحّد لكل الأخطاء القادمة من الـ API
/// بحيث تتعامل الـ Providers/Views مع رسالة واضحة دائمًا (عربي)
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'انتهت مهلة الاتصال بالسيرفر، تحقق من الشبكة وحاول مجددًا.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'تعذّر الاتصال بالسيرفر. تأكد من اتصالك بالإنترنت.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.badCertificate:
        return ApiException(message: 'شهادة الأمان غير موثوقة.');
      case DioExceptionType.cancel:
        return ApiException(message: 'تم إلغاء الطلب.');
      case DioExceptionType.badResponse:
        return _fromResponse(error);
      case DioExceptionType.unknown:
        return ApiException(
          message: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static ApiException _fromResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'حدث خطأ أثناء تنفيذ العملية.';

    if (data is Map) {
      message = (data['message'] ?? data['error'] ?? data['msg'] ?? message)
          .toString();
    }

    switch (statusCode) {
      case 400:
        message = data is Map ? message : 'طلب غير صالح.';
        break;
      case 401:
        message = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجددًا.';
        break;
      case 403:
        message = 'ليست لديك صلاحية للقيام بهذا الإجراء.';
        break;
      case 404:
        message = 'العنصر المطلوب غير موجود.';
        break;
      case 409:
        message = data is Map ? message : 'تعارض في البيانات.';
        break;
      case 422:
        message = data is Map ? message : 'بيانات غير صحيحة، تحقق من الحقول.';
        break;
      case 500:
      case 502:
      case 503:
        message = 'خطأ في السيرفر، حاول لاحقًا.';
        break;
    }

    return ApiException(message: message, statusCode: statusCode, data: data);
  }

  @override
  String toString() => message;
}
