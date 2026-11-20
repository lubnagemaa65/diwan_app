import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/features/auth/models/user_model.dart';
import 'package:university_assets_app/features/auth/repository/auth_repository.dart';
import '../../../core/storage/secure_storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// المزوّد الرئيسي لحالة تسجيل الدخول ودور المستخدم الحالي (Role-Based Access).
///
/// ملاحظة: تم تصحيح هذا الملف ليطابق AuthRepository الحقيقي الموجود في
/// المشروع (يرجع AppUser بدون الحاجة لتمرير Dio)، بدل النسخة الافتراضية
/// (LoginResult/UserModel) التي كانت مفترضة خطأً. التوكن الفعلي (JWT)
/// يُحفظ ويُدار داخلياً عبر ApiClient، وهنا نحفظ فقط بيانات العرض
/// (الاسم والبريد والدور) لاستعادة الجلسة بعد إعادة فتح التطبيق.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository, this.navigationManaged = false})
      : _repository = repository ?? AuthRepository() {
    ApiClient.onSessionExpired = _onSessionExpired;
  }
  final AuthRepository _repository;
  final bool navigationManaged;
  Future<void>? _operations;
  int _generation = 0;
  bool _disposed = false;

  // Session mutations must finish in order: in particular, a late login must
  // not write tokens after the subsequent logout has completed.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final previous = _operations;
    final result = previous == null
        ? Future<T>.sync(operation)
        : previous.then((_) => operation());
    late final Future<void> finished;
    finished = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _operations = finished;
    unawaited(finished.whenComplete(() {
      if (identical(_operations, finished)) _operations = null;
    }));
    return result;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onSessionExpired() {
    unawaited(handleSessionExpired());
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    if (ApiClient.onSessionExpired == _onSessionExpired) {
      ApiClient.onSessionExpired = null;
    }
    super.dispose();
  }

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  UserRole? get role => _currentUser?.role;
  bool get isAdmin => role == UserRole.admin;
  bool get isTechnician => role == UserRole.technician;
  bool get isEmployee => role == UserRole.employee;

  /// AppUser لا يحمل معرّفاً رقمياً (id) — المعرّف موجود داخل التوكن (JWT)
  /// كـ claim باسم "sub". نفكّه هنا محلياً دون أي مكتبة خارجية، لاستخدامه
  /// مثلاً عند تعيين الفني الحالي لطلب صيانة (technicianId).
  int? get currentUserId {
    final token = _currentUser?.token;
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4); // إكمال padding
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final sub = map['sub'];
      if (sub is int) return sub;
      if (sub is String) return int.tryParse(sub);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// يُستدعى عند إقلاع التطبيق للتحقق من وجود جلسة محفوظة.
  /// التحقق الفعلي من صلاحية التوكن يتم عبر ApiClient (مصدر الحقيقة
  /// للتوكن)، وبيانات العرض تُستعاد من SecureStorageService.
  Future<void> restoreSession() {
    final generation = _generation;
    return _enqueue(() async {
      if (!_isCurrent(generation)) return;
      try {
        final hasToken = await ApiClient.instance.hasToken();
        final profileJson =
            await SecureStorageService.instance.getUserProfile();
        if (!_isCurrent(generation)) return;
        if (!hasToken || profileJson == null) {
          await _clearLocalSession();
          if (!_isCurrent(generation)) return;
          ApiClient.instance.invalidateSession();
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
          _notify();
          return;
        }
        final map = jsonDecode(profileJson) as Map<String, dynamic>;
        final user = AppUser(
          name: (map['name'] ?? '').toString(),
          email: (map['email'] ?? '').toString(),
          role: UserRole.values.byName((map['role'] ?? 'employee').toString()),
          token: (map['token'] ?? '').toString(),
        );
        if (!_isCurrent(generation)) return;
        _currentUser = user;
        ApiClient.instance.activateSession();
        _status = AuthStatus.authenticated;
      } catch (_) {
        if (!_isCurrent(generation)) return;
        ApiClient.instance.invalidateSession();
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        // A corrupt profile or storage error must never restore a partial
        // session. Attempt all deletes even if one of them fails.
        try {
          await _clearLocalSession();
        } catch (_) {
          _errorMessage = 'تعذّر مسح بيانات الجلسة من الجهاز.';
        }
        if (!_isCurrent(generation)) return;
      }
      _notify();
    });
  }

  AppUser _normalizeUser(dynamic value) {
    if (value is AppUser) return value;

    final dynamicMap = value is Map<String, dynamic>
        ? value
        : value is Map
            ? Map<String, dynamic>.from(value)
            : null;

    Object? userObj;
    if (dynamicMap != null) {
      userObj = dynamicMap['user'] ??
          dynamicMap['data'] ??
          dynamicMap['profile'] ??
          value;
    } else {
      userObj = value;
    }

    final source = userObj is Map<String, dynamic>
        ? userObj
        : userObj is Map
            ? Map<String, dynamic>.from(userObj)
            : userObj;

    if (source is Map<String, dynamic>) {
      final rawRole = source['role'] ?? source['userRole'];
      final role = rawRole is UserRole
          ? rawRole
          : UserRole.values.firstWhere(
              (item) => item.name == rawRole.toString(),
              orElse: () => UserRole.employee,
            );

      return AppUser(
        name: (source['name'] ?? source['fullName'] ?? '').toString(),
        email: (source['email'] ?? '').toString(),
        role: role,
        token: (source['token'] ?? source['accessToken'] ?? '').toString(),
      );
    }

    final dynamicUser = value as dynamic;
    final rawRole = dynamicUser.role ?? dynamicUser.userRole;
    final role = rawRole is UserRole
        ? rawRole
        : rawRole == null
            ? UserRole.employee
            : UserRole.values.firstWhere(
                (item) => item.name == rawRole.toString(),
                orElse: () => UserRole.employee,
              );

    return AppUser(
      name: (dynamicUser.name ?? dynamicUser.fullName ?? '').toString(),
      email: (dynamicUser.email ?? '').toString(),
      role: role,
      token: (dynamicUser.token ?? dynamicUser.accessToken ?? '').toString(),
    );
  }

  Future<bool> login({required String email, required String password}) {
    final generation = ++_generation;
    ApiClient.instance.invalidateSession();
    _currentUser = null;
    if (_status == AuthStatus.authenticated) {
      _status = AuthStatus.unauthenticated;
    }
    _errorMessage = null;
    _setLoading(true);
    return _enqueue(() async {
      if (!_isCurrent(generation)) return false;
      try {
        // Never combine a new user's profile with old or partial tokens.
        await _clearLocalSession();
        if (!_isCurrent(generation)) return false;
        final user = await _repository.login(email: email, password: password);
        if (!_isCurrent(generation)) return false;
        final appUser = _normalizeUser(user);
        await SecureStorageService.instance.saveUserProfile(jsonEncode({
          'name': appUser.name,
          'email': appUser.email,
          'role': appUser.role.name,
          'token': appUser.token,
        }));
        if (!_isCurrent(generation)) return false;
        _currentUser = appUser;
        ApiClient.instance.activateSession();
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } on AuthException catch (e) {
        if (!_isCurrent(generation)) return false;
        _errorMessage = e.message;
      } catch (_) {
        if (!_isCurrent(generation)) return false;
        _errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى.';
      }
      // Login can fail after its repository has already persisted tokens.
      try {
        await _clearLocalSession();
      } catch (_) {
        if (_isCurrent(generation)) {
          _errorMessage = 'تعذّر مسح بيانات الجلسة من الجهاز.';
        }
      }
      if (_isCurrent(generation)) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _setLoading(false);
      }
      return false;
    });
  }

  Future<bool> forgotPassword({required String email}) {
    final generation = _generation;
    _setLoading(true);
    _errorMessage = null;
    return _enqueue(() async {
      if (!_isCurrent(generation)) return false;
      try {
        await _repository.forgotPassword(email: email);
        if (!_isCurrent(generation)) return false;
        _setLoading(false);
        return true;
      } on AuthException catch (e) {
        if (!_isCurrent(generation)) return false;
        _errorMessage = e.message;
      } catch (_) {
        if (!_isCurrent(generation)) return false;
        _errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى.';
      }
      _setLoading(false);
      return false;
    });
  }

  /// يُستدعى تلقائياً عند انتهاء صلاحية الجلسة (401 + فشل تجديد التوكن).
  Future<void> handleSessionExpired() => _endSession();

  Future<void> logout() => _endSession();

  Future<void> _endSession() {
    final generation = ++_generation;
    // Do this synchronously, before network/storage awaits or navigation.
    ApiClient.instance.invalidateSession();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _isLoading = false;
    _notify();
    return _enqueue(() async {
      // Remove the restorable profile before trying server-side revocation.
      try {
        await SecureStorageService.instance.clearUserProfile();
      } catch (_) {
        // Retry as part of the full cleanup below.
      }
      try {
        await _repository.logout();
      } catch (_) {
        // Local cleanup must still run if logout or secure storage fails.
      }
      try {
        await _clearLocalSession();
      } catch (_) {
        if (_isCurrent(generation)) {
          _errorMessage = 'تعذّر مسح بيانات الجلسة من الجهاز.';
          _notify();
        }
      }
    });
  }

  Future<void> _clearLocalSession() async {
    Object? firstError;
    StackTrace? firstStack;
    try {
      await ApiClient.instance.clearTokens();
    } catch (error, stack) {
      firstError = error;
      firstStack = stack;
    }
    try {
      await SecureStorageService.instance.clearSession();
    } catch (error, stack) {
      firstError ??= error;
      firstStack ??= stack;
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack!);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notify();
  }
}
