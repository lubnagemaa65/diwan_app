import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:university_assets_app/core/constants/app_constants.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/models/activity_log_model.dart';
import 'package:university_assets_app/models/college_model.dart';
import 'package:university_assets_app/models/computer_model.dart';
import 'package:university_assets_app/models/employee_model.dart';
import 'package:university_assets_app/models/maintenance_order_model.dart'
    as maintenance_models;
// import maintenance_order_model with prefix to avoid name conflicts (e.g. MaintenanceStatus)
import 'package:university_assets_app/models/printer_model.dart';
import 'package:university_assets_app/models/user_model.dart';

Dio get _d => ApiClient.instance.dio;

/// الباك اند يعيد مصفوفة مباشرة (وليس {results: []}) ويحدّد الافتراضي بـ 10 عناصر،
/// لذلك نطلب عدداً كبيراً إلى أن نضيف ترقيم صفحات (pagination) في الواجهة.
const Map<String, dynamic> _all = {'limit': 1000};

List<Map<String, dynamic>> _asList(dynamic data) {
  final raw = data is List
      ? data
      : (data is Map && data['results'] is List
          ? data['results'] as List
          : const []);
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

Map<String, dynamic> _asMap(dynamic data) =>
    Map<String, dynamic>.from(data as Map);

// ======================= المصادقة =======================
class AuthService {
  AuthService._();

  static Future<UserModel> login(String email, String password) =>
      ApiClient.guard(() async {
        final res = await _d
            .post('/auth/login', data: {'email': email, 'password': password});
        final body = _asMap(res.data);
        await ApiClient.instance.saveTokens(_asMap(body['tokens']));
        final user = UserModel.fromJson(_asMap(body['user']));
        await ApiClient.instance.saveUserJson(jsonEncode(user.toJson()));
        return user;
      });

  /// يستعيد المستخدم المحفوظ عند فتح التطبيق (لا يوجد endpoint لـ /me في الباك اند).
  static Future<UserModel?> currentUser() async {
    if (!await ApiClient.instance.hasToken()) return null;
    final raw = await ApiClient.instance.readUserJson();
    if (raw == null) return null;
    return UserModel.fromJson(_asMap(jsonDecode(raw)));
  }

  static Future<void> logout() async {
    try {
      final rt = await ApiClient.instance.refreshToken;
      if (rt != null) await _d.post('/auth/logout', data: {'refreshToken': rt});
    } catch (_) {
      // نتجاهل أخطاء الشبكة عند تسجيل الخروج
    }
    await ApiClient.instance.clearTokens();
  }
}

// ======================= المستخدمون =======================
class UserService {
  UserService._();

  static Future<List<UserModel>> list() => ApiClient.guard(() async {
        final res = await _d.get('/users', queryParameters: _all);
        return _asList(res.data).map(UserModel.fromJson).toList();
      });

  static Future<UserModel> create({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) =>
      ApiClient.guard(() async {
        final res = await _d.post('/users', data: {
          'name': name,
          'email': email,
          'password': password,
          'role': ApiMappers.roleToApi(role),
        });
        return UserModel.fromJson(_asMap(res.data));
      });

  /// الباك اند يسمح بتعديل الاسم والبريد وكلمة المرور فقط (وليس الدور).
  static Future<UserModel> update(String id,
          {String? name, String? email, String? password}) =>
      ApiClient.guard(() async {
        final body = {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
        };
        final res = await _d.patch('/users/$id', data: body);
        return UserModel.fromJson(_asMap(res.data));
      });

  static Future<void> delete(String id) => ApiClient.guard(() async {
        await _d.delete('/users/$id');
      });
}

// ======================= الكليات =======================
class CollegeService {
  CollegeService._();

  static Future<List<CollegeModel>> list() => ApiClient.guard(() async {
        final res = await _d.get('/colleges', queryParameters: _all);
        return _asList(res.data).map(CollegeModel.fromJson).toList();
      });

  static Future<CollegeModel> create(String name) => ApiClient.guard(() async {
        final res = await _d.post('/colleges', data: {'name': name});
        return CollegeModel.fromJson(_asMap(res.data));
      });

  static Future<CollegeModel> update(String id, String name) =>
      ApiClient.guard(() async {
        final res = await _d.patch('/colleges/$id', data: {'name': name});
        return CollegeModel.fromJson(_asMap(res.data));
      });

  static Future<void> delete(String id) => ApiClient.guard(() async {
        await _d.delete('/colleges/$id');
      });
}

// ======================= الموظفون =======================
class EmployeeService {
  EmployeeService._();

  static Future<List<EmployeeModel>> list({String? collegeId}) =>
      ApiClient.guard(() async {
        final res = await _d.get('/employees', queryParameters: {
          ..._all,
          if (collegeId != null) 'collegeId': collegeId,
        });
        return _asList(res.data).map(EmployeeModel.fromJson).toList();
      });

  static Future<EmployeeModel> create(EmployeeModel e) =>
      ApiClient.guard(() async {
        final res = await _d.post('/employees', data: e.toJson());
        return EmployeeModel.fromJson(_asMap(res.data));
      });

  static Future<EmployeeModel> update(EmployeeModel e) =>
      ApiClient.guard(() async {
        final res =
            await _d.patch('/employees/${e.id}', data: e.toUpdateJson());
        return EmployeeModel.fromJson(_asMap(res.data));
      });

  static Future<void> delete(String id) => ApiClient.guard(() async {
        await _d.delete('/employees/$id');
      });
}

// ======================= الحواسيب =======================
class ComputerService {
  ComputerService._();

  static Future<List<ComputerModel>> list(
          {String? collegeId, String? search}) =>
      ApiClient.guard(() async {
        final res = await _d.get('/computers', queryParameters: {
          ..._all,
          if (collegeId != null) 'collegeId': collegeId,
          if (search != null && search.isNotEmpty) 'id': search,
        });
        return _asList(res.data).map(ComputerModel.fromJson).toList();
      });

  static Future<ComputerModel> create(ComputerModel c) =>
      ApiClient.guard(() async {
        final res = await _d.post('/computers', data: c.toJson());
        return ComputerModel.fromJson(_asMap(res.data));
      });

  /// ملاحظة: التعديل يستخدم toUpdateJson() (بدون collegeId)، لأن الباك اند
  /// لا يسمح بتغيير كلية الحاسوب بعد إنشائه — إرسالها يسبب خطأ 400.
  static Future<ComputerModel> update(ComputerModel c) =>
      ApiClient.guard(() async {
        final res =
            await _d.patch('/computers/${c.id}', data: c.toUpdateJson());
        return ComputerModel.fromJson(_asMap(res.data));
      });

  static Future<void> delete(String id) => ApiClient.guard(() async {
        await _d.delete('/computers/$id');
      });
}

// ======================= الطابعات =======================
class PrinterService {
  PrinterService._();

  static Future<List<PrinterModel>> list({String? collegeId, String? search}) =>
      ApiClient.guard(() async {
        final res = await _d.get('/printers', queryParameters: {
          ..._all,
          if (collegeId != null) 'collegeId': collegeId,
          if (search != null && search.isNotEmpty) 'id': search,
        });
        return _asList(res.data).map(PrinterModel.fromJson).toList();
      });

  static Future<PrinterModel> create(PrinterModel p) =>
      ApiClient.guard(() async {
        final res = await _d.post('/printers', data: p.toJson());
        return PrinterModel.fromJson(_asMap(res.data));
      });

  /// ملاحظة: التعديل يستخدم toUpdateJson() (بدون collegeId)، لنفس سبب الحاسوب.
  static Future<PrinterModel> update(PrinterModel p) =>
      ApiClient.guard(() async {
        final res = await _d.patch('/printers/${p.id}', data: p.toUpdateJson());
        return PrinterModel.fromJson(_asMap(res.data));
      });

  static Future<void> delete(String id) => ApiClient.guard(() async {
        await _d.delete('/printers/$id');
      });
}

// ======================= طلبات الصيانة =======================

class MaintenanceOrderService {
  MaintenanceOrderService._();

  static Future<List<maintenance_models.MaintenanceOrderModel>> list({
    maintenance_models.MaintenanceStatus? status,
    String? collegeId,
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) =>
      ApiClient.guard(() async {
        final res = await _d.get('/maintenance-orders', queryParameters: {
          ..._all,
          if (status != null)
            'status':
                maintenance_models.ApiMappers.maintenanceStatusToApi(status),
          if (collegeId != null) 'collegeId': collegeId,
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
          if (from != null) 'dateFrom': from.toIso8601String(),
          if (to != null) 'dateTo': to.toIso8601String(),
        });
        return _asList(res.data)
            .map(maintenance_models.MaintenanceOrderModel.fromJson)
            .toList();
      });

  static Future<maintenance_models.MaintenanceOrderModel> create(
          maintenance_models.MaintenanceOrderModel o) =>
      ApiClient.guard(() async {
        final res = await _d.post('/maintenance-orders', data: o.toJson());
        return maintenance_models.MaintenanceOrderModel.fromJson(
            _asMap(res.data));
      });

  static Future<maintenance_models.MaintenanceOrderModel> updateStatus(
          String id, maintenance_models.MaintenanceStatus status) =>
      ApiClient.guard(() async {
        final res = await _d.patch('/maintenance-orders/$id', data: {
          'status': maintenance_models.ApiMappers.maintenanceStatusToApi(status)
        });
        return maintenance_models.MaintenanceOrderModel.fromJson(
            _asMap(res.data));
      });

  /// [technicianUserId] هو id المستخدم الفني (User) أو null لإلغاء التعيين.
  static Future<maintenance_models.MaintenanceOrderModel> assignTechnician(
          String id, String? technicianUserId) =>
      ApiClient.guard(() async {
        final res = await _d.patch('/maintenance-orders/$id', data: {
          'technicianId': maintenance_models.ApiMappers.toInt(technicianUserId)
        });
        return maintenance_models.MaintenanceOrderModel.fromJson(
            _asMap(res.data));
      });

  static Future<void> delete(String id) => ApiClient.guard(() async {
        await _d.delete('/maintenance-orders/$id');
      });

  static Future<String> triageSuggestion(String id) =>
      ApiClient.guard(() async {
        final res = await _d.get('/maintenance-orders/$id/triage-suggestion');
        return (_asMap(res.data)['suggestion'] ?? '').toString();
      });
}

// ======================= سجل النشاطات =======================
class ActivityLogService {
  ActivityLogService._();

  static Future<List<ActivityLogModel>> list({int limit = 200}) =>
      ApiClient.guard(() async {
        final res =
            await _d.get('/activity-logs', queryParameters: {'limit': limit});
        return _asList(res.data).map(ActivityLogModel.fromJson).toList();
      });
}
