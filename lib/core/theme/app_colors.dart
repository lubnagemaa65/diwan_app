import 'package:flutter/material.dart';

/// لوحة ألوان موحّدة للتطبيق (مطابقة لهوية النظام الأصلي - أزرق أساسي)
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E56A0);
  static const Color primaryDark = Color(0xFF163F73);
  static const Color primaryLight = Color(0xFF4A7FC1);

  static const Color secondary = Color(0xFF00A896);

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkSurface = Color(0xFF1E2126);

  // حالات الأصول / الصيانة
  static const Color statusActive = Color(0xFF2E7D32); // نشط
  static const Color statusBroken = Color(0xFFC62828); // معطل
  static const Color statusMaintenance = Color(0xFFF9A825); // تحت الصيانة
  static const Color statusPending = Color(0xFF757575); // قيد الانتظار
  static const Color statusInProgress = Color(0xFF1565C0); // قيد التنفيذ
  static const Color statusCompleted = Color(0xFF2E7D32); // مكتمل
  static const Color statusCancelled = Color(0xFF9E9E9E); // ملغى

  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF0288D1);

  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
}
