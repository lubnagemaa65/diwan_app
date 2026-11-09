import '../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      // الاسم اختياري في الباك اند (name?)
      name: (json['name'] ?? json['fullName'] ?? '—').toString(),
      email: (json['email'] ?? '').toString(),
      role: ApiMappers.roleFromApi(json['role']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// للتخزين المحلي فقط (الجلسة). أما الإنشاء والتعديل فتبنيهما UserService.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': ApiMappers.roleToApi(role),
      };

  UserModel copyWith({String? name, String? email, UserRole? role}) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
