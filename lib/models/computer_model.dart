import '../core/constants/app_constants.dart';

/// نوع جهاز الحاسوب: مكتبي / محمول
enum ComputerType { desktop, laptop, unknown }

extension ComputerTypeX on ComputerType {
  static ComputerType fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'desktop':
      case 'مكتبي':
        return ComputerType.desktop;
      case 'laptop':
      case 'محمول':
        return ComputerType.laptop;
      default:
        return ComputerType.unknown;
    }
  }

  String labelAr() => this == ComputerType.desktop
      ? 'مكتبي'
      : this == ComputerType.laptop
          ? 'محمول'
          : 'غير معروف';

  String labelEn() => this == ComputerType.desktop
      ? 'Desktop'
      : this == ComputerType.laptop
          ? 'Laptop'
          : 'Unknown';
}

class ComputerModel {
  /// في الباك اند معرّف الحاسوب هو نفسه الكود (مثال: COL03-PC001) ويُولَّد تلقائياً.
  final String id;
  final String code;
  final ComputerType type;
  final String? collegeId;
  final String? collegeName;
  final String? employeeId;
  final String? employeeName;
  final String? processor;
  final String? motherboard;

  /// SATA أو IDE فقط (hardDiskType)
  final String? diskType;

  /// مثال: 512GB (hardDiskSpace)
  final String? diskSize;

  /// ramType
  final String? ram;

  /// INTEGRATED أو SEPARATE
  final String? graphicsCard;

  /// غير موجود في الباك اند حالياً، أُبقي فارغاً حتى لا تنكسر الشاشات القديمة.
  final DateTime? purchaseDate;
  final AssetStatus status;

  ComputerModel({
    required this.id,
    required this.code,
    required this.type,
    this.collegeId,
    this.collegeName,
    this.employeeId,
    this.employeeName,
    this.processor,
    this.motherboard,
    this.diskType,
    this.diskSize,
    this.ram,
    this.graphicsCard,
    this.purchaseDate,
    required this.status,
  });

  factory ComputerModel.fromJson(Map<String, dynamic> json) {
    final college = json['college'];
    final employee = json['employee'];
    final id = (json['id'] ?? '').toString();
    return ComputerModel(
      id: id,
      code: id,
      type: ComputerTypeX.fromString(json['type']?.toString()),
      collegeId: json['collegeId']?.toString() ??
          (college is Map ? college['id']?.toString() : null),
      collegeName: college is Map ? college['name']?.toString() : null,
      employeeId: json['employeeId']?.toString() ??
          (employee is Map ? employee['id']?.toString() : null),
      employeeName: employee is Map
          ? ApiMappers.joinNames([employee['firstName'], employee['lastName']])
          : null,
      processor: json['processor']?.toString(),
      motherboard: json['motherboard']?.toString(),
      diskType: json['hardDiskType']?.toString(),
      diskSize: json['hardDiskSpace']?.toString(),
      ram: json['ramType']?.toString(),
      graphicsCard: json['graphicsCard']?.toString(),
      status: ApiMappers.assetStatusFromApi(json['status']?.toString()),
    );
  }

  /// جسم طلب الإنشاء POST /computers (الكود يُولَّد في الباك اند فلا يُرسل).
  Map<String, dynamic> toJson() => {
        'type': type == ComputerType.laptop ? 'LAPTOP' : 'DESKTOP',
        'processor': processor,
        'motherboard': motherboard,
        'hardDiskType': diskType,
        'hardDiskSpace': diskSize,
        'ramType': ram,
        'graphicsCard': graphicsCard,
        'status': ApiMappers.assetStatusToApi(status),
        'collegeId': ApiMappers.toInt(collegeId),
        'employeeId': ApiMappers.toInt(employeeId),
      };

  /// جسم طلب التعديل PATCH /computers/:id (الباك اند لا يسمح بتغيير الكلية).
  Map<String, dynamic> toUpdateJson() {
    final m = toJson()..remove('collegeId');
    return m;
  }

  String get diskLabel =>
      [diskType, diskSize].where((e) => e != null && e.isNotEmpty).join(' - ');
}
