import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'report_screen.dart';

/// FUTURE API WIRING: GET AppConstants.computersEndpoint + aggregate,
/// or a dedicated /reports/computers endpoint once it exists.
class ComputersReportScreen extends StatelessWidget {
  const ComputersReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final computers = <Map<String, String>>[
      {'status': 'يعمل'},
      {'status': 'يعمل'},
      {'status': 'بحاجة صيانة'},
      {'status': 'خارج الخدمة'},
    ];

    final total = computers.length;
    final working = computers.where((c) => c['status'] == 'يعمل').length;
    final needsMaint =
        computers.where((c) => c['status'] == 'بحاجة صيانة').length;
    final outOfService =
        computers.where((c) => c['status'] == 'خارج الخدمة').length;

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
