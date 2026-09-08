import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/computer_model.dart';
import '../../../models/printer_model.dart';

class AssetsRepository {
  AssetsRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;
  final Dio _dio;

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
          if (search != null && search.isNotEmpty) 'search': search,
          if (type != null && type.isNotEmpty && type != 'all') 'type': type,
          if (status != null && status.isNotEmpty && status != 'all') 'status': status,
          if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
        },
      );
      final list = _extractList(response.data);
      return list.map((e) => ComputerModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
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
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty && status != 'all') 'status': status,
          if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
        },
      );
      final list = _extractList(response.data);
      return list.map((e) => PrinterModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<ComputerModel> fetchComputerById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.computerById(id));
      return ComputerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<PrinterModel> fetchPrinterById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.printerById(id));
      return PrinterModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> createComputer(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiConstants.computers, data: payload);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> createPrinter(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiConstants.printers, data: payload);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> deleteComputer(String id) async {
    try {
      await _dio.delete(ApiConstants.computerById(id));
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> deletePrinter(String id) async {
    try {
      await _dio.delete(ApiConstants.printerById(id));
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
