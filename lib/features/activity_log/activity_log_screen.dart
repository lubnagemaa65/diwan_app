import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/widgets/data_list_screen.dart';

/// Not captured in a screenshot — read-only log using the same table
/// pattern, but with no add/edit/delete actions.
///
/// FUTURE API WIRING: GET AppConstants.activityLogEndpoint
class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      route: '/activity-log',
      title: 'سجل النشاطات',
      showActions: false,
      columns: const [
        ListColumn('الوقت', flex: 2),
        ListColumn('المستخدم', flex: 2),
        ListColumn('الإجراء', flex: 4),
      ],
      rows: [
        for (final a in mockActivityLog)
          [
            Text(a.time),
            Text(a.user),
            Text(a.action),
          ],
      ],
    );
  }
}
