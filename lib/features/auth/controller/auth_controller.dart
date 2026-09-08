import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repository/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  AppUser? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _repository.login(email: email, password: password);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('AuthException: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}
