import 'package:flutter/material.dart';

/// لوحة ألوان مطابقة **حرفيًا** لتصميم النظام الأصلي
/// "نظام إدارة أجهزة الجامعة" (أزرق فاتح + خلفية بيضاء + رقاقات حالة واضحة)
class AppColors {
  AppColors._();

  // نفس الأزرق الظاهر في الشريط العلوي بالنظام الأصلي
  static const Color primary = Color(0xFF2F80ED);
  static const Color primaryDark = Color(0xFF1C5FC7);
  static const Color primaryLight = Color(0xFF6FA6F5);

  static const Color secondary = Color(0xFF00A896);

  // النظام الأصلي أبيض بالكامل تقريبًا، بلا خلفية رمادية داكنة
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkSurface = Color(0xFF1E2126);

  // حالات الأصول / الصيانة — نفس الأخضر/الأحمر/الرمادي الظاهر في النظام الأصلي بالضبط
  static const Color statusActive = Color(0xFF1E8E3E); // نشط - أخضر
  static const Color statusBroken = Color(0xFFD93025); // معطل - أحمر
  static const Color statusMaintenance = Color(0xFFF9A825); // تحت الصيانة - برتقالي
  static const Color statusPending = Color(0xFF9AA0A6); // قيد الانتظار - رمادي
  static const Color statusInProgress = Color(0xFF1967D2); // قيد التنفيذ - أزرق
  static const Color statusCompleted = Color(0xFF1E8E3E); // مكتمل - أخضر
  static const Color statusCancelled = Color(0xFF9AA0A6); // ملغى - رمادي

  static const Color error = Color(0xFFD93025);
  static const Color warning = Color(0xFFF9A825);
  static const Color success = Color(0xFF1E8E3E);
  static const Color info = Color(0xFF1967D2);

  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color divider = Color(0xFFE0E3E7);

  // ألوان أيقونات الإجراءات في الجداول (تعديل/حذف/صيانة) كما في النظام الأصلي
  static const Color actionEdit = Color(0xFF5F6368);
  static const Color actionDelete = Color(0xFF5F6368);
  static const Color actionMaintenance = Color(0xFF5F6368);
}
