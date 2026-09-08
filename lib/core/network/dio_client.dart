import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// يبني ويُهيّئ نسخة [Dio] واحدة تُستخدم في كل التطبيق (Singleton)
/// يضيف: BaseOptions + AuthInterceptor + ErrorInterceptor + Logger
class DioClient {
  DioClient._internal();
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio = _createDio();

  /// دالة تُستدعى عند انتهاء الجلسة (مثلاً لتوجيه المستخدم لشاشة تسجيل الدخول)
  Future<void> Function()? onSessionExpired;

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        dio: dio,
        onSessionExpired: () async => onSessionExpired?.call(),
      ),
      ErrorInterceptor(),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
      ),
    ]);

    return dio;
  }
}
