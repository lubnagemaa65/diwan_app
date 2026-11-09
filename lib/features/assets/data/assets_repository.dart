import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/computer_model.dart';
import '../../../models/printer_model.dart';

class AssetsRepository {
  final Dio _dio;

  /// مهم: مرّر هنا الـ Dio المضبوط (baseUrl + توكن)، وليس Dio() فارغ،
  /// وإلا لن تصل الطلبات للسيرفر ولن يُرسل التوكن.
  AssetsRepository({required Dio dio}) : _dio = dio;

  // الباك اند يرجع مصفوفة مباشرة، والافتراضي 10 عناصر فقط، لذلك نطلب عدداً أكبر.
  static const int _limit = 1000;

  // ===================== القراءة =====================

  Future<List<ComputerModel>> fetchComputers({
    String? search,
    String? type,
    String? status,
    String? collegeId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.computers,
        queryParameters: {
          'limit': _limit,
          // الباك اند يبحث بالمعرّف (الكود) عبر الباراميتر id
          if (search != null && search.isNotEmpty) 'id': search,
          if (_isSet(type)) 'type': type!.toUpperCase(),
          if (_isSet(status) && _statusToApi(status) != null)
            'status': _statusToApi(status),
          if (_isSet(collegeId)) 'collegeId': collegeId,
        },
      );
      return _extractList(response.data)
          .map((e) => ComputerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<List<PrinterModel>> fetchPrinters({
    String? search,
    String? status,
    String? collegeId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.printers,
        queryParameters: {
          'limit': _limit,
          if (search != null && search.isNotEmpty) 'id': search,
          if (_isSet(status) && _statusToApi(status) != null)
            'status': _statusToApi(status),
          if (_isSet(collegeId)) 'collegeId': collegeId,
        },
      );
      return _extractList(response.data)
          .map((e) => PrinterModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<ComputerModel> fetchComputerById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.computerById(id));
      return ComputerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<PrinterModel> fetchPrinterById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.printerById(id));
      return PrinterModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  // ===================== الإضافة والتعديل =====================

  Future<void> createComputer(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiConstants.computers,
          data: _computerBody(payload, forCreate: true));
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> updateComputer(String id, Map<String, dynamic> payload) async {
    try {
      // الباك اند يستخدم PATCH وليس PUT
      await _dio.patch(ApiConstants.computerById(id),
          data: _computerBody(payload, forCreate: false));
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> createPrinter(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiConstants.printers,
          data: _printerBody(payload, forCreate: true));
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> updatePrinter(String id, Map<String, dynamic> payload) async {
    try {
      await _dio.patch(ApiConstants.printerById(id),
          data: _printerBody(payload, forCreate: false));
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  // ===================== الحذف =====================

  Future<void> deleteComputer(String id) async {
    try {
      await _dio.delete(ApiConstants.computerById(id));
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> deletePrinter(String id) async {
    try {
      await _dio.delete(ApiConstants.printerById(id));
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  // ===================== بناء أجسام الطلبات =====================
  // الباك اند (Joi) يرفض أي حقل غير معروف، لذلك نرسل الحقول المسموحة فقط
  // ونحوّل الأسماء والقيم لما يفهمه (code يُولَّد في السيرفر ولا يُرسل أبداً).

  Map<String, dynamic> _computerBody(Map<String, dynamic> p,
      {required bool forCreate}) {
    final body = <String, dynamic>{};

    final type = p['type']?.toString().trim().toLowerCase();
    if (type == 'laptop' || type == 'محمول') body['type'] = 'LAPTOP';
    if (type == 'desktop' || type == 'مكتبي') body['type'] = 'DESKTOP';

    _put(body, 'processor', p['processor']);
    _put(body, 'motherboard', p['motherboard']);
    _put(body, 'hardDiskType',
        (p['hardDiskType'] ?? p['diskType'])?.toString().toUpperCase());
    _put(body, 'hardDiskSpace', p['hardDiskSpace'] ?? p['diskSize']);
    _put(body, 'ramType', p['ramType'] ?? p['ram']);
    _put(body, 'graphicsCard', p['graphicsCard']?.toString().toUpperCase());
    _put(body, 'status', _statusToApi(p['status']));

    // employeeId يقبل null (فك الربط)، فنرسله إن كان المفتاح موجوداً
    if (p.containsKey('employeeId')) {
      body['employeeId'] = _toInt(p['employeeId']);
    }
    // الكلية تُرسل عند الإنشاء فقط (التعديل لا يقبلها)
    if (forCreate) body['collegeId'] = _toInt(p['collegeId']);

    return body;
  }

  Map<String, dynamic> _printerBody(Map<String, dynamic> p,
      {required bool forCreate}) {
    final body = <String, dynamic>{};
    _put(body, 'type', p['type']);
    _put(body, 'status', _statusToApi(p['status']));
    if (forCreate) body['collegeId'] = _toInt(p['collegeId']);
    return body;
  }

  // ===================== أدوات مساعدة =====================

  bool _isSet(String? v) => v != null && v.isNotEmpty && v != 'all';

  void _put(Map<String, dynamic> body, String key, dynamic value) {
    if (value != null && value.toString().trim().isNotEmpty) {
      body[key] = value is String ? value.trim() : value;
    }
  }

  int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

  /// يحوّل حالة التطبيق إلى ACTIVE / DISABLED / MAINTENANCE
  String? _statusToApi(dynamic v) {
    if (v == null) return null;
    if (v is AssetStatus) return ApiMappers.assetStatusToApi(v);
    switch (v.toString().trim().toLowerCase()) {
      case 'active':
      case 'enabled':
        return 'ACTIVE';
      case 'broken':
      case 'disabled':
      case 'out_of_service':
        return 'DISABLED';
      case 'undermaintenance':
      case 'under_maintenance':
      case 'maintenance':
        return 'MAINTENANCE';
      default:
        return null;
    }
  }

  ApiException _toApiException(DioException e) {
    if (e.error is ApiException) {
      return e.error as ApiException;
    }

    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(
        data['message'].toString(),
        statusCode: e.response?.statusCode,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
          'تعذّر الاتصال بالخادم، تحقق من الشبكة وعنوان الخادم',
          statusCode: e.response?.statusCode,
        );
      default:
        return ApiException(
          'حدث خطأ غير متوقع',
          statusCode: e.response?.statusCode,
        );
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return [];
  }
}
