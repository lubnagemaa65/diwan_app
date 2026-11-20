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
    _rejectUnsupportedFields(p, forCreate: forCreate, isPrinter: false);

    final type = p['type']?.toString().trim().toLowerCase();
    if (type == 'laptop' || type == 'محمول') body['type'] = 'LAPTOP';
    if (type == 'desktop' || type == 'مكتبي') body['type'] = 'DESKTOP';
    if (p['type'] != null && !body.containsKey('type')) {
      throw ApiException('نوع الحاسوب غير صالح.');
    }

    _put(body, 'processor', p['processor']);
    _put(body, 'motherboard', p['motherboard']);
    _put(body, 'hardDiskType',
        (p['hardDiskType'] ?? p['diskType'])?.toString().toUpperCase());
    _put(body, 'hardDiskSpace', p['hardDiskSpace'] ?? p['diskSize']);
    _put(body, 'ramType', p['ramType'] ?? p['ram']);
    _put(body, 'graphicsCard', p['graphicsCard']?.toString().toUpperCase());
    _put(body, 'status', _statusToApi(p['status']));
    if (body.containsKey('hardDiskType') &&
        !['SATA', 'IDE'].contains(body['hardDiskType'])) {
      throw ApiException('نوع القرص غير مدعوم؛ يقبل الخادم SATA أو IDE.');
    }
    if (body.containsKey('graphicsCard') &&
        !['INTEGRATED', 'SEPARATE'].contains(body['graphicsCard'])) {
      throw ApiException('نوع بطاقة الرسوميات غير صالح.');
    }

    // employeeId يقبل null (فك الربط)، فنرسله إن كان المفتاح موجوداً
    if (p.containsKey('employeeId')) {
      body['employeeId'] = p['employeeId'] == null
          ? null
          : _requiredInt(p['employeeId'], 'الموظف');
    }
    // الكلية تُرسل عند الإنشاء فقط (التعديل لا يقبلها)
    if (forCreate) {
      body['collegeId'] = _requiredInt(p['collegeId'], 'الكلية');
      if (!body.containsKey('motherboard') ||
          !body.containsKey('graphicsCard')) {
        throw ApiException(
          'تعذّر إنشاء الحاسوب: يتطلب الخادم اللوحة الأم وبطاقة الرسوميات، وهما غير متاحتين في هذا النموذج.',
        );
      }
      for (final field in [
        'type',
        'processor',
        'hardDiskType',
        'hardDiskSpace',
        'ramType'
      ]) {
        if (!body.containsKey(field)) {
          throw ApiException('يرجى إكمال بيانات الحاسوب المطلوبة.');
        }
      }
    }

    return body;
  }

  Map<String, dynamic> _printerBody(Map<String, dynamic> p,
      {required bool forCreate}) {
    final body = <String, dynamic>{};
    _rejectUnsupportedFields(p, forCreate: forCreate, isPrinter: true);
    _put(body, 'type', p['type']);
    _put(body, 'status', _statusToApi(p['status']));
    if (forCreate) {
      body['collegeId'] = _requiredInt(p['collegeId'], 'الكلية');
      if (!body.containsKey('type')) {
        throw ApiException('يرجى اختيار نوع الطابعة.');
      }
    }
    return body;
  }

  // ===================== أدوات مساعدة =====================

  void _rejectUnsupportedFields(Map<String, dynamic> payload,
      {required bool forCreate, required bool isPrinter}) {
    if (payload['code']?.toString().trim().isNotEmpty == true) {
      throw ApiException('يُولّد الخادم معرّف الأصل ولا يقبل تعديله.');
    }
    if (!forCreate && payload.containsKey('collegeId')) {
      throw ApiException('لا يدعم الخادم تغيير كلية الأصل بعد إنشائه.');
    }
    if (isPrinter && payload['employeeId'] != null) {
      throw ApiException('لا يدعم الخادم ربط الطابعة بموظف.');
    }
  }

  bool _isSet(String? v) => v != null && v.isNotEmpty && v != 'all';

  void _put(Map<String, dynamic> body, String key, dynamic value) {
    if (value != null && value.toString().trim().isNotEmpty) {
      body[key] = value is String ? value.trim() : value;
    }
  }

  int _requiredInt(dynamic value, String label) {
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) throw ApiException('معرّف $label غير صالح.');
    return parsed;
  }

  /// يحوّل حالة التطبيق إلى ACTIVE / DISABLED / MAINTENANCE
  String? _statusToApi(dynamic v) {
    if (v == null) return null;
    if (v is AssetStatus) {
      if (v == AssetStatus.unknown) {
        throw ApiException('حالة الأصل غير معروفة.');
      }
      return ApiMappers.assetStatusToApi(v);
    }
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
        throw ApiException('حالة الأصل غير معروفة.');
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
    throw ApiException('استجابة قائمة الأصول غير صالحة.');
  }
}
