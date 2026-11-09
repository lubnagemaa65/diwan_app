import 'dart:convert';

import 'package:dio/dio.dart';
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
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

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
  Future<void> restoreSession() async {
    final hasToken = await ApiClient.instance.hasToken();
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final profileJson = await SecureStorageService.instance.getUserProfile();
    if (profileJson == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final map = jsonDecode(profileJson) as Map<String, dynamic>;
      _currentUser = AppUser(
        name: (map['name'] ?? '').toString(),
        email: (map['email'] ?? '').toString(),
        role: UserRole.values.byName((map['role'] ?? 'employee').toString()),
        token: (map['token'] ?? '').toString(),
      );
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
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

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _repository.login(email: email, password: password);
      final appUser = _normalizeUser(user);
      _currentUser = appUser;
      _status = AuthStatus.authenticated;
      await SecureStorageService.instance.saveUserProfile(jsonEncode({
        'name': appUser.name,
        'email': appUser.email,
        'role': appUser.role.name,
        'token': appUser.token,
      }));
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.forgotPassword(email: email);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى.';
      _setLoading(false);
      return false;
    }
  }

  /// يُستدعى تلقائياً عند انتهاء صلاحية الجلسة (401 + فشل تجديد التوكن).
  Future<void> handleSessionExpired() async {
    await _repository.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
