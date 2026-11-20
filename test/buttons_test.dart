import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/core/widgets/custom_button.dart';
import 'package:university_assets_app/features/colleges/views/colleges_list_screen.dart';

import 'support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnvironment env;
  setUp(() => env = TestEnvironment());
  tearDown(() => env.dispose());

  testWidgets('custom button calls callback and is disabled while loading',
      (tester) async {
    var count = 0;
    Widget app(bool loading) => MaterialApp(
            home: Scaffold(
                body: CustomButton(
          label: 'Submit',
          onPressed: () => count++,
          isLoading: loading,
        )));
    await tester.pumpWidget(app(false));
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(count, 1);
    await tester.pumpWidget(app(true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(count, 1);
  });

  testWidgets('college add validates input and submits trimmed name',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.app(const CollegesListScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة كلية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    expect(env.api.calls('POST', '/colleges'), isEmpty);
    await tester.enterText(find.byType(TextFormField), '  Science  ');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    final request = env.api.calls('POST', '/colleges').single;
    final body = request.data is String
        ? jsonDecode(request.data as String)
        : request.data;
    expect(body, {'name': 'Science'});
    expect(find.text('Science'), findsOneWidget);
  });

  testWidgets('college deletion requires confirmation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.app(const CollegesListScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(env.api.calls('DELETE', '/colleges/7'), isEmpty);
    await tester.tap(find.byTooltip('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(env.api.calls('DELETE', '/colleges/7'), hasLength(1));
    expect(find.text('Engineering'), findsNothing);
    expect(find.text('لا توجد كليات مضافة بعد'), findsOneWidget);
  });
}
