import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/data_list_screen.dart';
import '../../core/widgets/status_pill.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'مكتمل':
      return AppColors.success;
    case 'قيد المعالجة':
      return AppColors.warning;
    default:
      return AppColors.info;
  }
}

/// Not captured in a screenshot — built on the same table pattern.
/// FUTURE API WIRING: GET/POST/PUT/DELETE AppConstants.maintenanceRequestsEndpoint
class MaintenanceRequestsScreen extends StatelessWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      route: '/maintenance-requests',
      title: 'طلبات الصيانة',
      addLabel: 'إضافة طلب',
      onAdd: () {},
      columns: const [
        ListColumn('الجهاز', flex: 2),
        ListColumn('الوصف', flex: 4),
        ListColumn('الحالة', flex: 2),
        ListColumn('التاريخ', flex: 2),
      ],
      rows: [
        for (final m in mockMaintenanceRequests)
          [
            Text(m.device),
            Text(m.description),
            StatusPill(label: m.status, color: _statusColor(m.status)),
            Text(m.date),
          ],
      ],
      onEdit: (i) {},
      onDelete: (i) {},
    );
  }
}
