import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/features/assets/views/assets_list_screen.dart';
import 'package:university_assets_app/features/auth/views/login_screen.dart';
import 'package:university_assets_app/features/colleges/views/colleges_list_screen.dart';
import 'package:university_assets_app/features/maintenance/views/maintenance_list_screen.dart';
import 'package:university_assets_app/features/shared/views/admin_management_screen.dart';
import 'package:university_assets_app/features/shared/views/main_navigation_screen.dart';
import 'package:university_assets_app/features/shared/views/profile_screen.dart';
import 'package:university_assets_app/features/shared/views/splash_screen.dart';

import 'support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnvironment env;
  setUp(() => env = TestEnvironment());
  tearDown(() => env.dispose());

  Future<void> showNavigation(WidgetTester tester, String role) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    env.api.role = role;
    expect(
        await tester.runAsync(() =>
            env.auth.login(email: 'test@example.com', password: 'secret123')),
        isTrue);
    await tester.pumpWidget(env.app(const MainNavigationScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, int index) async {
    await tester.tap(find.byType(NavigationDestination).at(index));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index);
  }

  testWidgets('no saved token routes splash to login without real network',
      (tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpWidget(env.app(const SplashScreen()));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(env.api.requests, isEmpty);
  });

  testWidgets('saved token and profile route splash to navigation',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'fake-token',
      'user_profile':
          '{"name":"Saved User","email":"saved@example.com","role":"employee","token":"fake-token"}',
    });
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpWidget(env.app(const SplashScreen()));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(env.auth.currentUser?.name, 'Saved User');
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });

  testWidgets('admin can switch tabs and navigate into college management',
      (tester) async {
    await showNavigation(tester, 'ADMIN');
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await select(tester, 1);
    expect(find.byType(AssetsListScreen), findsOneWidget);
    await select(tester, 2);
    expect(find.byType(MaintenanceListScreen), findsOneWidget);
    await select(tester, 3);
    expect(find.byType(AdminManagementScreen), findsOneWidget);
    await tester.tap(find.text('الكليات'));
    await tester.pumpAndSettle();
    expect(find.byType(CollegesListScreen), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminManagementScreen), findsOneWidget);
    await select(tester, 4);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('employee has no admin destination and can change locale',
      (tester) async {
    await showNavigation(tester, 'EMPLOYEE');
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('الإدارة'), findsNothing);
    await select(tester, 3);
    expect(find.text('الإعدادات'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(env.locale.locale.languageCode, 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('logout confirmation can be cancelled then accepted',
      (tester) async {
    await showNavigation(tester, 'EMPLOYEE');
    await select(tester, 3);
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(env.auth.isAuthenticated, isTrue);
    expect(env.api.calls('POST', '/auth/logout'), isEmpty);
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    await tester.tap(find
        .descendant(
            of: find.byType(AlertDialog), matching: find.text('تسجيل الخروج'))
        .last);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await tester.pumpAndSettle();
    expect(env.api.calls('POST', '/auth/logout'), hasLength(1));
    expect(env.auth.isAuthenticated, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
