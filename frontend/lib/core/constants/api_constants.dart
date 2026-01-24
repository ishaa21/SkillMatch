import 'package:flutter/foundation.dart';

class ApiConstants {
  // ===================================================================
  // CONFIGURATION: Update this IP when your network changes!
  // Find your IP: Open PowerShell and run 'ipconfig'
  // Look for "IPv4 Address" under your active WiFi/Ethernet adapter.
  // ===================================================================
  static const String _lanIP = '192.168.0.111'; // <-- UPDATE THIS
  
  // Set to true if using Android Emulator, false for Physical Device
  static const bool _useEmulator = false;
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Emulator uses 10.0.2.2 (maps to host localhost)
      // Physical device uses LAN IP to reach the PC
      return _useEmulator
          ? 'http://10.0.2.2:5000/api'
          : 'http://$_lanIP:5000/api';
    } else {
      // iOS Simulator or other platforms
      return 'http://localhost:5000/api';
    }
  }

  // Timeout configurations (in seconds)
  // Increased to 60 seconds to accommodate slow network connections
  static const int connectTimeoutSeconds = 60;
  static const int receiveTimeoutSeconds = 60;
  static const int sendTimeoutSeconds = 60;


  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
}
