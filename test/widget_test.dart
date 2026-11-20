import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/features/auth/providers/auth_provider.dart';
import 'package:university_assets_app/features/auth/views/forgot_password_screen.dart';
import 'package:university_assets_app/features/auth/views/login_screen.dart';
import 'package:university_assets_app/features/shared/views/main_navigation_screen.dart';

import 'support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnvironment env;

  setUp(() => env = TestEnvironment());
  tearDown(() => env.dispose());

  Future<void> showLogin(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpWidget(env.app(const LoginScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> finishRequest(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await tester.pumpAndSettle();
  }

  Future<void> enterCredentials(
      WidgetTester tester, String email, String password) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  testWidgets(
      'empty form validates both fields without sending a login request',
      (tester) async {
    await showLogin(tester);
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);
    expect(env.api.calls('POST', '/auth/login'), isEmpty);
  });

  testWidgets('invalid email and short password do not reach the API',
      (tester) async {
    await showLogin(tester);
    await enterCredentials(tester, 'not-an-email', '123');
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();
    expect(find.text('يرجى إدخال بريد إلكتروني صحيح'), findsOneWidget);
    expect(find.text('يجب ألا تقل كلمة المرور عن 6 أحرف'), findsOneWidget);
    expect(env.api.calls('POST', '/auth/login'), isEmpty);
  });

  testWidgets('password visibility button toggles obscuring', (tester) async {
    await showLogin(tester);
    TextField passwordField() =>
        tester.widget<TextField>(find.byType(TextField).at(1));
    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(passwordField().obscureText, isTrue);
  });

  testWidgets('failed login shows the server message and stays on login',
      (tester) async {
    env.api.rejectLogin = true;
    await showLogin(tester);
    await enterCredentials(tester, 'test@example.com', 'secret123');
    await tester.tap(find.text('تسجيل الدخول'));
    await finishRequest(tester);
    expect(find.text('بيانات الدخول غير صحيحة'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(env.auth.status, AuthStatus.unauthenticated);
    expect(env.api.calls('POST', '/auth/login'), hasLength(1));
  });

  testWidgets('successful login sends trimmed email and opens main navigation',
      (tester) async {
    await showLogin(tester);
    await enterCredentials(tester, '  test@example.com  ', 'secret123');
    await tester.tap(find.text('تسجيل الدخول'));
    await finishRequest(tester);
    final request = env.api.calls('POST', '/auth/login').single;
    final body = request.data is String
        ? jsonDecode(request.data as String)
        : request.data;
    expect(body, {'email': 'test@example.com', 'password': 'secret123'});
    expect(env.auth.isAuthenticated, isTrue);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('أهلًا بك Test User 👋'), findsOneWidget);
  });

  testWidgets('forgot-password flow validates, sends and returns to login',
      (tester) async {
    await showLogin(tester);
    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.tap(find.text('إرسال رابط الاستعادة'));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    expect(env.api.calls('POST', '/auth/forgot-password'), isEmpty);
    await tester.enterText(find.byType(TextFormField), ' test@example.com ');
    await tester.tap(find.text('إرسال رابط الاستعادة'));
    await finishRequest(tester);
    final request = env.api.calls('POST', '/auth/forgot-password').single;
    final body = request.data is String
        ? jsonDecode(request.data as String)
        : request.data;
    expect(body, {'email': 'test@example.com'});
    expect(find.text('تم إرسال رابط الاستعادة إلى بريدك الإلكتروني'),
        findsOneWidget);
    await tester.tap(find.text('العودة لتسجيل الدخول'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
