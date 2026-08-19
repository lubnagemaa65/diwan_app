import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/admin/admin_dashboard_screen.dart';
import 'features/dashboard/employee/employee_dashboard_screen.dart';
import 'features/dashboard/technician/technician_dashboard_screen.dart';

void main() {
  runApp(const FacilityApp());
}

class FacilityApp extends StatelessWidget {
  const FacilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Single AuthController instance for the whole app. When the real
      // backend is ready, this is also where you'd inject an
      // AuthRepositoryHttp instead of the default mock AuthRepository:
      //   AuthController(repository: AuthRepositoryHttp())
      create: (_) => AuthController(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppColors.themeData(),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/dashboard/admin': (_) => const AdminDashboardScreen(),
          '/dashboard/technician': (_) => const TechnicianDashboardScreen(),
          '/dashboard/employee': (_) => const EmployeeDashboardScreen(),
        },
      ),
    );
  }
}
