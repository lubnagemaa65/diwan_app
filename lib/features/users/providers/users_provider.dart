import 'package:flutter/material.dart';
import 'package:university_assets_app/core/constants/load_status.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/user_model.dart';
import '../data/users_repository.dart';
export '../../../core/constants/load_status.dart';

class UsersProvider extends ChangeNotifier {
  // UsersRepository يحتاج Dio مُهيأً (baseUrl + توكن). إذا كان التطبيق
  // يوفر Dio عبر حقن أو Singleton آخر، مرره عبر المعامل `repository` بدل
  // الاعتماد على إنشاء جديد هنا.
  UsersProvider({UsersRepository? repository})
      : _repository =
            repository ?? UsersRepository(dio: ApiClient.instance.dio);
  final UsersRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<UserModel> _users = [];
  String _errorMessage = '';
  bool _isSubmitting = false;

  LoadStatus get status => _status;
  List<UserModel> get users => _users;
  String get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;

  Future<void> loadUsers() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _users = await _repository.fetchUsers();
      _status = LoadStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    } catch (_) {
      _errorMessage = 'تعذّر تحميل المستخدمين.';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// الباك اند يتطلب كلمة مرور عند إنشاء مستخدم (8 أحرف على الأقل، تحتوي
  /// رقماً وحرفاً)، لذلك أصبح [password] مطلوباً هنا. أضف حقل كلمة المرور
  /// في فورم "إضافة مستخدم" إذا لم يكن موجوداً.
  Future<bool> addUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      await loadUsers();
      _isSubmitting = false;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// ملاحظة: الباك اند لا يسمح بتعديل الدور بعد الإنشاء، لذلك حُذف باراميتر
  /// [role] من هذه الدالة. أخفِ حقل تعديل الدور في شاشة تعديل المستخدم،
  /// أو اعرضه للقراءة فقط. مرّر [password] فقط إذا أراد المستخدم تغييرها.
  Future<bool> updateUser(String id,
      {String? name, String? email, String? password}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.updateUser(id,
          name: name, email: email, password: password);
      await loadUsers();
      _isSubmitting = false;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _repository.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
