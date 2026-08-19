/// The three roles supported by the web dashboard.
enum UserRole { admin, technician, employee }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.technician:
        return 'Maintenance Technician';
      case UserRole.employee:
        return 'Employee';
    }
  }

  /// Short label used for badges/chips in the app bar.
  String get shortLabel {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.technician:
        return 'TECH';
      case UserRole.employee:
        return 'EMPLOYEE';
    }
  }
}

/// Represents the authenticated user.
///
/// Mirrors the shape you'll likely get back from `POST /auth/login` on the
/// real API (id, name, email, role, token). [toJson]/[fromJson] are already
/// included so swapping the mock repository for a real HTTP client later
/// is a drop-in change.
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? token; // placeholder for future JWT/session token

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.employee,
      ),
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'token': token,
      };
}
