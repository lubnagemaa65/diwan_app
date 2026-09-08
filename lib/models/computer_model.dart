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
  final String id;
  final String code; // مثال: COL03-PC001
  final ComputerType type;
  final String? collegeId;
  final String? collegeName;
  final String? employeeId;
  final String? employeeName;
  final String? processor;
  final String? diskType;
  final String? diskSize;
  final String? ram;
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
    this.diskType,
    this.diskSize,
    this.ram,
    this.purchaseDate,
    required this.status,
  });

  factory ComputerModel.fromJson(Map<String, dynamic> json) {
    final college = json['college'];
    final employee = json['employee'];
    return ComputerModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      code: (json['code'] ?? json['assetCode'] ?? '').toString(),
      type: ComputerTypeX.fromString(json['type']?.toString()),
      collegeId: json['collegeId']?.toString() ?? college?['id']?.toString(),
      collegeName: college is Map ? college['name']?.toString() : json['collegeName']?.toString(),
      employeeId: json['employeeId']?.toString() ?? employee?['id']?.toString(),
      employeeName: employee is Map
          ? [employee['firstName'], employee['fatherName'], employee['familyName']]
              .where((e) => e != null && e.toString().isNotEmpty)
              .join(' ')
          : json['employeeName']?.toString(),
      processor: json['processor']?.toString(),
      diskType: json['diskType']?.toString() ?? json['disk_type']?.toString(),
      diskSize: json['diskSize']?.toString() ?? json['disk_size']?.toString(),
      ram: json['ram']?.toString(),
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate'].toString())
          : null,
      status: AssetStatusX.fromString(json['status']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'type': type == ComputerType.desktop ? 'desktop' : 'laptop',
        'collegeId': collegeId,
        'employeeId': employeeId,
        'processor': processor,
        'diskType': diskType,
        'diskSize': diskSize,
        'ram': ram,
        'purchaseDate': purchaseDate?.toIso8601String(),
      };

  String get diskLabel => [diskType, diskSize].where((e) => e != null && e.isNotEmpty).join(' - ');
}
