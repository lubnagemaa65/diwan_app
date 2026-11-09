// Local enums used by the API mappers.
enum UserRole { admin, technician, employee }

enum AssetStatus { active, broken, underMaintenance, unknown }

enum MaintenanceStatus { pending, inProgress, completed, cancelled, unknown }

/// تحويلات بين قيم الباك اند (ADMIN, IN_PROGRESS, DISABLED ...) وقيم التطبيق.
class ApiMappers {
  ApiMappers._();

  // ---------- الأدوار ----------
  static UserRole roleFromApi(String? v) {
    switch (v?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'TECHNICIAN':
        return UserRole.technician;
      default:
        return UserRole.employee;
    }
  }

  static String roleToApi(UserRole r) {
    if (r == UserRole.admin) return 'ADMIN';
    if (r == UserRole.technician) return 'TECHNICIAN';
    return 'EMPLOYEE';
  }

  // ---------- حالة الجهاز (ACTIVE / DISABLED / MAINTENANCE) ----------
  static AssetStatus assetStatusFromApi(String? v) {
    switch (v?.toUpperCase()) {
      case 'ACTIVE':
        return AssetStatus.active;
      case 'DISABLED':
        return AssetStatus.broken;
      case 'MAINTENANCE':
        return AssetStatus.underMaintenance;
      default:
        return AssetStatus.unknown;
    }
  }

  static String assetStatusToApi(AssetStatus s) {
    if (s == AssetStatus.broken) return 'DISABLED';
    if (s == AssetStatus.underMaintenance) return 'MAINTENANCE';
    return 'ACTIVE';
  }

  // ---------- حالة طلب الصيانة ----------
  static MaintenanceStatus maintenanceStatusFromApi(String? v) {
    switch (v?.toUpperCase()) {
      case 'PENDING':
        return MaintenanceStatus.pending;
      case 'IN_PROGRESS':
        return MaintenanceStatus.inProgress;
      case 'COMPLETED':
        return MaintenanceStatus.completed;
      case 'CANCELLED':
        return MaintenanceStatus.cancelled;
      default:
        return MaintenanceStatus.unknown;
    }
  }

  static String maintenanceStatusToApi(MaintenanceStatus s) {
    if (s == MaintenanceStatus.inProgress) return 'IN_PROGRESS';
    if (s == MaintenanceStatus.completed) return 'COMPLETED';
    if (s == MaintenanceStatus.cancelled) return 'CANCELLED';
    return 'PENDING';
  }

  // ---------- نوع المشكلة (HARDWARE / SOFTWARE) ----------
  static String problemTypeFromApi(String? v) {
    switch (v?.toUpperCase()) {
      case 'HARDWARE':
        return 'عتاد';
      case 'SOFTWARE':
        return 'برمجيات';
      default:
        return v ?? '';
    }
  }

  static String problemTypeToApi(String label) {
    final l = label.trim().toLowerCase();
    if (l == 'برمجيات' || l == 'software') return 'SOFTWARE';
    return 'HARDWARE';
  }

  // ---------- أدوات صغيرة ----------
  /// معرّفات المستخدمين والكليات والموظفين والطلبات أرقام (int) في الباك اند،
  /// بينما النماذج في التطبيق تخزّنها كنص.
  static int? toInt(String? s) => s == null ? null : int.tryParse(s);

  static String joinNames(List<dynamic> parts) =>
      parts.where((e) => e != null && e.toString().isNotEmpty).join(' ');
}
