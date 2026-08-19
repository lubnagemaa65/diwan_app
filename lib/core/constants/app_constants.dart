/// Central place for app-wide constant values.
///
/// Keeping the future API base URL and endpoint paths here means that
/// when the backend is ready, only this file (plus the repository
/// implementations) needs to change — no screen code should ever
/// hardcode a URL directly.
class AppConstants {
  AppConstants._();

  static const String appName = 'Facility Manager';

  // ---------------------------------------------------------------------
  // FUTURE REST API CONFIGURATION
  // Replace with your real backend origin when ready, e.g.
  // 'https://api.yourcompany.com/v1'
  // ---------------------------------------------------------------------
  static const String apiBaseUrl = 'https://api.example.com/v1';

  static const String loginEndpoint = '$apiBaseUrl/auth/login';
  static const String logoutEndpoint = '$apiBaseUrl/auth/logout';
  static const String currentUserEndpoint = '$apiBaseUrl/auth/me';

  static const String maintenanceTasksEndpoint =
      '$apiBaseUrl/technician/tasks';
  static const String employeeRequestsEndpoint =
      '$apiBaseUrl/employee/requests';
  static const String adminUsersEndpoint = '$apiBaseUrl/admin/users';
  static const String adminMetricsEndpoint = '$apiBaseUrl/admin/metrics';

  // Simulated network latency for mock repositories, so loading states
  // are visible during development/demo. Set to Duration.zero to disable.
  static const Duration mockNetworkDelay = Duration(milliseconds: 900);
}
