import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:university_assets_app/core/localization/app_localizations.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/features/assets/providers/assets_provider.dart';
import 'package:university_assets_app/features/auth/providers/auth_provider.dart';
import 'package:university_assets_app/features/dashboard/services/dashboard_stats_service.dart';
import 'package:university_assets_app/features/dashboard/views/dashboard_screen.dart';
import 'package:university_assets_app/features/maintenance/providers/maintenance_provider.dart';
import 'package:university_assets_app/features/maintenance/views/maintenance_form_screen.dart';
import 'package:university_assets_app/features/maintenance/views/maintenance_list_screen.dart';
import 'package:university_assets_app/models/asset_item.dart';

class MockAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> patchBodies = [];
  bool rejectPatch = false;
  bool rejectAssets = false;
  String orderStatus = 'PENDING';
  int? technicianId;

  final computers = <Map<String, dynamic>>[
    {'id': 'PC-1', 'type': 'DESKTOP', 'status': 'ACTIVE'},
    {'id': 'PC-2', 'type': 'LAPTOP', 'status': 'ACTIVE'},
  ];
  final printers = <Map<String, dynamic>>[
    {'id': 'PR-1', 'type': 'Laser', 'status': 'ACTIVE'},
  ];
  late final List<Map<String, dynamic>> orders = _orders();

  List<Map<String, dynamic>> _orders() {
    final now = DateTime.now();
    String atDays(int days) => DateTime(now.year, now.month, now.day + days, 0, 30)
        .toUtc().toIso8601String();
    Map<String, dynamic> order(int id, String status, String? device,
        {bool printer = false, String? date}) => {
      'id': id, 'status': status, 'type': 'HARDWARE',
      'problemDescription': 'Fault $id',
      if (device != null) (printer ? 'printerId' : 'computerId'): device,
      if (date != null) 'date': date,
      'updatedAt': atDays(1),
    };
    return [
      order(1, 'COMPLETED', 'PC-1', date: atDays(0)),
      order(2, 'COMPLETED', 'PC-1', date: atDays(-6)),
      order(3, 'COMPLETED', 'PC-1', printer: true, date: atDays(-7)),
      order(4, 'COMPLETED', null),
      order(5, 'IN_PROGRESS', 'PC-2', date: atDays(1)),
      order(6, 'PENDING', 'PC-2', date: atDays(0)),
      order(7, 'CANCELLED', 'PC-2', date: atDays(-1)),
    ];
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    Object value;
    var code = 200;
    if (options.method == 'PATCH') {
      final data = options.data;
      final body = data is String ? jsonDecode(data) : data;
      patchBodies.add(Map<String, dynamic>.from(body as Map));
      if (rejectPatch) {
        code = 400;
        value = {'message': 'Invalid technician'};
      } else {
        orderStatus = body['status'] as String;
        technicianId = body['technicianId'] as int?;
        orders.first['status'] = orderStatus;
        value = {'id': 1, 'status': orderStatus};
      }
    } else if (options.path == '/computers' || options.path == '/printers') {
      if (rejectAssets) {
        code = 403;
        value = {'message': 'Forbidden'};
      } else {
        value = options.path == '/computers' ? computers : printers;
      }
    } else if (options.path == '/maintenance-orders') {
      value = orders;
    } else {
      value = <Object>[];
    }
    return ResponseBody.fromString(jsonEncode(value), code, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}

Widget testApp(Widget page, AssetsProvider assets, MaintenanceProvider maintenance) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AssetsProvider>.value(value: assets),
      ChangeNotifierProvider<MaintenanceProvider>.value(value: maintenance),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: page,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAdapter adapter;
  late HttpClientAdapter original;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    adapter = MockAdapter();
    original = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = adapter;
  });
  tearDown(() => ApiClient.instance.dio.httpClientAdapter = original);

  test('real status counts and date buckets; no invented repair timestamp', () async {
    final stats = await DashboardStatsService.load();
    expect(stats.totalComputers, 2);
    expect(stats.totalPrinters, 1);
    expect(stats.completedCount, 4);
    expect(stats.inProgressCount, 1);
    expect(stats.pendingCount, 1);
    expect(stats.cancelledCount, 1);
    expect(stats.totalOrders, 7);
    expect(stats.devicesRepairedCount, 2); // duplicates collapse; missing excluded; distinct types
    expect(stats.completionRate, closeTo(4 / 7, 0.00001));
    expect(stats.averageRepairTime, isNull);
    expect(stats.averageRepairTimeLabel, '—');
    expect(stats.last7DaysCounts, [1, 0, 0, 0, 0, 1, 2]);
  });

  test('empty order list gives zero completion and unavailable average', () async {
    adapter.orders.clear();
    final stats = await DashboardStatsService.load();
    expect(stats.totalOrders, 0);
    expect(stats.completionRate, 0);
    expect(stats.devicesRepairedCount, 0);
    expect(stats.averageRepairTime, isNull);
    expect(stats.last7DaysCounts, List.filled(7, 0));
  });

  test('one atomic PATCH carries both status and technician; status-only remains supported', () async {
    final p = MaintenanceProvider();
    expect(await p.updateStatus('1', 'in_progress', technicianId: '42'), isTrue);
    expect(adapter.patchBodies, [{'status': 'IN_PROGRESS', 'technicianId': 42}]);
    expect(adapter.orderStatus, 'IN_PROGRESS');
    expect(adapter.technicianId, 42);
    expect(p.orders.first.status.name, 'inProgress');
    expect(await p.updateStatus('1', 'completed'), isTrue);
    expect(adapter.patchBodies.last, {'status': 'COMPLETED'});
    expect(adapter.patchBodies.length, 2);
  });

  test('rejected or malformed technician never produces a partial status update', () async {
    final p = MaintenanceProvider();
    adapter.rejectPatch = true;
    expect(await p.updateStatus('1', 'completed', technicianId: '42'), isFalse);
    expect(p.errorMessage, 'Invalid technician');
    expect(adapter.orderStatus, 'PENDING');
    expect(adapter.patchBodies, [{'status': 'COMPLETED', 'technicianId': 42}]);
    expect(await p.updateStatus('1', 'completed', technicianId: 'not-a-number'), isFalse);
    expect(adapter.patchBodies.length, 1);
    expect(adapter.orderStatus, 'PENDING');
  });

  testWidgets('form loads unfiltered assets without changing persisted asset filters', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final assets = AssetsProvider();
    await tester.runAsync(() => assets.loadAssets());
    assets.setSearchQuery('nothing matches');
    assets.setTypeFilter('computer');
    assets.setStatusFilter('broken');
    expect(assets.filteredAssets, isEmpty);
    final maintenance = MaintenanceProvider();
    await tester.pumpWidget(testApp(const MaintenanceFormScreen(), assets, maintenance));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButton<AssetItem>>(
      find.byType(DropdownButton<AssetItem>));
    expect(dropdown.items!.map((item) => item.value!.code).toList(),
        ['PC-1', 'PC-2', 'PR-1']);
    dropdown.onChanged!(dropdown.items!.last.value);
    await tester.pump();
    expect(tester.widget<DropdownButton<AssetItem>>(find.byType(DropdownButton<AssetItem>)).value!.code, 'PR-1');
    expect(assets.searchQuery, 'nothing matches');
    expect(assets.typeFilter, 'computer');
    expect(assets.statusFilter, 'broken');
  });

  testWidgets('asset load failure shows existing dropdown hint instead of endless spinner', (tester) async {
    adapter.rejectAssets = true;
    final assets = AssetsProvider();
    final maintenance = MaintenanceProvider();
    await tester.pumpWidget(testApp(const MaintenanceFormScreen(), assets, maintenance));
    await tester.pumpAndSettle();
    expect(find.text('Forbidden'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('pending card replaces old filter before navigation', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final assets = AssetsProvider();
    final maintenance = MaintenanceProvider();
    maintenance.setStatusFilter('completed');
    await tester.pumpWidget(testApp(const DashboardScreen(), assets, maintenance));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.pending_actions_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(MaintenanceListScreen), findsOneWidget);
    expect(maintenance.statusFilter, 'pending');
    expect(maintenance.filteredOrders.length, 1);
    expect(maintenance.filteredOrders.single.id, '6');
  });
}
