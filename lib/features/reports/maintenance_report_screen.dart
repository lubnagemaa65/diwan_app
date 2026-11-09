import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'report_screen.dart';

/// FUTURE API WIRING: GET AppConstants.maintenanceRequestsEndpoint + aggregate,
/// or a dedicated /reports/maintenance endpoint once it exists.
class MaintenanceReportScreen extends StatelessWidget {
  const MaintenanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use mock data when available; fallback to empty list to avoid undefined identifier.
    final maintenanceRequests = <dynamic>[];
    final total = maintenanceRequests.length;
    final pending =
        maintenanceRequests.where((m) => m.status == 'قيد الانتظار').length;
    final inProgress =
        maintenanceRequests.where((m) => m.status == 'قيد المعالجة').length;
    final done = maintenanceRequests.where((m) => m.status == 'مكتمل').length;

    return ReportScreen(
      route: '/reports/maintenance',
      title: 'تقرير طلبات الصيانة',
      stats: [
        ReportStat('إجمالي الطلبات', '$total', AppColors.primary),
        ReportStat('قيد الانتظار', '$pending', AppColors.info),
        ReportStat('قيد المعالجة', '$inProgress', AppColors.warning),
        ReportStat('مكتمل', '$done', AppColors.success),
      ],
    );
  }
}
