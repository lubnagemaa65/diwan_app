class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static String? email(String? value, {String requiredMsg = 'هذا الحقل مطلوب', String invalidMsg = 'يرجى إدخال بريد إلكتروني صحيح'}) {
    if (value == null || value.trim().isEmpty) return requiredMsg;
    if (!_emailRegex.hasMatch(value.trim())) return invalidMsg;
    return null;
  }

  static String? required(String? value, {String message = 'هذا الحقل مطلوب'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? password(String? value, {int minLength = 6, String message = 'كلمة المرور مطلوبة'}) {
    if (value == null || value.isEmpty) return message;
    if (value.length < minLength) return 'يجب ألا تقل كلمة المرور عن $minLength أحرف';
    return null;
  }
}
