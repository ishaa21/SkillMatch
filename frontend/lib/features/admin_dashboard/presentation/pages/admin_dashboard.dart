import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../data/admin_service.dart';
import '../widgets/overview_section.dart';
import '../widgets/approvals_section.dart';
import '../widgets/users_section.dart';
import '../widgets/internships_section.dart';
import '../widgets/ai_config_section.dart';
import '../../data/models/admin_stats_model.dart';
import '../widgets/analytics_section.dart';

import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import 'settings/admin_settings_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Data State - persisted across navigation
  AdminStats _stats = AdminStats.empty();
  AdminAnalytics _analytics = AdminAnalytics.empty();
  List<CompanyUser> _companies = [];
  List<StudentUser> _students = [];
  List<InternshipModel> _internships = [];
  List<ApplicationModel> _applications = [];
  AIConfigModel _aiConfig = AIConfigModel.empty();
  
  // Pagination state
  int _companyPage = 1;
  int _studentPage = 1;
  int _internshipPage = 1;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }



  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getCompanies(),
        _adminService.getStudents(),
        _adminService.getInternships(),
        _adminService.getAIConfig(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as AdminStats;
          _companies = results[1] as List<CompanyUser>;
          _students = results[2] as List<StudentUser>;
          _internships = results[3] as List<InternshipModel>;
          _aiConfig = results[4] as AIConfigModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize admin dashboard: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAnalytics() async {
    if (_analytics.applicationsTrend.isNotEmpty) return; // Already loaded
    try {
      final analytics = await _adminService.getAnalytics();
      if (mounted) {
        setState(() => _analytics = analytics);
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  Future<void> _refreshCurrentSection() async {
    try {
      switch (_selectedIndex) {
        case 0:
          final stats = await _adminService.getDashboardStats();
          if (mounted) setState(() => _stats = stats);
          break;
        case 1:
          final companies = await _adminService.getCompanies(status: 'pending');
          if (mounted) setState(() => _companies = companies);
          break;
        case 2:
          final students = await _adminService.getStudents();
          final companies = await _adminService.getCompanies();
          if (mounted) setState(() {
            _students = students;
            _companies = companies;
          });
          break;
        case 3:
          final internships = await _adminService.getInternships();
          if (mounted) setState(() => _internships = internships);
          break;
        case 4:
          final config = await _adminService.getAIConfig();
          if (mounted) setState(() => _aiConfig = config);
          break;
        case 5:
          final analytics = await _adminService.getAnalytics();
          final stats = await _adminService.getDashboardStats();
          if (mounted) setState(() {
            _analytics = analytics;
            _stats = stats;
          });
          break;
      }
    } catch (e) {
      _showSnackBar('Error refreshing data: $e', isError: true);
    }
  }


  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.mediumGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleCompanyAction(String companyId, String action) async {
    try {
      await _adminService.updateCompanyStatus(companyId, action);
      _showSnackBar('Company ${action}ed successfully');
      _refreshCurrentSection();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _handleVerifyCompany(String id, String cin) async {
    try {
      final result = await _adminService.verifyCompany(id, cin);
      if (result['success'] == true) {
        _showSnackBar(result['message'] ?? 'Company verified successfully');
        _refreshCurrentSection();
      }
    } catch (e) {
      // Extract error message if possible
      String errorMsg = e.toString();
      if (e is DioException && e.response?.data != null) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      _showSnackBar('Verification failed: $errorMsg', isError: true);
    }
  }

  Future<void> _handleDeleteUser(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to delete the account for:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(
              'This action is irreversible and will delete all associated data including listings, applications, and history.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteUser(userId);
        _showSnackBar('User deleted successfully');
        _refreshCurrentSection();
      } catch (e) {
        _showSnackBar('Error deleting user: $e', isError: true);
      }
    }
  }

  Future<void> _handleAIConfigUpdate(Map<String, double> weights) async {
    try {
      await _adminService.updateAIConfig(weights);
      _showSnackBar('AI configuration updated successfully');
      _refreshCurrentSection();
    } catch (e) {
      _showSnackBar('Error updating AI config: $e', isError: true);
    }
  }

  Future<void> _handleInternshipToggle(String internshipId) async {
    try {
      await _adminService.toggleInternshipStatus(internshipId);
      _showSnackBar('Internship status toggled');
      _refreshCurrentSection();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 5) _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return _buildMobileLayout();
        }
        return _buildMainLayout();
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.deepGreen),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
              );
            },
            icon: const Icon(Icons.settings, color: AppColors.deepGreen),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.deepGreen),
            onPressed: _refreshCurrentSection,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.deepGreen),
              accountName: const Text('Administrator'),
              accountEmail: const Text('admin@skillmatch.com'),
              currentAccountPicture: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings, size: 36, color: AppColors.deepGreen),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(0, Icons.dashboard_outlined, 'Overview'),
                  _buildDrawerItem(1, Icons.verified_user_outlined, 'Approvals', badge: _getPendingCount()),
                  _buildDrawerItem(2, Icons.people_outline, 'Users'),
                  _buildDrawerItem(3, Icons.work_outline, 'Internships'),
                  _buildDrawerItem(4, Icons.psychology_outlined, 'AI Config'),
                  _buildDrawerItem(5, Icons.analytics_outlined, 'Analytics'),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          OverviewSection(
            stats: _stats,
            onRefresh: _refreshCurrentSection,
            onNavigateToApprovals: () => _onNavItemTapped(1),
          ),
          ApprovalsSection(
            companies: _companies.where((c) => 
              c.isApproved == false && c.isSuspended != true
            ).toList(),
            onApprove: (id) => _handleCompanyAction(id, 'approve'),
            onReject: (id) => _handleCompanyAction(id, 'reject'),
            onVerify: _handleVerifyCompany,
            onRefresh: _refreshCurrentSection,
          ),
          UsersSection(
            students: _students,
            companies: _companies,
            onDeleteUser: _handleDeleteUser,
            onSuspendCompany: (id) => _handleCompanyAction(id, 'suspend'),
            onReactivateCompany: (id) => _handleCompanyAction(id, 'reactivate'),
            onRefresh: _refreshCurrentSection,
          ),
          InternshipsSection(
            internships: _internships,
            onToggleStatus: _handleInternshipToggle,
            onRefresh: _refreshCurrentSection,
          ),
          AIConfigSection(
            config: _aiConfig,
            onSave: _handleAIConfigUpdate,
            onRefresh: _refreshCurrentSection,
          ),
          AnalyticsSection(
            stats: _stats,
            analytics: _analytics,
            onRefresh: _refreshCurrentSection,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label, {int badge = 0}) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.deepGreen : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.deepGreen : Colors.grey.shade700,
        ),
      ),
      trailing: badge > 0 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // Close drawer
        _onNavItemTapped(index);
      },
    );
  }

  Widget _buildMainLayout() {
    return Row(
      children: [
        // Side Navigation Rail
        _buildNavigationRail(),
        // Main Content Area
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      OverviewSection(
                        stats: _stats,
                        onRefresh: _refreshCurrentSection,
                        onNavigateToApprovals: () => _onNavItemTapped(1),
                      ),
                      ApprovalsSection(
                        companies: _companies.where((c) => 
                          c.isApproved == false && c.isSuspended != true
                        ).toList(),
                        onApprove: (id) => _handleCompanyAction(id, 'approve'),
                        onReject: (id) => _handleCompanyAction(id, 'reject'),
                        onVerify: _handleVerifyCompany,
                        onRefresh: _refreshCurrentSection,
                      ),
                      UsersSection(
                        students: _students,
                        companies: _companies,
                        onDeleteUser: _handleDeleteUser,
                        onSuspendCompany: (id) => _handleCompanyAction(id, 'suspend'),
                        onReactivateCompany: (id) => _handleCompanyAction(id, 'reactivate'),
                        onRefresh: _refreshCurrentSection,
                      ),
                      InternshipsSection(
                        internships: _internships,
                        onToggleStatus: _handleInternshipToggle,
                        onRefresh: _refreshCurrentSection,
                      ),
                      AIConfigSection(
                        config: _aiConfig,
                        onSave: _handleAIConfigUpdate,
                        onRefresh: _refreshCurrentSection,
                      ),
                      AnalyticsSection(
                        stats: _stats,
                        analytics: _analytics,
                        onRefresh: _refreshCurrentSection,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildNavigationRail() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.deepGreen, Color(0xFF0D2818)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 32),
          // Nav Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, 'Overview'),
                  _buildNavItem(1, Icons.verified_user_outlined, 'Approvals', badge: _getPendingCount()),
                  _buildNavItem(2, Icons.people_outline, 'Users'),
                  _buildNavItem(3, Icons.work_outline, 'Internships'),
                  _buildNavItem(4, Icons.psychology_outlined, 'AI Config'),
                  _buildNavItem(5, Icons.analytics_outlined, 'Analytics'),
                ],
              ),
            ),
          ),
          // Logout
          _buildNavItem(-1, Icons.logout, 'Logout', isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  int _getPendingCount() {
    return _companies.where((c) => c.isApproved == false && c.isSuspended != true).length;
  }


  Widget _buildNavItem(int index, IconData icon, String label, {int badge = 0, bool isLogout = false}) {
    final isSelected = _selectedIndex == index && !isLogout;
    
    return Tooltip(
      message: label,
      preferBelow: false,
      child: InkWell(
        onTap: () {
          if (isLogout) {
            _showLogoutDialog();
          } else {
            _onNavItemTapped(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                size: 24,
              ),
              if (badge > 0)
                Positioned(
                  right: 16,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Page Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPageTitle(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  _getPageSubtitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Settings Button
          IconButton(
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.softMint,
              foregroundColor: AppColors.deepGreen,
            ),
          ),
          const SizedBox(width: 12),
          // Refresh Button
          IconButton(
            onPressed: _refreshCurrentSection,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.softMint,
              foregroundColor: AppColors.deepGreen,
            ),
          ),
          const SizedBox(width: 12),
          // Admin Profile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.softMint,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'Platform Overview';
      case 1: return 'Company Approvals';
      case 2: return 'User Management';
      case 3: return 'Internship Monitoring';
      case 4: return 'AI Configuration';
      case 5: return 'Analytics Dashboard';
      default: return 'Admin Dashboard';
    }
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0: return 'Real-time platform metrics and health status';
      case 1: return 'Review and manage pending company registrations';
      case 2: return 'Manage student and company accounts';
      case 3: return 'Monitor all internship listings across the platform';
      case 4: return 'Configure AI matching algorithm weights';
      case 5: return 'Platform analytics and insights';
      default: return '';
    }
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Lottie.asset(
                  AssetConstants.loading,
                  height: 80,
                  errorBuilder: (_, __, ___) => const CircularProgressIndicator(
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Initializing Control Panel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.deepGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading platform data...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
              ),
              const SizedBox(height: 24),
              const Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Unable to connect to the server',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // 1. Close the dialog
                Navigator.of(dialogContext).pop();
                
                // 2. Perform logout (clears storage)
                debugPrint('DEBUG: Admin logging out...');
                await _authService.logout();
                debugPrint('DEBUG: Logout successful, navigating to LoginPage');
                
                // 3. Navigate back to login/signup page
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  
                  // Use rootNavigator to ensure we clear the entire app state
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }


}
