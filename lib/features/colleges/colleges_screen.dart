import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/widgets/data_list_screen.dart';

/// Matches the "الكليات" screenshot: numbered rows, college name, blue
/// "إضافة كلية" button, edit + delete actions, and the copyright footer.
///
/// FUTURE API WIRING:
///   - Load  -> GET  AppConstants.collegesEndpoint
///   - Add   -> POST AppConstants.collegesEndpoint
///   - Edit  -> PUT  AppConstants.collegesEndpoint/{id}
///   - Delete-> DELETE AppConstants.collegesEndpoint/{id}
class CollegesScreen extends StatelessWidget {
  const CollegesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      route: '/colleges',
      title: 'الكليات',
      addLabel: 'إضافة كلية',
      onAdd: () {
        // FUTURE: open an add-college dialog, then POST to collegesEndpoint.
      },
      columns: const [
        ListColumn('الرقم', flex: 1),
        ListColumn('اسم الكلية', flex: 4),
      ],
      rows: [
        for (final c in mockColleges)
          [
            Text('${c.number}'),
            Text(c.name),
          ],
      ],
      onEdit: (i) {
        // FUTURE: PUT AppConstants.collegesEndpoint/{mockColleges[i].number}
      },
      onDelete: (i) {
        // FUTURE: DELETE AppConstants.collegesEndpoint/{mockColleges[i].number}
      },
      footer: '© 2026 نظام إدارة أجهزة الجامعة — جميع الحقوق محفوظة',
    );
  }
}
