import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Creates a Dio instance with proper timeout configurations
/// to prevent connection timeout errors on mobile devices.
/// 
/// Usage: Replace `Dio()` with `createDio()` in your widgets.
Dio createDio() {
  return Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: Duration(seconds: ApiConstants.connectTimeoutSeconds),
    receiveTimeout: Duration(seconds: ApiConstants.receiveTimeoutSeconds),
    sendTimeout: Duration(seconds: ApiConstants.sendTimeoutSeconds),
  ));
}

/// Dio instance with default timeouts for reuse
final dioClient = createDio();
