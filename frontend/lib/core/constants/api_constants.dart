import 'package:flutter/foundation.dart';

class ApiConstants {
  // ===================================================================
  // CONFIGURATION: API Base URL
  // ===================================================================
  static const String baseUrl = "https://skillmatch-iy1r.onrender.com/api";

  // Timeout configurations (in seconds)
  // Increased to 120 seconds to accommodate Render free-tier cold starts
  static const int connectTimeoutSeconds = 120; 
  static const int receiveTimeoutSeconds = 120;
  static const int sendTimeoutSeconds = 120;


  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
}
