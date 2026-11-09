import 'package:university_assets_app/core/constants/app_constants.dart';

class EmployeeModel {
  final String id;
  final String firstName;
  final String fatherName;

  /// يقابل الحقل lastName في الباك اند.
  final String familyName;
  final String? userId;
  final String? collegeId;
  final String? collegeName;

  EmployeeModel({
    required this.id,
    required this.firstName,
    required this.fatherName,
    required this.familyName,
    this.userId,
    this.collegeId,
    this.collegeName,
  });

  String get fullName => '$firstName $fatherName $familyName'.trim();

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final college = json['college'];
    final user = json['user'];
    return EmployeeModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      fatherName: (json['fatherName'] ?? '').toString(),
      familyName: (json['lastName'] ?? json['familyName'] ?? '').toString(),
      userId: json['userId']?.toString() ??
          (user is Map ? user['id']?.toString() : null),
      collegeId: json['collegeId']?.toString() ??
          (college is Map ? college['id']?.toString() : null),
      collegeName: college is Map
          ? college['name']?.toString()
          : json['collegeName']?.toString(),
    );
  }

  /// جسم طلب الإنشاء POST /employees
  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'fatherName': fatherName,
        'lastName': familyName,
        'userId': ApiMappers.toInt(userId),
        'collegeId': ApiMappers.toInt(collegeId),
      };

  /// جسم طلب التعديل PATCH /employees/:id (الباك اند لا يسمح بتغيير userId)
  Map<String, dynamic> toUpdateJson() => {
        'firstName': firstName,
        'fatherName': fatherName,
        'lastName': familyName,
        'collegeId': ApiMappers.toInt(collegeId),
      };
}
