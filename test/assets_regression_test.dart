import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/core/constants/app_constants.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/features/assets/data/assets_repository.dart';
import 'package:university_assets_app/features/assets/views/assets_list_screen.dart';
import 'package:university_assets_app/features/assets/views/computer_form_screen.dart';
import 'package:university_assets_app/features/assets/views/printer_form_screen.dart';
import 'package:university_assets_app/features/assets/views/asset_details_screen.dart';
import 'support/test_harness.dart';

class MutationApi extends TestApi {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    if ((o.method == 'PATCH' || o.method == 'POST') && (o.path.startsWith('/computers') || o.path.startsWith('/printers'))) {
      requests.add(o);
      return ResponseBody.fromString('{}', 200, headers: {Headers.contentTypeHeader: ['application/json']});
    }
    return super.fetch(o, body, cancel);
  }
}

dynamic decoded(dynamic data) => data is String ? jsonDecode(data) : data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('repository validates status, optional ids and unsupported input before any network call', () async {
    final api = MutationApi();
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/v1'))..httpClientAdapter = api;
    final repo = AssetsRepository(dio: dio);
    await repo.updateComputer('PC-101', {'status': AssetStatus.underMaintenance});
    await repo.updatePrinter('PR-101', {'status': 'broken'});
    expect(decoded(api.calls('PATCH', '/computers/PC-101').single.data), {'status': 'MAINTENANCE'});
    expect(decoded(api.calls('PATCH', '/printers/PR-101').single.data), {'status': 'DISABLED'});
    final n = api.requests.length;
    await expectLater(repo.updateComputer('PC-101', {'status': AssetStatus.unknown}), throwsA(isA<ApiException>()));
    await expectLater(repo.updateComputer('PC-101', {'employeeId': 'invalid'}), throwsA(isA<ApiException>()));
    await expectLater(repo.updateComputer('PC-101', {'diskType': 'SSD'}), throwsA(isA<ApiException>()));
    await expectLater(repo.createComputer({'collegeId': '7', 'type': 'desktop'}), throwsA(isA<ApiException>()));
    await expectLater(repo.createPrinter({'collegeId': '7', 'type': 'ليزر', 'employeeId': '4'}), throwsA(isA<ApiException>()));
    expect(api.requests.length, n);
  });
  test('list filters and mutation completion notification', () async {
    final env = TestEnvironment();
    final api = MutationApi(); ApiClient.instance.dio.httpClientAdapter = api;
    await env.assets.loadAssets();
    env.assets.setStatusFilter('broken');
    expect(env.assets.filteredAssets.length, 1);
    final states = <bool>[]; env.assets.addListener(() => states.add(env.assets.isSubmitting));
    expect(await env.assets.updatePrinter('PR-101', {'status': 'active'}), isTrue);
    expect(states.first, isTrue);
    expect(states.last, isFalse);
    env.dispose();
  });
  testWidgets('technician asset controls stay visible and explain server permissions', (t) async {
    final env = TestEnvironment(); env.api.role = 'TECHNICIAN';
    await t.runAsync(() => env.auth.login(email: 'test@example.com', password: 'secret123'));
    await t.pumpWidget(env.app(const AssetsListScreen())); await t.pumpAndSettle();
    for (final tooltip in ['تحديث حالة الصيانة', 'تعديل', 'حذف']) {
      expect(find.byTooltip(tooltip), findsWidgets);
      await t.tap(find.byTooltip(tooltip).first); await t.pump();
      expect(find.textContaining('متاح للمدير فقط'), findsOneWidget);
      await t.pump(const Duration(seconds: 5)); await t.pumpAndSettle();
    }
    expect(env.api.requests.where((r) => r.method == 'PATCH' || r.method == 'DELETE'), isEmpty);
    await t.pumpWidget(const SizedBox()); env.dispose();
  });
  testWidgets('administrator status action sends MAINTENANCE', (t) async {
    final env = TestEnvironment(); final api = MutationApi(); ApiClient.instance.dio.httpClientAdapter = api;
    await t.runAsync(() => env.auth.login(email: 'test@example.com', password: 'secret123'));
    await t.pumpWidget(env.app(const AssetsListScreen())); await t.pumpAndSettle();
    await t.tap(find.byTooltip('تحديث حالة الصيانة').first); await t.pumpAndSettle();
    await t.tap(find.text('underMaintenance')); await t.pumpAndSettle();
    await t.tap(find.text('حفظ')); await t.pumpAndSettle();
    expect(decoded(api.calls('PATCH', '/computers/PC-101').single.data), {'status': 'MAINTENANCE'});
    await t.pumpWidget(const SizedBox()); env.dispose();
  });
  testWidgets('computer create explains missing required backend fields without posting', (t) async {
    final env = TestEnvironment(); await t.runAsync(() => env.auth.login(email: 'test@example.com', password: 'secret123'));
    await t.pumpWidget(env.app(const ComputerFormScreen())); await t.pumpAndSettle();
    await t.ensureVisible(find.text('إضافة')); await t.tap(find.text('إضافة')); await t.pump();
    expect(find.textContaining('اللوحة الأم وبطاقة الرسوميات'), findsOneWidget);
    expect(env.api.calls('POST', '/computers'), isEmpty);
    await t.pumpWidget(const SizedBox()); env.dispose();
  });
  testWidgets('printer edit preserves a nonstandard current type while options load', (t) async {
    final env = TestEnvironment(); await t.runAsync(() => env.auth.login(email: 'test@example.com', password: 'secret123'));
    await t.runAsync(() => env.assets.loadAssets()); final printer = env.assets.filteredAssets.last.printer!;
    await t.pumpWidget(env.app(PrinterFormScreen(existing: printer))); await t.pumpAndSettle();
    expect(find.text('Laser'), findsOneWidget); expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox()); env.dispose();
  });
  testWidgets('technician maintenance button explains missing requester input', (t) async {
    final env = TestEnvironment(); env.api.role = 'TECHNICIAN';
    await t.runAsync(() => env.auth.login(email: 'test@example.com', password: 'secret123'));
    await t.runAsync(() => env.assets.loadAssets()); final asset = env.assets.filteredAssets.first;
    await t.pumpWidget(env.app(AssetDetailsScreen(asset: asset))); await t.pumpAndSettle();
    await t.ensureVisible(find.byIcon(Icons.build_outlined)); await t.tap(find.byIcon(Icons.build_outlined)); await t.pump();
    expect(find.textContaining('مقدّم الطلب للفني'), findsOneWidget);
    await t.pumpWidget(const SizedBox()); env.dispose();
  });
}
