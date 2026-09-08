/// عنوان الـ API الأساسي وجميع نقاط النهاية (Endpoints)
/// مطابقة لباك إند مشروع `university-assets-api`
///
/// عدّل [baseUrl] ليطابق بيئتك (محلي / سيرفر / إنتاج).
class ApiConstants {
  ApiConstants._();

  // TODO: استبدل هذا بعنوان السيرفر الفعلي لديك
  // مثال محلي: http://192.168.1.66:3000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.66:3000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ---------------- Auth ----------------
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';

  // ---------------- Users (المستخدمون) ----------------
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // ---------------- Colleges (الكليات) ----------------
  static const String colleges = '/colleges';
  static String collegeById(String id) => '/colleges/$id';

  // ---------------- Employees (الموظفون) ----------------
  static const String employees = '/employees';
  static String employeeById(String id) => '/employees/$id';

  // ---------------- Computers (الحواسيب) ----------------
  static const String computers = '/computers';
  static String computerById(String id) => '/computers/$id';

  // ---------------- Printers (الطابعات) ----------------
  static const String printers = '/printers';
  static String printerById(String id) => '/printers/$id';

  // ---------------- Maintenance Orders (طلبات الصيانة) ----------------
  static const String maintenanceOrders = '/maintenance-orders';
  static String maintenanceOrderById(String id) => '/maintenance-orders/$id';

  // ---------------- Reports (التقارير) ----------------
  static const String reportComputers = '/reports/computers';
  static const String reportPrinters = '/reports/printers';
  static const String reportMaintenanceOrders = '/reports/maintenance-orders';

  // ---------------- Activity Log (سجل النشاطات) ----------------
  static const String activityLogs = '/activity-logs';

  // ---------------- Dashboard ----------------
  static const String dashboardSummary = '/dashboard/summary';
}
