import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/features/maintenance/views/maintenance_form_screen.dart';
import 'package:university_assets_app/features/maintenance/views/maintenance_list_screen.dart';

import 'support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnvironment env;
  setUp(() => env = TestEnvironment());
  tearDown(() => env.dispose());

  Future<void> showOrders(WidgetTester tester, {String role = 'ADMIN'}) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    env.api.role = role;
    expect(
        await tester.runAsync(() =>
            env.auth.login(email: 'test@example.com', password: 'secret123')),
        isTrue);
    await tester.pumpWidget(env.app(const MaintenanceListScreen()));
    await tester.pumpAndSettle();
  }

  Finder chip(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip));

  testWidgets(
      'maintenance status filters show matching records and empty state',
      (tester) async {
    env.api.orders.add({
      'id': 3,
      'computerId': 'PC-202',
      'type': 'HARDWARE',
      'problemDescription': 'Repaired computer',
      'status': 'COMPLETED'
    });
    await showOrders(tester);
    expect(find.text('Broken screen'), findsOneWidget);
    expect(find.text('Printer software'), findsOneWidget);
    expect(find.text('Repaired computer'), findsOneWidget);
    await tester.tap(chip('قيد التنفيذ'));
    await tester.pumpAndSettle();
    expect(env.maintenance.statusFilter, 'inProgress');
    expect(find.text('Printer software'), findsOneWidget);
    expect(find.text('Broken screen'), findsNothing);
    await tester.tap(chip('مكتمل'));
    await tester.pumpAndSettle();
    expect(find.text('Repaired computer'), findsOneWidget);
    expect(find.text('Printer software'), findsNothing);
    await tester.tap(chip('ملغى'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد بيانات لعرضها'), findsOneWidget);
    await tester.tap(chip('الكل'));
    await tester.pumpAndSettle();
    expect(find.text('Broken screen'), findsOneWidget);
    expect(find.text('Printer software'), findsOneWidget);
  });

  testWidgets(
      'canceling deletion makes no request; confirmation removes the order',
      (tester) async {
    await showOrders(tester);
    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();
    expect(find.text('هل أنت متأكد من حذف الطلب رقم 1؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(env.api.calls('DELETE', '/maintenance-orders/1'), isEmpty);
    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(env.api.calls('DELETE', '/maintenance-orders/1'), hasLength(1));
    expect(find.text('Broken screen'), findsNothing);
    expect(find.text('Printer software'), findsOneWidget);
  });

  testWidgets(
      'employee can open creation form but cannot edit or delete orders',
      (tester) async {
    await showOrders(tester, role: 'EMPLOYEE');
    expect(find.byTooltip('حذف'), findsNothing);
    expect(find.byTooltip('تعديل الحالة'), findsNothing);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(MaintenanceFormScreen), findsOneWidget);
    await tester.ensureVisible(find.text('إرسال الطلب'));
    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('اختر الجهاز'), findsWidgets);
    expect(env.api.calls('POST', '/maintenance-orders'), isEmpty);
  });

  testWidgets('technician can manage orders but does not see add button',
      (tester) async {
    await showOrders(tester, role: 'TECHNICIAN');
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('حذف'), findsNWidgets(2));
    expect(find.byTooltip('تعديل الحالة'), findsNWidgets(2));
  });
}
