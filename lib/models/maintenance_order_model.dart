import '../core/constants/app_constants.dart';

class MaintenanceOrderModel {
  final String id;
  final DateTime? date;
  final AssetType deviceType; // computer / printer
  final String deviceId;
  final String? deviceCode;
  final String? requesterId;
  final String? requesterName;
  final String? technicianId;
  final String? technicianName;
  final String problemType; // عتاد / برمجيات / شبكة / أخرى
  final String description;
  final MaintenanceStatus status;

  MaintenanceOrderModel({
    required this.id,
    this.date,
    required this.deviceType,
    required this.deviceId,
    this.deviceCode,
    this.requesterId,
    this.requesterName,
    this.technicianId,
    this.technicianName,
    required this.problemType,
    required this.description,
    required this.status,
  });

  factory MaintenanceOrderModel.fromJson(Map<String, dynamic> json) {
    final device = json['device'];
    final requester = json['requester'] ?? json['requestedBy'];
    final technician = json['technician'];

    return MaintenanceOrderModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null),
      deviceType: (json['deviceType']?.toString().toLowerCase() == 'printer' ||
              json['deviceType']?.toString() == 'طابعة')
          ? AssetType.printer
          : AssetType.computer,
      deviceId: (json['deviceId'] ?? device?['id'] ?? '').toString(),
      deviceCode: device is Map ? device['code']?.toString() : json['deviceCode']?.toString(),
      requesterId: json['requesterId']?.toString() ?? requester?['id']?.toString(),
      requesterName: requester is Map
          ? [requester['firstName'], requester['fatherName'], requester['familyName']]
              .where((e) => e != null && e.toString().isNotEmpty)
              .join(' ')
          : requester?.toString(),
      technicianId: json['technicianId']?.toString() ?? technician?['id']?.toString(),
      technicianName: technician is Map
          ? (technician['name'] ?? technician['email'])?.toString()
          : technician?.toString(),
      problemType: (json['problemType'] ?? json['issueType'] ?? '').toString(),
      description: (json['description'] ?? json['problemDescription'] ?? '').toString(),
      status: MaintenanceStatusX.fromString(json['status']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceType': deviceType == AssetType.computer ? 'computer' : 'printer',
        'deviceId': deviceId,
        'requesterId': requesterId,
        'problemType': problemType,
        'description': description,
      };
}
