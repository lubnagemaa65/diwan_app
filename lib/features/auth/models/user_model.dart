enum UserRole { admin, technician, employee }

extension UserRoleX on UserRole {
  /// Matches the exact pill labels seen in the Users screenshot.
  String get arabicLabel {
    switch (this) {
      case UserRole.admin:
        return 'مدير';
      case UserRole.technician:
        return 'فني';
      case UserRole.employee:
        return 'موظف';
    }
  }
}

class AppUser {
  final String name;
  final String email;
  final UserRole role;
  final String? token;

  const AppUser({required this.name, required this.email, required this.role, this.token});
}
