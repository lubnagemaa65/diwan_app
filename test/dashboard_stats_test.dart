import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/features/dashboard/services/dashboard_stats_service.dart';

import 'support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnvironment env;
  setUp(() => env = TestEnvironment());
  tearDown(() => env.dispose());

  testWidgets('completed orders calculate dashboard counts without throwing',
      (tester) async {
    env.api.orders.addAll([
      {
        'id': 3,
        'computerId': 'PC-101',
        'type': 'HARDWARE',
        'problemDescription': 'First repair',
        'status': 'COMPLETED',
        'date': '2025-01-01T00:00:00Z',
        'updatedAt': '2025-01-02T00:00:00Z'
      },
      {
        'id': 4,
        'computerId': 'PC-101',
        'type': 'HARDWARE',
        'problemDescription': 'Second repair',
        'status': 'COMPLETED'
      },
    ]);
    final stats = (await tester.runAsync(DashboardStatsService.load))!;
    expect(stats.totalComputers, 2);
    expect(stats.totalPrinters, 1);
    expect(stats.totalOrders, 4);
    expect(stats.pendingCount, 1);
    expect(stats.inProgressCount, 1);
    expect(stats.completedCount, 2);
    expect(stats.devicesRepairedCount, 1);
    expect(stats.completionRate, 0.5);
  });
}
