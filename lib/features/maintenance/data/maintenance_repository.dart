import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/maintenance_order_model.dart'
    show MaintenanceOrderModel;

class MaintenanceRepository {
  /// مهم: مرّر الـ Dio المضبوط (baseUrl + توكن) وليس Dio() فارغ.
  MaintenanceRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  // الباك اند يرجع 10 عناصر فقط افتراضياً، فنطلب عدداً أكبر.
  static const int _limit = 1000;

  Future<List<MaintenanceOrderModel>> fetchOrders({
    String? status,
    String? search,
  }) async {
    try {
      final apiStatus = _statusToApi(status);
      final response = await _dio.get(
        ApiConstants.maintenanceOrders,
        queryParameters: {
          'limit': _limit,
          if (apiStatus != null) 'status': apiStatus,
          // الباك اند يبحث بكود الجهاز عبر deviceId (بحث جزئي)
          if (search != null && search.isNotEmpty) 'deviceId': search,
        },
      );
      return _extractList(response.data)
          .map((e) => MaintenanceOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<MaintenanceOrderModel> fetchOrderById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.maintenanceOrderById(id));
      return MaintenanceOrderModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// يقبل الـ payload القديم (deviceType/deviceId/problemType/description/requesterId)
  /// أو الجديد (type/problemDescription/computerId/printerId/requestedById)،
  /// ويحوّله لما يفهمه الباك اند.
  Future<void> createOrder(Map<String, dynamic> payload) async {
    final body = <String, dynamic>{};

    // نوع المشكلة: HARDWARE / SOFTWARE فقط
    final problem =
        (payload['type'] ?? payload['problemType'] ?? '').toString().trim();
    body['type'] = _problemTypeToApi(problem);

    body['problemDescription'] =
        (payload['problemDescription'] ?? payload['description'] ?? '')
            .toString()
            .trim();

    // الجهاز: إما computerId أو printerId (وليس الاثنين)
    final printerId = payload['printerId']?.toString();
    final computerId = payload['computerId']?.toString();
    final deviceId = payload['deviceId']?.toString();
    final deviceType = payload['deviceType']?.toString().toLowerCase();

    if (printerId != null && printerId.isNotEmpty) {
      body['printerId'] = printerId;
    } else if (computerId != null && computerId.isNotEmpty) {
      body['computerId'] = computerId;
    } else if (deviceId != null && deviceId.isNotEmpty) {
      body[deviceType == 'printer' ? 'printerId' : 'computerId'] = deviceId;
    } else {
      throw ApiException('يجب اختيار الجهاز.');
    }

    // requestedById = معرّف الموظف (Employee) وليس المستخدم.
    // للموظف (EMPLOYEE) يتجاهله السيرفر ويستخدم سجل الموظف المرتبط بحسابه.
    final requester = int.tryParse(
        (payload['requestedById'] ?? payload['requesterId'] ?? '').toString());
    if (requester != null) body['requestedById'] = requester;

    final tech = int.tryParse((payload['technicianId'] ?? '').toString());
    if (tech != null) body['technicianId'] = tech;

    try {
      await _dio.post(ApiConstants.maintenanceOrders, data: body);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// تحديث حالة الطلب (للفني/المدير). [technicianId] هو id المستخدم الفني.
  Future<void> updateOrderStatus(String id, String status,
      {String? technicianId}) async {
    final apiStatus = _statusToApi(status);
    if (apiStatus == null) {
      throw ApiException('حالة الطلب غير صالحة.');
    }
    final tech = int.tryParse(technicianId ?? '');
    try {
      // الباك اند يستخدم PATCH وليس PUT
      await _dio.patch(ApiConstants.maintenanceOrderById(id), data: {
        'status': apiStatus,
        if (tech != null) 'technicianId': tech,
      });
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _dio.delete(ApiConstants.maintenanceOrderById(id));
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// اقتراح تشخيص من الذكاء الاصطناعي (Gemini) للطلب.
  Future<String> fetchTriageSuggestion(String id) async {
    try {
      final response = await _dio
          .get('${ApiConstants.maintenanceOrderById(id)}/triage-suggestion');
      final data = response.data;
      return data is Map ? (data['suggestion'] ?? '').toString() : '';
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  // ===================== أدوات مساعدة =====================

  /// يحوّل اسم حالة التطبيق (pending / inProgress / completed / cancelled)
  /// إلى قيمة الباك اند. يرجّع null لـ all/فارغ.
  String? _statusToApi(String? s) {
    if (s == null || s.isEmpty || s == 'all') return null;
    switch (s.trim().toLowerCase().replaceAll('_', '')) {
      case 'pending':
        return 'PENDING';
      case 'inprogress':
        return 'IN_PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
      case 'canceled':
        return 'CANCELLED';
      default:
        return null;
    }
  }

  String _problemTypeToApi(String label) {
    final l = label.toLowerCase();
    if (l == 'برمجيات' || l == 'software') return 'SOFTWARE';
    return 'HARDWARE';
  }

  ApiException _toApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;

    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(),
          statusCode: e.response?.statusCode);
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
        return ApiException(e.message ?? 'خطأ في الاتصال',
            statusCode: e.response?.statusCode);
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
