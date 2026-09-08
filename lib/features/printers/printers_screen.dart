import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/data_list_screen.dart';
import '../../core/widgets/status_pill.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'يعمل':
      return AppColors.success;
    case 'بحاجة صيانة':
      return AppColors.warning;
    default:
      return AppColors.statusBroken;
  }
}

/// Not captured in a screenshot — built on the same table pattern.
/// FUTURE API WIRING: GET/POST/PUT/DELETE AppConstants.printersEndpoint
class PrintersScreen extends StatelessWidget {
  const PrintersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      route: '/printers',
      title: 'الطابعات',
      addLabel: 'إضافة طابعة',
      onAdd: () {},
      columns: const [
        ListColumn('اسم الطابعة', flex: 2),
        ListColumn('الكلية', flex: 3),
        ListColumn('الحالة', flex: 2),
      ],
      rows: [
        for (final p in mockPrinters)
          [
            Text(p.name),
            Text(p.college),
            StatusPill(label: p.status, color: _statusColor(p.status)),
          ],
      ],
      onEdit: (i) {},
      onDelete: (i) {},
    );
  }
}
