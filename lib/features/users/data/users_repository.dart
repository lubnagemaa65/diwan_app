import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/user_model.dart';

class UsersRepository {
  UsersRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;
  final Dio _dio;

  Future<List<UserModel>> fetchUsers() async {
    try {
      final response = await _dio.get(ApiConstants.users);
      final list = _extractList(response.data);
      return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> createUser(Map<String, dynamic> payload) async {
    try {
      await _dio.post(ApiConstants.users, data: payload);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> payload) async {
    try {
      await _dio.put(ApiConstants.userById(id), data: payload);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException.fromDioError(e);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete(ApiConstants.userById(id));
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
