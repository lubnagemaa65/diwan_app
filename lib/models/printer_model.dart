import '../core/constants/app_constants.dart';

class PrinterModel {
  final String id;
  final String code;
  final String? type; // مثال: ليزر Laser
  final String? collegeId;
  final String? collegeName;
  final String? employeeId;
  final String? employeeName;
  final AssetStatus status;

  PrinterModel({
    required this.id,
    required this.code,
    this.type,
    this.collegeId,
    this.collegeName,
    this.employeeId,
    this.employeeName,
    required this.status,
  });

  factory PrinterModel.fromJson(Map<String, dynamic> json) {
    final college = json['college'];
    final employee = json['employee'];
    return PrinterModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      code: (json['code'] ?? json['assetCode'] ?? '').toString(),
      type: json['type']?.toString(),
      collegeId: json['collegeId']?.toString() ?? college?['id']?.toString(),
      collegeName: college is Map ? college['name']?.toString() : json['collegeName']?.toString(),
      employeeId: json['employeeId']?.toString() ?? employee?['id']?.toString(),
      employeeName: employee is Map
          ? [employee['firstName'], employee['fatherName'], employee['familyName']]
              .where((e) => e != null && e.toString().isNotEmpty)
              .join(' ')
          : json['employeeName']?.toString(),
      status: AssetStatusX.fromString(json['status']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'type': type,
        'collegeId': collegeId,
        'employeeId': employeeId,
      };
}
