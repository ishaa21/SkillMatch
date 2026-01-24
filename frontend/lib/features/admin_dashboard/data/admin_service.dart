
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/dio_client.dart';
import 'models/admin_stats_model.dart';

class AdminService {
  final Dio _dio = createDio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getAuthHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('No authentication token found');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Dashboard Stats
  Future<AdminStats> getDashboardStats() async {
    final options = await _getAuthHeaders();
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/admin/stats',
      options: options,
    );
    return AdminStats.fromJson(response.data);
  }

  // Analytics
  Future<AdminAnalytics> getAnalytics() async {
    final options = await _getAuthHeaders();
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/admin/analytics',
      options: options,
    );
    return AdminAnalytics.fromJson(response.data);
  }

  // Companies
  Future<List<CompanyUser>> getCompanies({
    String? status,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final options = await _getAuthHeaders();
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get(
      '${ApiConstants.baseUrl}/admin/companies',
      queryParameters: queryParams,
      options: options,
    );
    final List<dynamic> data = response.data['companies'] ?? [];
    return data.map((e) => CompanyUser.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> updateCompanyStatus(String id, String action) async {
    final options = await _getAuthHeaders();
    final response = await _dio.patch(
      '${ApiConstants.baseUrl}/admin/companies/$id/status',
      data: {'action': action},
      options: options,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyCompany(String id, String cin) async {
    final options = await _getAuthHeaders();
    final response = await _dio.post(
      '${ApiConstants.baseUrl}/admin/verify-company',
      data: {'companyId': id, 'cin': cin},
      options: options,
    );
    return response.data;
  }

  // Students
  Future<List<StudentUser>> getStudents({
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final options = await _getAuthHeaders();
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get(
      '${ApiConstants.baseUrl}/admin/students',
      queryParameters: queryParams,
      options: options,
    );
    final List<dynamic> data = response.data['students'] ?? [];
    return data.map((e) => StudentUser.fromJson(e)).toList();
  }

  // Internships
  Future<List<InternshipModel>> getInternships({
    String? status,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final options = await _getAuthHeaders();
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get(
      '${ApiConstants.baseUrl}/admin/internships',
      queryParameters: queryParams,
      options: options,
    );
    final List<dynamic> data = response.data['internships'] ?? [];
    return data.map((e) => InternshipModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> toggleInternshipStatus(String id) async {
    final options = await _getAuthHeaders();
    final response = await _dio.patch(
      '${ApiConstants.baseUrl}/admin/internships/$id/toggle',
      options: options,
    );
    return response.data;
  }

  // Applications
  Future<List<ApplicationModel>> getApplications({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final options = await _getAuthHeaders();
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      '${ApiConstants.baseUrl}/admin/applications',
      queryParameters: queryParams,
      options: options,
    );
    final List<dynamic> data = response.data['applications'] ?? [];
    return data.map((e) => ApplicationModel.fromJson(e)).toList();
  }


  // AI Config
  Future<AIConfigModel> getAIConfig() async {
    final options = await _getAuthHeaders();
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/admin/ai-config',
      options: options,
    );
    return AIConfigModel.fromJson(response.data);
  }

  Future<AIConfigModel> updateAIConfig(Map<String, double> weights) async {
    final options = await _getAuthHeaders();
    final response = await _dio.put(
      '${ApiConstants.baseUrl}/admin/ai-config',
      data: {'weights': weights},
      options: options,
    );
    return AIConfigModel.fromJson(response.data['config'] ?? {});
  }


  // Delete User
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    final options = await _getAuthHeaders();
    final response = await _dio.delete(
      '${ApiConstants.baseUrl}/admin/users/$userId',
      options: options,
    );
    return response.data;
  }
}
