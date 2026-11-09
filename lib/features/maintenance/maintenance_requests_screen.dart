import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/data_list_screen.dart';
import '../../core/widgets/status_pill.dart';

final List<Map<String, String>> _maintenanceRequests = [
  {
    'device': 'AC-01',
    'description': 'تسريب ماء من الوحدة الداخلية',
    'status': 'قيد المعالجة',
    'date': '2025-01-12',
  },
  {
    'device': 'مكيف 2',
    'description': 'عدم تبريد الهواء بشكل كافٍ',
    'status': 'مكتمل',
    'date': '2025-01-09',
  },
  {
    'device': 'إنارة',
    'description': 'إصلاح كشاف مكسور في الطابق الثاني',
    'status': 'قيد المعالجة',
    'date': '2025-01-07',
  },
];

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
        for (final request in _maintenanceRequests)
          [
            Text(request['device'] ?? ''),
            Text(request['description'] ?? ''),
            StatusPill(
              label: request['status'] ?? '',
              color: _statusColor(request['status'] ?? ''),
            ),
            Text(request['date'] ?? ''),
          ],
      ],
      onEdit: (i) {},
      onDelete: (i) {},
    );
  }
}
