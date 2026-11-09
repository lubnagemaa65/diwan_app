import 'package:flutter/material.dart';
import 'package:university_assets_app/core/constants/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/employee_model.dart';
import '../data/employees_repository.dart';
export '../../../core/constants/load_status.dart';

class EmployeesProvider extends ChangeNotifier {
  EmployeesProvider({EmployeesRepository? repository})
      : _repository =
            repository ?? EmployeesRepository(dio: ApiClient.instance.dio);
  final EmployeesRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<EmployeeModel> _employees = [];
  String _errorMessage = '';
  bool _isSubmitting = false;

  LoadStatus get status => _status;
  List<EmployeeModel> get employees => _employees;
  String get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;

  Future<void> loadEmployees() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _employees = await _repository.fetchEmployees();
      _status = LoadStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    } catch (_) {
      _errorMessage = 'تعذّر تحميل الموظفين.';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<bool> addEmployee({
    required String firstName,
    required String fatherName,
    required String familyName,
    String? userId,
    String? collegeId,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.createEmployee(
        firstName: firstName,
        fatherName: fatherName,
        familyName: familyName,
        userId: userId,
        collegeId: collegeId,
      );
      await loadEmployees();
      _isSubmitting = false;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      await _repository.deleteEmployee(id);
      _employees.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
