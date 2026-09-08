import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/user_model.dart';
import '../data/users_repository.dart';

enum LoadStatus { initial, loading, loaded, error }

class UsersProvider extends ChangeNotifier {
  UsersProvider({UsersRepository? repository}) : _repository = repository ?? UsersRepository();
  final UsersRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<UserModel> _users = [];
  String _errorMessage = '';

  LoadStatus get status => _status;
  List<UserModel> get users => _users;
  String get errorMessage => _errorMessage;

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
