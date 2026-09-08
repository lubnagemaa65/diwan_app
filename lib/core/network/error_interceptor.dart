import 'package:dio/dio.dart';
import 'api_exception.dart';

/// يحوّل أي [DioException] إلى [ApiException] موحّد قبل أن يصل لطبقة الـ Repository
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = ApiException.fromDioError(err);
    final newError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiException,
      message: apiException.message,
    );
    handler.next(newError);
  }
}
