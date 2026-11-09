import 'package:flutter/material.dart';
import 'package:university_assets_app/core/constants/load_status.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/models/maintenance_order_model.dart';
export 'package:university_assets_app/core/constants/load_status.dart';

class MaintenanceProvider extends ChangeNotifier {
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

  int get pendingCount =>
      _orders.where((o) => o.status.name == 'pending').length;

  Future<void> loadOrders() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _orders = await MaintenanceOrderService.list();
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

  /// [deviceType]: 'computer' أو 'printer'.
  /// [problemType]: 'hardware' أو 'software' فقط — هذا كل ما يدعمه الباك اند.
  /// [requesterId]: معرّف سجل الموظف (Employee.id وليس User.id)، مطلوب فقط
  /// عند الإنشاء بحساب مدير (للموظف يتجاهله الباك اند ويستخدم سجله تلقائياً).
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
      final order = MaintenanceOrderModel(
        id: '',
        deviceType:
            deviceType == 'printer' ? AssetType.printer : AssetType.computer,
        deviceId: deviceId,
        requesterId: requesterId,
        problemType: problemType == 'software' ? 'برمجيات' : 'عتاد',
        description: description,
        status: MaintenanceStatus.pending,
      );
      await MaintenanceOrderService.create(order);
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

  /// [status]: 'pending' / 'in_progress' أو 'inProgress' / 'completed' / 'cancelled'
  /// (تُقبل الصيغتان). [technicianId] هو معرّف المستخدم الفني (User.id).
  Future<bool> updateStatus(String id, String status,
      {String? technicianId}) async {
    try {
      await MaintenanceOrderService.updateStatus(id, _parseStatus(status));
      if (technicianId != null && technicianId.isNotEmpty) {
        await MaintenanceOrderService.assignTechnician(id, technicianId);
      }
      await loadOrders();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    try {
      await MaintenanceOrderService.delete(id);
      _orders.removeWhere((o) => o.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  MaintenanceStatus _parseStatus(String s) {
    switch (s.replaceAll('_', '').toLowerCase()) {
      case 'inprogress':
        return MaintenanceStatus.inProgress;
      case 'completed':
        return MaintenanceStatus.completed;
      case 'cancelled':
        return MaintenanceStatus.cancelled;
      default:
        return MaintenanceStatus.pending;
    }
  }
}
