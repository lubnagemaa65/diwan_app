import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/secure_storage_service.dart';

/// خطأ موحّد يُعرض للمستخدم (رسالة جاهزة للعرض في SnackBar أو ErrorStateWidget).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final generation = options.extra
            .putIfAbsent(_generationKey, () => _sessionGeneration) as int;
        if (!_isCurrent(options, generation)) {
          return handler.reject(_staleRequest(options));
        }
        try {
          final token = await _storage.read(key: _accessKey);
          if (!_isCurrent(options, generation)) {
            return handler.reject(_staleRequest(options));
          }
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        } catch (error, stack) {
          handler.reject(DioException(
              requestOptions: options, error: error, stackTrace: stack));
        }
      },
      onResponse: (response, handler) {
        final req = response.requestOptions;
        if (!_isCurrent(req, req.extra[_generationKey] as int?)) {
          return handler.reject(_staleRequest(req));
        }
        handler.next(response);
      },
      onError: (e, handler) async {
        final req = e.requestOptions;
        final generation = req.extra[_generationKey] as int?;
        if (!_isCurrent(req, generation)) {
          return handler.next(_staleRequest(req));
        }
        final isAuthCall = _isAuthCall(req);
        if (e.response?.statusCode == 401 && !isAuthCall) {
          if (req.extra['retried'] == true) {
            _notifyExpired();
          } else {
            try {
              // A late 401 for an old access token can reuse an already
              // refreshed token, rather than consuming the refresh token twice.
              final token = await _storage.read(key: _accessKey);
              if (!_isCurrent(req, generation)) {
                return handler.next(_staleRequest(req));
              }
              final sentToken = req.headers['Authorization'];
              final alreadyRefreshed = token != null &&
                  sentToken != null &&
                  sentToken != 'Bearer $token';
              final ok = alreadyRefreshed ||
                  await _refreshOnce(generation!, sentToken?.toString());
              if (!_isCurrent(req, generation)) {
                return handler.next(_staleRequest(req));
              }
              if (ok) {
                req.extra['retried'] = true;
                // onRequest reads the latest token again for the retry.
                try {
                  return handler.resolve(await dio.fetch(req));
                } on DioException catch (err) {
                  return handler.next(err);
                }
              }
            } on DioException catch (refreshError) {
              if (!_isCurrent(req, generation)) {
                return handler.next(_staleRequest(req));
              }
              // Connectivity and server errors do not prove the session is
              // invalid. Return the refresh error so the UI can report it.
              return handler.next(refreshError);
            } catch (error, stack) {
              if (!_isCurrent(req, generation)) {
                return handler.next(_staleRequest(req));
              }
              return handler.next(DioException(
                  requestOptions: req, error: error, stackTrace: stack));
            }
            if (_isCurrent(req, generation)) _notifyExpired();
          }
        }
        handler.next(e);
      },
    ));
  }

  /// يُستدعى عند فشل تجديد الجلسة، لإعادة المستخدم لشاشة الدخول.
  static void Function()? onSessionExpired;
  static bool _expiredNotified = false;

  static void _notifyExpired() {
    if (_expiredNotified) return;
    _expiredNotified = true;
    final callback = onSessionExpired;
    if (callback != null) {
      callback();
    } else {
      // Even without a UI listener, never leave an expired session usable.
      instance.invalidateSession();
      unawaited(instance._clearExpiredWithoutListener());
    }
  }

  Future<void> _clearExpiredWithoutListener() async {
    try {
      await clearTokens();
    } catch (_) {
      // Still try the separate profile storage below.
    }
    try {
      await SecureStorageService.instance.clearSession();
    } catch (_) {
      // Storage may be unavailable; the in-memory session remains blocked.
    }
  }

  static final ApiClient instance = ApiClient._();

  // API_BASE_URL takes precedence; API_URL remains supported for older builds.
  // With neither define, keep the project's existing default unchanged.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://192.168.1.66:3000/v1',
    ),
  );
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'current_user_json';
  static const _generationKey = 'session_generation';

  // Retain the original storage options so existing ApiClient sessions can
  // still be restored. Profile storage uses its own configured options.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio dio;
  Future<bool>? _refreshing;
  int? _refreshGeneration;
  int _sessionGeneration = 0;
  bool _sessionBlocked = false;
  Future<void>? _storageWrites;

  bool _isAuthCall(RequestOptions req) =>
      Uri.parse(req.path).path.startsWith('/auth/');

  bool _isCurrent(RequestOptions req, int? generation) =>
      generation == _sessionGeneration &&
      (!_sessionBlocked || _isAuthCall(req));

  DioException _staleRequest(RequestOptions req) => DioException(
        requestOptions: req,
        type: DioExceptionType.cancel,
        error: 'Session changed',
      );

  /// Invalidate pending results immediately, before asynchronous cleanup.
  void invalidateSession() {
    _sessionGeneration++;
    _sessionBlocked = true;
    _refreshing = null;
    _refreshGeneration = null;
  }

  /// Called only after a complete login or successful restoration.
  void activateSession() {
    _sessionBlocked = false;
    _expiredNotified = false;
  }

  Future<T> _serializeStorage<T>(Future<T> Function() operation) {
    final previous = _storageWrites;
    final result = previous == null
        ? Future<T>.sync(operation)
        : previous.then((_) => operation());
    late final Future<void> finished;
    finished = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _storageWrites = finished;
    unawaited(finished.whenComplete(() {
      if (identical(_storageWrites, finished)) _storageWrites = null;
    }));
    return result;
  }

  // ---------------- التوكنات والجلسة ----------------

  /// [tokens] هو الكائن الراجع من الباك اند: {access: {token, expires}, refresh: {token, expires}}
  Future<void> saveTokens(Map<String, dynamic> tokens,
          {int? expectedGeneration}) =>
      _serializeStorage(() async {
        if (expectedGeneration != null &&
            expectedGeneration != _sessionGeneration) {
          return;
        }
        final access = tokens['access']?['token'];
        final refresh = tokens['refresh']?['token'];
        if (access != null) {
          await _storage.write(key: _accessKey, value: access.toString());
        }
        if (refresh != null) {
          await _storage.write(key: _refreshKey, value: refresh.toString());
        }
      });

  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<bool> hasToken() async =>
      (await _storage.read(key: _accessKey)) != null;

  Future<void> saveUserJson(String json) =>
      _storage.write(key: _userKey, value: json);

  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> clearTokens() => _serializeStorage(() async {
        Object? firstError;
        StackTrace? firstStack;
        for (final key in [_accessKey, _refreshKey, _userKey]) {
          try {
            await _storage.delete(key: key);
          } catch (error, stack) {
            firstError ??= error;
            firstStack ??= stack;
          }
        }
        if (firstError != null) {
          Error.throwWithStackTrace(firstError, firstStack!);
        }
      });

  Future<bool> _refreshOnce(int generation, String? sentToken) {
    if (_refreshing != null && _refreshGeneration == generation) {
      return _refreshing!;
    }
    _refreshGeneration = generation;
    late final Future<bool> future;
    future = _refresh(generation, sentToken).whenComplete(() {
      if (identical(_refreshing, future)) {
        _refreshing = null;
        _refreshGeneration = null;
      }
    });
    _refreshing = future;
    return future;
  }

  Future<bool> _refresh(int generation, String? sentToken) async {
    try {
      final currentAccess = await _storage.read(key: _accessKey);
      if (generation != _sessionGeneration || _sessionBlocked) return false;
      if (currentAccess != null &&
          sentToken != null &&
          sentToken != 'Bearer $currentAccess') {
        return true;
      }
      final refresh = await _storage.read(key: _refreshKey);
      if (refresh == null || generation != _sessionGeneration) return false;
      // Dio منفصل لتجنّب الدخول في حلقة مع الـ interceptor.
      final res = await Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      )).post('/auth/refresh-tokens', data: {'refreshToken': refresh});
      if (generation != _sessionGeneration || _sessionBlocked) return false;
      final tokens = Map<String, dynamic>.from(res.data as Map);
      final access = tokens['access'];
      final nextRefresh = tokens['refresh'];
      if (access is! Map ||
          nextRefresh is! Map ||
          (access['token']?.toString().isEmpty ?? true) ||
          (nextRefresh['token']?.toString().isEmpty ?? true)) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
          error: 'Invalid token refresh response',
        );
      }
      await saveTokens(tokens, expectedGeneration: generation);
      return generation == _sessionGeneration && !_sessionBlocked;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) return false;
      rethrow;
    }
  }

  // ---------------- معالجة الأخطاء ----------------

  /// يلفّ أي طلب ويحوّل أخطاء Dio إلى [ApiException] برسالة مفهومة.
  static Future<T> guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  static ApiException _toException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(), statusCode: status);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
            'تعذّر الاتصال بالخادم، تحقق من الشبكة وعنوان الخادم',
            statusCode: status);
      default:
        return ApiException('حدث خطأ غير متوقع', statusCode: status);
    }
  }
}
