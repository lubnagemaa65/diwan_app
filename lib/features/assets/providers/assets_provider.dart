import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/asset_item.dart';
import '../data/assets_repository.dart';

enum LoadStatus { initial, loading, loaded, error }

class AssetsProvider extends ChangeNotifier {
  AssetsProvider({AssetsRepository? repository}) : _repository = repository ?? AssetsRepository();

  final AssetsRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<AssetItem> _allAssets = [];
  String _errorMessage = '';
  String _searchQuery = '';
  String _typeFilter = 'all'; // all | computer | printer
  String _statusFilter = 'all'; // all | active | broken | underMaintenance

  LoadStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  String get statusFilter => _statusFilter;

  List<AssetItem> get filteredAssets {
    return _allAssets.where((asset) {
      final matchesType = _typeFilter == 'all' ||
          (_typeFilter == 'computer' && asset.assetType.name == 'computer') ||
          (_typeFilter == 'printer' && asset.assetType.name == 'printer');

      final matchesStatus = _statusFilter == 'all' || asset.status.name == _statusFilter;

      final matchesSearch = _searchQuery.isEmpty ||
          asset.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (asset.employeeName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesType && matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> loadAssets() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.fetchComputers(),
        _repository.fetchPrinters(),
      ]);
      final computers = results[0].map((c) => AssetItem.fromComputer(c as dynamic)).toList();
      final printers = results[1].map((p) => AssetItem.fromPrinter(p as dynamic)).toList();

      _allAssets = [...computers, ...printers];
      _status = LoadStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    } catch (_) {
      _errorMessage = 'تعذّر تحميل الأصول، حاول مرة أخرى.';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  // إحصاءات سريعة للوحة التحكم
  int get totalComputers => _allAssets.where((a) => a.assetType.name == 'computer').length;
  int get totalPrinters => _allAssets.where((a) => a.assetType.name == 'printer').length;
  int get activeCount => _allAssets.where((a) => a.status.name == 'active').length;
}
