class EmployeeModel {
  final String id;
  final String firstName;
  final String fatherName;
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
    return EmployeeModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
      fatherName: (json['fatherName'] ?? json['father_name'] ?? '').toString(),
      familyName: (json['familyName'] ?? json['family_name'] ?? '').toString(),
      userId: json['userId']?.toString() ?? json['user']?['id']?.toString(),
      collegeId: json['collegeId']?.toString() ?? college?['id']?.toString(),
      collegeName: college is Map ? college['name']?.toString() : json['collegeName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'fatherName': fatherName,
        'familyName': familyName,
        'userId': userId,
        'collegeId': collegeId,
      };
}
