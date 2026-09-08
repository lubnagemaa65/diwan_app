import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/maintenance_order_model.dart';

class MaintenanceRepository {
  MaintenanceRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;
  final Dio _dio;

  Future<List<MaintenanceOrderModel>> fetchOrders({
    String? status,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.maintenanceOrders,
        queryParameters: {
          if (status != null && status.isNotEmpty && status != 'all') 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final list = _extractList(response.data);
      return list.map((e) => MaintenanceOrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<MaintenanceOrderModel> fetchOrderById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.maintenanceOrderById(id));
      return MaintenanceOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> createOrder(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiConstants.maintenanceOrders, data: payload);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  /// تحديث حالة الطلب (لاستخدام الفني/المدير)
  Future<void> updateOrderStatus(String id, String status, {String? technicianId}) async {
    try {
      await _dio.put(ApiConstants.maintenanceOrderById(id), data: {
        'status': status,
        if (technicianId != null) 'technicianId': technicianId,
      });
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _dio.delete(ApiConstants.maintenanceOrderById(id));
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return [];
  }
}
