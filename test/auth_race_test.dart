import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/core/storage/secure_storage_service.dart';
import 'package:university_assets_app/features/auth/providers/auth_provider.dart';

class LocalHttpOverrides extends HttpOverrides {}

class Adapter implements HttpClientAdapter {
  Completer<void>? loginGate;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancelled) async {
    if (options.path == '/auth/login') {
      if (loginGate != null) await loginGate!.future;
      return response(200, {'user': {'name': 'A', 'email': 'a@a.com', 'role':'EMPLOYEE'}, 'tokens': {'access': {'token': 'access'}, 'refresh': {'token': 'refresh'}}});
    }
    if (options.path == '/auth/logout') return response(200, {});
    return response(401, {'message':'unauthorized'});
  }
  ResponseBody response(int status, Object data) => ResponseBody.fromString(jsonEncode(data), status, headers: {Headers.contentTypeHeader:['application/json']});
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This test uses a real loopback HTTP listener. Refuse to run before any
  // network request unless the application URL is explicitly set to it.
  if (ApiClient.baseUrl != 'http://127.0.0.1:41899/v1') {
    throw StateError('Run with --dart-define=API_BASE_URL=http://127.0.0.1:41899/v1');
  }
  late HttpServer server;
  late int refreshStatus;
  late Adapter adapter;
  late AuthProvider auth;
  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 41899);
    server.listen((req) async {
      await req.drain<void>();
      req.response.statusCode = refreshStatus;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'message': refreshStatus == 401 ? 'bad refresh' : 'service unavailable'}));
      await req.response.close();
    });
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    adapter = Adapter();
    ApiClient.instance.dio.httpClientAdapter = adapter;
    auth = AuthProvider();
    refreshStatus = 401;
  });
  tearDown(() => auth.dispose());
  tearDownAll(() => server.close(force: true));
  test('401 refresh rejects and removes session data', () async {
    expect(await auth.login(email:'a@a.com', password:'secret'), true);
    try { await HttpOverrides.runWithHttpOverrides(() => ApiClient.instance.dio.get('/assets'), LocalHttpOverrides()); } on DioException catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(auth.isAuthenticated, false);
    expect(await ApiClient.instance.hasToken(), false);
    expect(await SecureStorageService.instance.getUserProfile(), isNull);
  });
  test('503 refresh reports server failure and keeps session', () async {
    refreshStatus = 503;
    expect(await auth.login(email:'a@a.com', password:'secret'), true);
    DioException? failure;
    try { await HttpOverrides.runWithHttpOverrides(() => ApiClient.instance.dio.get('/assets'), LocalHttpOverrides()); } on DioException catch (e) { failure = e; }
    expect(failure?.response?.statusCode, 503);
    expect(auth.isAuthenticated, true);
    expect(await ApiClient.instance.hasToken(), true);
    expect(await SecureStorageService.instance.getUserProfile(), isNotNull);
  });
  test('logout during late login cannot resurrect session', () async {
    adapter.loginGate = Completer<void>();
    final login = auth.login(email:'a@a.com', password:'secret');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final logout = auth.logout();
    adapter.loginGate!.complete();
    expect(await login, false);
    await logout;
    expect(auth.isAuthenticated, false);
    expect(await ApiClient.instance.hasToken(), false);
    expect(await SecureStorageService.instance.getUserProfile(), isNull);
  });
  test('connection failure keeps session and propagates network error', () async {
    await server.close(force: true);
    expect(await auth.login(email:'a@a.com', password:'secret'), true);
    DioException? failure;
    try { await HttpOverrides.runWithHttpOverrides(() => ApiClient.instance.dio.get('/assets'), LocalHttpOverrides()); } on DioException catch (e) { failure = e; }
    expect(failure?.type, anyOf(DioExceptionType.connectionError, DioExceptionType.connectionTimeout));
    expect(auth.isAuthenticated, true);
    expect(await ApiClient.instance.hasToken(), true);
    expect(await SecureStorageService.instance.getUserProfile(), isNotNull);
  });
}
