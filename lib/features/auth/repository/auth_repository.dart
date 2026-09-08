import 'package:university_assets_app/features/auth/models/user_model.dart';

import '../../../core/mock/mock_data.dart';
import '../../../models/user_model.dart';

/// Exception used by the mock authentication repository.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

/// Mock authentication repository.
///
/// This repository does NOT use Dio or any real API.
///
/// Test accounts:
///
/// Admin:
///   admintest@local.com
///   123456
///
/// Technician:
///   technicanusertest@local.com
///   123456
///
/// Employee:
///   emptest@local.com
///   123456
class AuthRepository {
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    // Simulate a small network delay.
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    final normalizedEmail = email.trim().toLowerCase();

    // -----------------------------------------------------------------------
    // Password validation
    // -----------------------------------------------------------------------

    if (password != '123456') {
      throw AuthException(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      );
    }

    // -----------------------------------------------------------------------
    // Find user in mock data
    // -----------------------------------------------------------------------

    final matchingUsers = mockUsers.where(
      (user) => user.email.trim().toLowerCase() == normalizedEmail,
    );

    if (matchingUsers.isEmpty) {
      throw AuthException(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      );
    }

    final user = matchingUsers.first;

    // -----------------------------------------------------------------------
    // Convert Arabic role to UserRole
    // -----------------------------------------------------------------------

    final UserRole role;

    switch (user.role) {
      case 'مدير':
        role = UserRole.admin;
        break;

      case 'فني':
        role = UserRole.technician;
        break;

      case 'موظف':
        role = UserRole.employee;
        break;

      default:
        throw AuthException(
          'دور المستخدم غير معروف',
        );
    }

    // -----------------------------------------------------------------------
    // Return AppUser
    // -----------------------------------------------------------------------

    return AppUser(
      name: user.name,
      email: user.email,
      role: role,
      token: 'mock-token',
    );
  }
}
