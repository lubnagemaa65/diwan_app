import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import 'report_screen.dart';

/// FUTURE API WIRING: GET AppConstants.computersEndpoint + aggregate,
/// or a dedicated /reports/computers endpoint once it exists.
class ComputersReportScreen extends StatelessWidget {
  const ComputersReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = mockComputers.length;
    final working = mockComputers.where((c) => c.status == 'يعمل').length;
    final needsMaint =
        mockComputers.where((c) => c.status == 'بحاجة صيانة').length;
    final outOfService =
        mockComputers.where((c) => c.status == 'خارج الخدمة').length;

    return ReportScreen(
      route: '/reports/computers',
      title: 'تقرير الحواسيب',
      stats: [
        ReportStat('إجمالي الحواسيب', '$total', AppColors.primary),
        ReportStat('تعمل', '$working', AppColors.success),
        ReportStat('بحاجة صيانة', '$needsMaint', AppColors.warning),
        ReportStat('خارج الخدمة', '$outOfService', AppColors.statusBroken),
      ],
    );
  }
}
