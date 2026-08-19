import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Thrown when login credentials don't match any known account.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Abstract contract so the UI/controller never depends on whether data
/// comes from mock storage or a real network call.
abstract class AuthRepositoryBase {
  Future<UserModel> login({required String email, required String password});
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

/// Mock implementation — validates against a small hardcoded credential
/// table. This is what the app uses TODAY.
///
/// To go live: create `AuthRepositoryHttp implements AuthRepositoryBase`
/// (or `dio`-based equivalent) using the same method signatures below,
/// then swap the instance created in `main.dart` / your DI setup.
/// No screen or controller code needs to change.
class AuthRepository implements AuthRepositoryBase {
  // In-memory "session" for the mock implementation.
  UserModel? _cachedUser;

  /// Hardcoded credential table mirroring the web app's test accounts.
  static final List<_MockAccount> _accounts = [
    _MockAccount(
      id: 'usr_001',
      name: 'System Admin',
      email: 'admintest@local.com',
      password: 'admintest123',
      role: UserRole.admin,
    ),
    _MockAccount(
      id: 'usr_002',
      name: 'Maintenance Tech',
      email: 'technicanusertest@local.com',
      password: 'tech1234',
      role: UserRole.technician,
    ),
    _MockAccount(
      id: 'usr_003',
      name: 'Staff Employee',
      email: 'emptest@local',
      password: 'emptest123',
      role: UserRole.employee,
    ),
  ];

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // ---------------------------------------------------------------
    // MOCK LOGIC (current behavior)
    // ---------------------------------------------------------------
    await Future.delayed(AppConstants.mockNetworkDelay);

    final match = _accounts.where(
      (a) =>
          a.email.toLowerCase() == email.trim().toLowerCase() &&
          a.password == password,
    );

    if (match.isEmpty) {
      throw AuthException('Invalid email or password.');
    }

    final account = match.first;
    final user = UserModel(
      id: account.id,
      name: account.name,
      email: account.email,
      role: account.role,
      token: 'mock-token-${account.id}',
    );
    _cachedUser = user;
    return user;

    // ---------------------------------------------------------------
    // FUTURE REAL API CALL — replace the block above with something like:
    // ---------------------------------------------------------------
    // final response = await http.post(
    //   Uri.parse(AppConstants.loginEndpoint),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'email': email, 'password': password}),
    // );
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   final user = UserModel.fromJson(data['user']);
    //   // TODO: persist data['token'] securely (flutter_secure_storage)
    //   return user;
    // } else {
    //   throw AuthException(jsonDecode(response.body)['message'] ??
    //       'Login failed');
    // }
  }

  @override
  Future<void> logout() async {
    // MOCK LOGIC
    await Future.delayed(const Duration(milliseconds: 300));
    _cachedUser = null;

    // FUTURE REAL API CALL:
    // await http.post(
    //   Uri.parse(AppConstants.logoutEndpoint),
    //   headers: {'Authorization': 'Bearer $token'},
    // );
    // TODO: also clear the persisted token from secure storage.
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // MOCK LOGIC — returns whatever is cached from the last login.
    return _cachedUser;

    // FUTURE REAL API CALL (e.g. to restore session on app start):
    // final token = await secureStorage.read(key: 'auth_token');
    // if (token == null) return null;
    // final response = await http.get(
    //   Uri.parse(AppConstants.currentUserEndpoint),
    //   headers: {'Authorization': 'Bearer $token'},
    // );
    // if (response.statusCode == 200) {
    //   return UserModel.fromJson(jsonDecode(response.body));
    // }
    // return null;
  }
}

class _MockAccount {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;

  const _MockAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}
