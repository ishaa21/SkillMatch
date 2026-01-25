import 'package:flutter/foundation.dart';

class ApiConstants {
  // ===================================================================
  // CONFIGURATION: API Base URL
  // ===================================================================
  static const String baseUrl = "https://skillmatch-iy1r.onrender.com/api";

  // Timeout configurations (in seconds)
  // Increased to 60 seconds to accommodate slow network connections
  static const int connectTimeoutSeconds = 60; 
  static const int receiveTimeoutSeconds = 60;
  static const int sendTimeoutSeconds = 60;


  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
}
