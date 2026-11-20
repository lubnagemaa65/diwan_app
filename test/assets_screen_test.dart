import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/features/assets/views/asset_details_screen.dart';
import 'package:university_assets_app/features/assets/views/assets_list_screen.dart';

import 'support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnvironment env;
  setUp(() => env = TestEnvironment());
  tearDown(() => env.dispose());

  Future<void> showAssets(WidgetTester tester, {String role = 'ADMIN'}) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    env.api.role = role;
    expect(
        await tester.runAsync(() =>
            env.auth.login(email: 'test@example.com', password: 'secret123')),
        isTrue);
    await tester.pumpWidget(env.app(const AssetsListScreen()));
    await tester.pumpAndSettle();
  }

  Finder chip(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip));

  testWidgets('type and status chips combine, toggle and reset',
      (tester) async {
    await showAssets(tester);
    expect(find.text('PC-101'), findsOneWidget);
    expect(find.text('PC-202'), findsOneWidget);
    expect(find.text('PR-101'), findsOneWidget);
    await tester.tap(chip('الحواسيب'));
    await tester.pumpAndSettle();
    expect(env.assets.typeFilter, 'computer');
    expect(find.text('PR-101'), findsNothing);
    await tester.tap(chip('معطل'));
    await tester.pumpAndSettle();
    expect(env.assets.statusFilter, 'broken');
    expect(find.text('PC-202'), findsOneWidget);
    expect(find.text('PC-101'), findsNothing);
    await tester.tap(chip('معطل'));
    await tester.pumpAndSettle();
    expect(env.assets.statusFilter, 'all');
    expect(find.text('PC-101'), findsOneWidget);
    await tester.tap(chip('الطابعات'));
    await tester.pumpAndSettle();
    expect(find.text('PR-101'), findsOneWidget);
    expect(find.text('PC-101'), findsNothing);
    await tester.tap(chip('الكل'));
    await tester.pumpAndSettle();
    expect(env.assets.typeFilter, 'all');
    expect(find.text('PC-101'), findsOneWidget);
  });

  testWidgets('search is case-insensitive and can match employee names',
      (tester) async {
    await showAssets(tester);
    await tester.enterText(find.byType(TextField), 'amina');
    await tester.pumpAndSettle();
    expect(find.text('PC-101'), findsOneWidget);
    expect(find.text('PC-202'), findsNothing);
    expect(find.text('PR-101'), findsNothing);
    await tester.enterText(find.byType(TextField), 'not-found');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد أصول مطابقة'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pr-101');
    await tester.pumpAndSettle();
    expect(find.text('PR-101'), findsOneWidget);
  });

  testWidgets('load failure is visible and retry fetches the list again',
      (tester) async {
    env.api.failComputersOnce = true;
    await showAssets(tester);
    expect(find.text('اختبار خطأ تحميل الأصول'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(env.api.calls('GET', '/computers'), hasLength(2));
    expect(find.text('PC-101'), findsOneWidget);
  });

  testWidgets('delete confirmation cancels or deletes only after confirmation',
      (tester) async {
    await showAssets(tester);
    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();
    expect(find.text('هل أنت متأكد من حذف "PC-101"؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(env.api.calls('DELETE', '/computers/PC-101'), isEmpty);
    expect(find.text('PC-101'), findsOneWidget);
    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(env.api.calls('DELETE', '/computers/PC-101'), hasLength(1));
    expect(find.text('PC-101'), findsNothing);
    expect(find.text('PC-202'), findsOneWidget);
  });

  testWidgets('admin add chooser can be dismissed and a row opens details',
      (tester) async {
    await showAssets(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('إضافة حاسوب جديد'), findsOneWidget);
    expect(find.text('إضافة طابعة جديدة'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PC-101'));
    await tester.pumpAndSettle();
    expect(find.byType(AssetDetailsScreen), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
  });

  testWidgets('employee cannot see asset add, edit or delete controls',
      (tester) async {
    await showAssets(tester, role: 'EMPLOYEE');
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('تعديل'), findsNothing);
    expect(find.byTooltip('حذف'), findsNothing);
    expect(find.text('PC-101'), findsOneWidget);
  });
}
