import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:university_assets_app/core/localization/app_localizations.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/features/assets/providers/assets_provider.dart';
import 'package:university_assets_app/features/auth/providers/auth_provider.dart';
import 'package:university_assets_app/features/colleges/providers/colleges_provider.dart';
import 'package:university_assets_app/features/employees/providers/employees_provider.dart';
import 'package:university_assets_app/features/maintenance/providers/maintenance_provider.dart';
import 'package:university_assets_app/features/users/providers/users_provider.dart';

/// In-memory adapter. Unknown calls fail locally; no request can reach a server.
class TestApi implements HttpClientAdapter {
  String role = 'ADMIN';
  bool rejectLogin = false;
  bool failComputersOnce = false;
  final requests = <RequestOptions>[];
  final computers = <Map<String, dynamic>>[
    {
      'id': 'PC-101',
      'type': 'DESKTOP',
      'status': 'ACTIVE',
      'employee': {'firstName': 'Amina', 'lastName': 'Saleh'},
      'college': {'name': 'Engineering'}
    },
    {
      'id': 'PC-202',
      'type': 'LAPTOP',
      'status': 'DISABLED',
      'employee': {'firstName': 'Omar', 'lastName': 'Ali'}
    },
  ];
  final printers = <Map<String, dynamic>>[
    {'id': 'PR-101', 'type': 'Laser', 'status': 'MAINTENANCE'},
  ];
  final orders = <Map<String, dynamic>>[
    {
      'id': 1,
      'computerId': 'PC-101',
      'type': 'HARDWARE',
      'problemDescription': 'Broken screen',
      'status': 'PENDING'
    },
    {
      'id': 2,
      'printerId': 'PR-101',
      'type': 'SOFTWARE',
      'problemDescription': 'Printer software',
      'status': 'IN_PROGRESS'
    },
  ];
  final colleges = <Map<String, dynamic>>[
    {'id': 7, 'name': 'Engineering'},
  ];

  List<RequestOptions> calls(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path).toList();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final method = options.method;
    final path = options.path;
    var status = 200;
    Object data;
    if (method == 'POST' && path == '/auth/login') {
      if (rejectLogin) {
        status = 401;
        data = {'message': 'بيانات الدخول غير صحيحة'};
      } else {
        data = {
          'user': {
            'name': 'Test User',
            'email': 'test@example.com',
            'role': role
          },
          'tokens': {
            'access': {'token': 'test-access-token'},
            'refresh': {'token': 'test-refresh-token'}
          }
        };
      }
    } else if (method == 'POST' && path == '/auth/forgot-password') {
      data = {'ok': true};
    } else if (method == 'POST' && path == '/auth/logout') {
      data = {'ok': true};
    } else if (method == 'GET' && path == '/computers') {
      if (failComputersOnce) {
        failComputersOnce = false;
        status = 500;
        data = {'message': 'اختبار خطأ تحميل الأصول'};
      } else {
        data = computers;
      }
    } else if (method == 'GET' && path == '/printers') {
      data = printers;
    } else if (method == 'GET' && path == '/maintenance-orders') {
      data = orders;
    } else if (method == 'GET' && path == '/colleges') {
      data = colleges;
    } else if (method == 'GET' &&
        (path == '/activity-logs' ||
            path == '/users' ||
            path == '/employees')) {
      data = [];
    } else if (method == 'DELETE' && path.startsWith('/computers/')) {
      computers.removeWhere(
          (item) => item['id'] == path.substring('/computers/'.length));
      data = {'ok': true};
    } else if (method == 'DELETE' && path.startsWith('/maintenance-orders/')) {
      orders.removeWhere((item) =>
          item['id'].toString() ==
          path.substring('/maintenance-orders/'.length));
      data = {'ok': true};
    } else if (method == 'DELETE' && path.startsWith('/colleges/')) {
      colleges.removeWhere((item) =>
          item['id'].toString() == path.substring('/colleges/'.length));
      data = {'ok': true};
    } else if (method == 'POST' && path == '/colleges') {
      final body = options.data is String
          ? jsonDecode(options.data as String)
          : options.data;
      colleges.add({'id': 8, 'name': body['name']});
      data = {'ok': true};
    } else {
      // A fail-closed adapter makes accidental real-network access impossible.
      status = 599;
      data = {'message': 'Unexpected test request: $method $path'};
    }
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

class TestEnvironment {
  TestEnvironment() {
    FlutterSecureStorage.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    api = TestApi();
    ApiClient.instance.dio.httpClientAdapter = api;
    ApiClient.instance.activateSession();
    auth = AuthProvider();
    assets = AssetsProvider();
    maintenance = MaintenanceProvider();
    colleges = CollegesProvider();
  }

  late final TestApi api;
  late final AuthProvider auth;
  late final AssetsProvider assets;
  late final MaintenanceProvider maintenance;
  late final CollegesProvider colleges;
  final locale = LocaleProvider();

  Widget app(Widget home) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AssetsProvider>.value(value: assets),
          ChangeNotifierProvider<MaintenanceProvider>.value(value: maintenance),
          ChangeNotifierProvider<CollegesProvider>.value(value: colleges),
          ChangeNotifierProvider<EmployeesProvider>(
              create: (_) => EmployeesProvider()),
          ChangeNotifierProvider<UsersProvider>(create: (_) => UsersProvider()),
          ChangeNotifierProvider<LocaleProvider>.value(value: locale),
        ],
        child: Consumer<LocaleProvider>(
          builder: (_, provider, __) => MaterialApp(
            locale: provider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: home,
          ),
        ),
      );

  void dispose() {
    auth.dispose();
    assets.dispose();
    maintenance.dispose();
    colleges.dispose();
    locale.dispose();
    ApiClient.onSessionExpired = null;
  }
}
