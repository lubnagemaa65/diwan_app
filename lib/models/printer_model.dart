import '../core/constants/app_constants.dart';

class PrinterModel {
  /// معرّف الطابعة في الباك اند هو نفسه الكود (مثال: COL03-PR001) ويُولَّد تلقائياً.
  final String id;
  final String code;
  final String? type; // مثال: ليزر Laser
  final String? collegeId;
  final String? collegeName;

  /// الباك اند لا يربط الطابعة بموظف حالياً، أُبقيا فارغين حتى لا تنكسر الشاشات.
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
    final id = (json['id'] ?? '').toString();
    return PrinterModel(
      id: id,
      code: id,
      type: json['type']?.toString(),
      collegeId: json['collegeId']?.toString() ??
          (college is Map ? college['id']?.toString() : null),
      collegeName: college is Map ? college['name']?.toString() : null,
      status: ApiMappers.assetStatusFromApi(json['status']?.toString()),
    );
  }

  /// جسم طلب الإنشاء POST /printers
  Map<String, dynamic> toJson() => {
        'type': type,
        'status': ApiMappers.assetStatusToApi(status),
        'collegeId': ApiMappers.toInt(collegeId),
      };

  /// جسم طلب التعديل PATCH /printers/:id
  Map<String, dynamic> toUpdateJson() => {
        'type': type,
        'status': ApiMappers.assetStatusToApi(status),
      };
}
