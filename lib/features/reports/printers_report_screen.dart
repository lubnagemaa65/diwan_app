import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import 'report_screen.dart';

/// FUTURE API WIRING: GET AppConstants.printersEndpoint + aggregate,
/// or a dedicated /reports/printers endpoint once it exists.
class PrintersReportScreen extends StatelessWidget {
  const PrintersReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = mockPrinters.length;
    final working = mockPrinters.where((p) => p.status == 'يعمل').length;
    final needsMaint = mockPrinters.where((p) => p.status == 'بحاجة صيانة').length;

    return ReportScreen(
      route: '/reports/printers',
      title: 'تقرير الطابعات',
      stats: [
        ReportStat('إجمالي الطابعات', '$total', AppColors.primary),
        ReportStat('تعمل', '$working', AppColors.success),
        ReportStat('بحاجة صيانة', '$needsMaint', AppColors.warning),
      ],
    );
  }
}
