import 'package:flutter/material.dart';
import 'package:university_assets_app/core/constants/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/college_model.dart';
import '../data/colleges_repository.dart';
export '../../../core/constants/load_status.dart';

class CollegesProvider extends ChangeNotifier {
  CollegesProvider({CollegesRepository? repository})
      : _repository =
            repository ?? CollegesRepository(dio: ApiClient.instance.dio);
  final CollegesRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<CollegeModel> _colleges = [];
  String _errorMessage = '';
  bool _isSubmitting = false;

  LoadStatus get status => _status;
  List<CollegeModel> get colleges => _colleges;
  String get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;

  Future<void> loadColleges() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _colleges = await _repository.fetchColleges();
      _status = LoadStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    } catch (_) {
      _errorMessage = 'تعذّر تحميل الكليات.';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<bool> addCollege(String name) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.createCollege(name);
      await loadColleges();
      _isSubmitting = false;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCollege(String id, String name) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.updateCollege(id, name);
      await loadColleges();
      _isSubmitting = false;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCollege(String id) async {
    try {
      await _repository.deleteCollege(id);
      _colleges.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
