import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/dio_client.dart';

class AuthService {
  final Dio _dio = createDio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login to: ${ApiConstants.login}');
      print('Payload: {email: $email, password: ***}');
      
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final token = response.data['token'];
        if (token == null) throw Exception('Token is null in response');
        
        await _storage.write(key: 'auth_token', value: token.toString());
        await _storage.write(key: 'user_role', value: response.data['role'].toString());
        await _storage.write(key: 'user_id', value: response.data['_id'].toString());
        return response.data;
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        String message;
        
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          final msg = data['message'];
          message = msg is String ? msg : msg.toString();
        } else if (data is String) {
          message = data;
        } else {
          message = 'Login failed';
        }
        
        throw Exception(message);
      } else {
        throw Exception('Connection failed: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    String? fullName,
    String? companyName,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: {
        'email': email,
        'password': password,
        'role': role,
        if (fullName != null) 'fullName': fullName,
        if (companyName != null) 'companyName': companyName,
      });

      if (response.statusCode == 201) {
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token.toString());
        await _storage.write(key: 'user_role', value: response.data['role'].toString());
        return response.data;
      } else {
        throw Exception('Failed to register');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        String message;
        
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          final msg = data['message'];
          message = msg is String ? msg : msg.toString();
        } else if (data is String) {
          message = data;
        } else {
          message = 'Registration failed';
        }
        
        throw Exception(message);
      } else {
        throw Exception('Connection failed: ${e.message}');
      }
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
