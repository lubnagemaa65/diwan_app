import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import 'report_screen.dart';

/// FUTURE API WIRING: GET AppConstants.maintenanceRequestsEndpoint + aggregate,
/// or a dedicated /reports/maintenance endpoint once it exists.
class MaintenanceReportScreen extends StatelessWidget {
  const MaintenanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = mockMaintenanceRequests.length;
    final pending = mockMaintenanceRequests.where((m) => m.status == 'قيد الانتظار').length;
    final inProgress = mockMaintenanceRequests.where((m) => m.status == 'قيد المعالجة').length;
    final done = mockMaintenanceRequests.where((m) => m.status == 'مكتمل').length;

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
