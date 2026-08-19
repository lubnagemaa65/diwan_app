import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repository/auth_repository.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

/// Holds auth state and exposes it to the widget tree via Provider.
///
/// Screens should only ever talk to this controller — never to
/// [AuthRepository] directly — so swapping mock data for real API calls
/// later never touches UI code.
class AuthController extends ChangeNotifier {
  AuthController({AuthRepositoryBase? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepositoryBase _repository;

  AuthStatus status = AuthStatus.unauthenticated;
  UserModel? currentUser;
  String? errorMessage;

  bool get isLoading => status == AuthStatus.authenticating;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<bool> login(String email, String password) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.login(email: email, password: password);
      currentUser = user;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
