import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/widgets/data_list_screen.dart';

/// Not captured in a screenshot — built on the same table pattern as
/// Users/Colleges. Adjust columns once you know the real Prisma model.
///
/// FUTURE API WIRING: GET/POST/PUT/DELETE AppConstants.employeesEndpoint
class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      route: '/employees',
      title: 'الموظفون',
      addLabel: 'إضافة موظف',
      onAdd: () {},
      columns: const [
        ListColumn('الاسم', flex: 3),
        ListColumn('الكلية', flex: 3),
        ListColumn('المنصب', flex: 2),
        ListColumn('رقم الهاتف', flex: 2),
      ],
      rows: [
        for (final e in mockEmployees)
          [
            Text(e.name),
            Text(e.college),
            Text(e.position),
            Text(e.phone),
          ],
      ],
      onEdit: (i) {},
      onDelete: (i) {},
    );
  }
}
