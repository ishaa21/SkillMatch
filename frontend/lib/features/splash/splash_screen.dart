import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/asset_constants.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/dio_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../student_dashboard/presentation/pages/student_dashboard.dart';
import '../../features/company_dashboard/presentation/pages/company_dashboard.dart';
import '../../features/admin_dashboard/presentation/pages/admin_dashboard.dart';
import 'welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = createDio();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Navigate after delay with proper token validation
    Future.delayed(const Duration(seconds: 3), _checkAuthAndNavigate);
  }

  /// Validates token and navigates to appropriate screen
  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    try {
      final token = await _storage.read(key: 'auth_token');
      final role = await _storage.read(key: 'user_role');

      // No stored credentials - go to login
      if (token == null || token.isEmpty || role == null || role.isEmpty) {
        _navigateToLogin();
        return;
      }

      // Validate token by calling /auth/me endpoint
      final isValid = await _validateToken(token);
      
      if (!mounted) return;

      if (!isValid) {
        // Token is invalid/expired - clear storage and go to login
        await _storage.deleteAll();
        _navigateToLogin();
        return;
      }

      // Token is valid - navigate based on role
      _navigateToRoleDashboard(role);
    } catch (e) {
      // On any error, clear storage and go to login
      debugPrint('Auth check error: $e');
      await _storage.deleteAll();
      if (mounted) _navigateToLogin();
    }
  }

  /// Validates token by calling the /auth/me endpoint
  Future<bool> _validateToken(String token) async {
    try {
      final response = await _dio.get(
        ApiConstants.me,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // Token is valid if we get a 200 response
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
    );
  }

  void _navigateToRoleDashboard(String role) {
    Widget destination;
    
    switch (role.toLowerCase()) {
      case 'student':
        destination = const StudentDashboard();
        break;
      case 'company':
        destination = const CompanyDashboard();
        break;
      case 'admin':
        destination = const AdminDashboard();
        break;
      default:
        destination = const LoginPage();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.softMint, // Using clean light background for splash
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Hero(
                tag: 'app_logo',
                 child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    height: 140, // Ensure precise size for the container
                    width: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.deepGreen, // Match logo background
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepGreen.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AssetConstants.logo,
                        fit: BoxFit.cover, // Ensure it fills the circle
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                             Icons.spa_rounded,
                             size: 80,
                             color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                           ),
               ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'SkillMatch',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.deepGreen,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                     Text(
                      'Your Career, AI-Powered',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.mediumTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
