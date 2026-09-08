import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:university_assets_app/core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../models/user_model.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// المزوّد الرئيسي لحالة تسجيل الدخول ودور المستخدم الحالي (Role-Based Access)
/// يُستخدم في كل التطبيق لمعرفة: هل المستخدم مسجّل؟ ما دوره؟ ما بياناته؟
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository}) : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  UserRole get role => _currentUser?.role ?? UserRole.unknown;
  bool get isAdmin => role == UserRole.admin;
  bool get isTechnician => role == UserRole.technician;
  bool get isEmployee => role == UserRole.employee;

  /// يُستدعى عند إقلاع التطبيق للتحقق من وجود جلسة محفوظة
  Future<void> restoreSession() async {
    final token = await SecureStorageService.instance.getAccessToken();
    final userJsonStr = await SecureStorageService.instance.getUserProfile();

    if (token == null || token.isEmpty || userJsonStr == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _currentUser = UserModel.fromJson(jsonDecode(userJsonStr) as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await _repository.login(email: email, password: password);
      _currentUser = result.user;
      _status = AuthStatus.authenticated;
      await SecureStorageService.instance.saveUserProfile(jsonEncode(result.user.toJson()));
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
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
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى.';
      _setLoading(false);
      return false;
    }
  }

  /// يُستدعى تلقائيًا من DioClient عند انتهاء صلاحية الجلسة (401 + فشل تجديد التوكن)
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
