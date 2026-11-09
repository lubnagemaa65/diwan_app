enum AssetType { computer, printer }

enum MaintenanceStatus { pending, inProgress, completed, cancelled }

class ApiMappers {
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  static String joinNames(List<dynamic> names) {
    final parts = names
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  /// يحوّل قيمة الباك اند (hardware/software، بأي حالة أحرف) إلى تمثيل
  /// داخلي موحّد بالإنجليزية الكبيرة (HARDWARE/SOFTWARE) يطابق enum
  /// الباك اند حرفياً، ليسهل إعادة إرساله لاحقاً دون أي لبس.
  static String problemTypeFromApi(String? value) {
    switch (value?.toLowerCase()) {
      case 'software':
        return 'SOFTWARE';
      case 'hardware':
      default:
        return 'HARDWARE';
    }
  }

  /// يحوّل القيمة الداخلية (HARDWARE/SOFTWARE) إلى القيمة التي يتوقعها
  /// الباك اند فعلياً (Prisma enum MaintenanceType: HARDWARE/SOFTWARE —
  /// بالأحرف الكبيرة بالضبط). يقبل أيضاً مدخلات عربية قديمة للتوافق.
  static String problemTypeToApi(String value) {
    final v = value.trim();
    if (v == 'SOFTWARE' || v.toLowerCase() == 'software' || v == 'برمجيات') {
      return 'SOFTWARE';
    }
    return 'HARDWARE';
  }

  static MaintenanceStatus maintenanceStatusFromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return MaintenanceStatus.pending;
      case 'IN_PROGRESS':
        return MaintenanceStatus.inProgress;
      case 'COMPLETED':
        return MaintenanceStatus.completed;
      case 'CANCELLED':
        return MaintenanceStatus.cancelled;
      default:
        return MaintenanceStatus.pending;
    }
  }

  /// يحوّل حالة الطلب إلى القيمة التي يتوقعها الباك اند فعلياً (Prisma enum
  /// MaintenanceOrderStatus: PENDING/IN_PROGRESS/COMPLETED/CANCELLED —
  /// بالأحرف الكبيرة بالضبط). يأخذ enum مباشرة (type-safe) بدل نص حر،
  /// لتفادي أي التباس أو حاجة لـ "as dynamic" عند الاستدعاء.
  static String maintenanceStatusToApi(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return 'PENDING';
      case MaintenanceStatus.inProgress:
        return 'IN_PROGRESS';
      case MaintenanceStatus.completed:
        return 'COMPLETED';
      case MaintenanceStatus.cancelled:
        return 'CANCELLED';
    }
  }

  /// تسمية عربية لعرض نوع المشكلة في الواجهة (القيمة الداخلية تبقى إنجليزية).
  static String problemTypeLabelAr(String value) =>
      problemTypeToApi(value) == 'SOFTWARE' ? 'برمجيات' : 'عتاد';

  /// تسمية عربية لعرض حالة الطلب في الواجهة.
  static String maintenanceStatusLabelAr(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return 'معلق';
      case MaintenanceStatus.inProgress:
        return 'قيد التنفيذ';
      case MaintenanceStatus.completed:
        return 'مكتمل';
      case MaintenanceStatus.cancelled:
        return 'ملغى';
    }
  }
}

class MaintenanceOrderModel {
  final String id;
  final DateTime? date;

  /// آخر تعديل على الطلب. عند الحالة "مكتمل" تُستخدم كتقريب لوقت الإصلاح
  /// فعلياً، لأن الباك اند لا يخزّن وقت إنجاز منفصلاً.
  final DateTime? updatedAt;
  final AssetType deviceType; // computer / printer
  final String deviceId; // = كود الجهاز في الباك اند
  final String? deviceCode;
  final String? requesterId; // معرّف الموظف (Employee) وليس المستخدم
  final String? requesterName;
  final String? technicianId; // معرّف المستخدم الفني (User)
  final String? technicianName;

  /// القيمة الداخلية دائماً 'HARDWARE' أو 'SOFTWARE' (إنجليزي كبير)،
  /// مطابقة لما يخزّنه/يتوقعه الباك اند. للعرض بالعربي استخدم
  /// ApiMappers.problemTypeLabelAr(problemType).
  final String problemType;
  final String description;
  final MaintenanceStatus status;

  MaintenanceOrderModel({
    required this.id,
    this.date,
    this.updatedAt,
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
    final requester = json['requestedBy'];
    final technician = json['technician'];
    final isPrinter = json['printerId'] != null;
    final deviceId = (json['computerId'] ?? json['printerId'] ?? '').toString();

    return MaintenanceOrderModel(
      id: (json['id'] ?? '').toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      deviceType: isPrinter ? AssetType.printer : AssetType.computer,
      deviceId: deviceId,
      deviceCode: deviceId,
      requesterId: json['requestedById']?.toString(),
      requesterName: requester is Map
          ? ApiMappers.joinNames([
              requester['firstName'],
              requester['lastName'],
            ])
          : null,
      technicianId: json['technicianId']?.toString(),
      technicianName: technician is Map
          ? (technician['name'] ?? technician['email'])?.toString()
          : null,
      problemType: ApiMappers.problemTypeFromApi(json['type']?.toString()),
      description: (json['problemDescription'] ?? '').toString(),
      status: ApiMappers.maintenanceStatusFromApi(json['status']?.toString()),
    );
  }

  /// جسم طلب الإنشاء POST /maintenance-orders
  /// (الباك اند يقبل computerId أو printerId فقط، وليس الاثنين معاً).
  /// للموظف (EMPLOYEE) يتجاهل الباك اند requestedById ويستخدم سجل الموظف المرتبط بحسابه.
  Map<String, dynamic> toJson() => {
        'type': ApiMappers.problemTypeToApi(problemType),
        'problemDescription': description,
        if (deviceType == AssetType.printer)
          'printerId': deviceId
        else
          'computerId': deviceId,
        if (ApiMappers.toInt(requesterId) != null)
          'requestedById': ApiMappers.toInt(requesterId),
        if (ApiMappers.toInt(technicianId) != null)
          'technicianId': ApiMappers.toInt(technicianId),
      };
}
