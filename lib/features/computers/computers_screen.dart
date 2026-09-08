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
/// FUTURE API WIRING: GET/POST/PUT/DELETE AppConstants.computersEndpoint
class ComputersScreen extends StatelessWidget {
  const ComputersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      route: '/computers',
      title: 'الحواسيب',
      addLabel: 'إضافة حاسوب',
      onAdd: () {},
      columns: const [
        ListColumn('اسم الجهاز', flex: 2),
        ListColumn('الكلية', flex: 3),
        ListColumn('الحالة', flex: 2),
      ],
      rows: [
        for (final c in mockComputers)
          [
            Text(c.name),
            Text(c.college),
            StatusPill(label: c.status, color: _statusColor(c.status)),
          ],
      ],
      onEdit: (i) {},
      onDelete: (i) {},
    );
  }
}
