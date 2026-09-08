/// أدوار المستخدمين في النظام (Role-Based Access)
enum UserRole { admin, employee, technician, unknown }

extension UserRoleX on UserRole {
  /// يحوّل القيمة القادمة من الـ API (عربي أو إنجليزي) إلى Enum
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'admin':
      case 'مدير':
        return UserRole.admin;
      case 'employee':
      case 'موظف':
        return UserRole.employee;
      case 'technician':
      case 'فني':
        return UserRole.technician;
      default:
        return UserRole.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
      case UserRole.technician:
        return 'technician';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  String labelAr() {
    switch (this) {
      case UserRole.admin:
        return 'مدير';
      case UserRole.employee:
        return 'موظف';
      case UserRole.technician:
        return 'فني';
      case UserRole.unknown:
        return 'غير معروف';
    }
  }

  String labelEn() {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.employee:
        return 'Employee';
      case UserRole.technician:
        return 'Technician';
      case UserRole.unknown:
        return 'Unknown';
    }
  }
}

/// حالة الأصل (حاسوب / طابعة)
enum AssetStatus { active, broken, underMaintenance, unknown }

extension AssetStatusX on AssetStatus {
  static AssetStatus fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'active':
      case 'نشط':
        return AssetStatus.active;
      case 'broken':
      case 'inactive':
      case 'معطل':
        return AssetStatus.broken;
      case 'under_maintenance':
      case 'in_maintenance':
      case 'تحت الصيانة':
      case 'في صيانة':
        return AssetStatus.underMaintenance;
      default:
        return AssetStatus.unknown;
    }
  }

  String labelAr() {
    switch (this) {
      case AssetStatus.active:
        return 'نشط';
      case AssetStatus.broken:
        return 'معطل';
      case AssetStatus.underMaintenance:
        return 'تحت الصيانة';
      case AssetStatus.unknown:
        return 'غير معروف';
    }
  }

  String labelEn() {
    switch (this) {
      case AssetStatus.active:
        return 'Active';
      case AssetStatus.broken:
        return 'Broken';
      case AssetStatus.underMaintenance:
        return 'Under Maintenance';
      case AssetStatus.unknown:
        return 'Unknown';
    }
  }
}

/// نوع الأصل
enum AssetType { computer, printer }

/// حالة طلب الصيانة
enum MaintenanceStatus { pending, inProgress, completed, cancelled, unknown }

extension MaintenanceStatusX on MaintenanceStatus {
  static MaintenanceStatus fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'pending':
      case 'قيد الانتظار':
        return MaintenanceStatus.pending;
      case 'in_progress':
      case 'قيد التنفيذ':
      case 'في صيانة':
        return MaintenanceStatus.inProgress;
      case 'completed':
      case 'مكتمل':
        return MaintenanceStatus.completed;
      case 'cancelled':
      case 'ملغى':
      case 'ملغي':
        return MaintenanceStatus.cancelled;
      default:
        return MaintenanceStatus.unknown;
    }
  }

  String labelAr() {
    switch (this) {
      case MaintenanceStatus.pending:
        return 'قيد الانتظار';
      case MaintenanceStatus.inProgress:
        return 'قيد التنفيذ';
      case MaintenanceStatus.completed:
        return 'مكتمل';
      case MaintenanceStatus.cancelled:
        return 'ملغى';
      case MaintenanceStatus.unknown:
        return 'غير معروف';
    }
  }

  String labelEn() {
    switch (this) {
      case MaintenanceStatus.pending:
        return 'Pending';
      case MaintenanceStatus.inProgress:
        return 'In Progress';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.cancelled:
        return 'Cancelled';
      case MaintenanceStatus.unknown:
        return 'Unknown';
    }
  }
}

class StorageKeys {
  StorageKeys._();
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userProfile = 'user_profile';
  static const String appLocale = 'app_locale';
  static const String appThemeMode = 'app_theme_mode';
}

class AppConstants {
  AppConstants._();
  static const String appNameAr = 'إدارة أصول الجامعة';
  static const String appNameEn = 'University Assets';
}
