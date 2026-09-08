import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/maintenance_order_model.dart';
import '../data/maintenance_repository.dart';

enum LoadStatus { initial, loading, loaded, error }

class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider({MaintenanceRepository? repository})
      : _repository = repository ?? MaintenanceRepository();

  final MaintenanceRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<MaintenanceOrderModel> _orders = [];
  String _errorMessage = '';
  String _statusFilter = 'all';
  bool _isSubmitting = false;

  LoadStatus get status => _status;
  List<MaintenanceOrderModel> get orders => _orders;
  String get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;
  bool get isSubmitting => _isSubmitting;

  List<MaintenanceOrderModel> get filteredOrders {
    if (_statusFilter == 'all') return _orders;
    return _orders.where((o) => o.status.name == _statusFilter).toList();
  }

  int get pendingCount => _orders.where((o) => o.status.name == 'pending').length;

  Future<void> loadOrders() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _orders = await _repository.fetchOrders();
      _status = LoadStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    } catch (_) {
      _errorMessage = 'تعذّر تحميل طلبات الصيانة.';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<bool> submitRequest({
    required String deviceType,
    required String deviceId,
    required String problemType,
    required String description,
    String? requesterId,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.createOrder({
        'deviceType': deviceType,
        'deviceId': deviceId,
        'problemType': problemType,
        'description': description,
        if (requesterId != null) 'requesterId': requesterId,
      });
      _isSubmitting = false;
      notifyListeners();
      await loadOrders();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'تعذّر إرسال الطلب، حاول مرة أخرى.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status, {String? technicianId}) async {
    try {
      await _repository.updateOrderStatus(id, status, technicianId: technicianId);
      await loadOrders();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
