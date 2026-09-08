import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/widgets/data_list_screen.dart';
import '../../core/widgets/status_pill.dart';

/// Matches the "المستخدمون" screenshots: name / email / role columns,
/// blue "إضافة مستخدم" button, edit + delete actions.
///
/// FUTURE API WIRING:
///   - Load  -> GET  AppConstants.usersEndpoint
///   - Add   -> POST AppConstants.usersEndpoint
///   - Edit  -> PUT  AppConstants.usersEndpoint/{id}
///   - Delete-> DELETE AppConstants.usersEndpoint/{id}
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      route: '/users',
      title: 'المستخدمون',
      addLabel: 'إضافة مستخدم',
      onAdd: () {
        // FUTURE: open an add-user dialog/screen, then POST to usersEndpoint.
      },
      columns: const [
        ListColumn('الاسم', flex: 3),
        ListColumn('البريد الإلكتروني', flex: 4),
        ListColumn('الدور', flex: 2),
      ],
      rows: [
        for (final u in mockUsers)
          [
            Text(u.name),
            Text(u.email),
            StatusPill(label: u.role),
          ],
      ],
      onEdit: (i) {
        // FUTURE: PUT AppConstants.usersEndpoint/{mockUsers[i].id}
      },
      onDelete: (i) {
        // FUTURE: DELETE AppConstants.usersEndpoint/{mockUsers[i].id}
      },
    );
  }
}
