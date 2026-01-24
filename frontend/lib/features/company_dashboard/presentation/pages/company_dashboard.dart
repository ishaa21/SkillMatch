import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/asset_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'create_internship_page.dart';
import 'applicants_page.dart';
import 'company_profile_page.dart';
import 'all_applicants_page.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  List<dynamic> _internships = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedIndex = 0;
  Map<String, dynamic>? _companyProfile;
  Map<String, dynamic> _stats = {};
  Set<String> _processingIds = {}; // Track internships being processed

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      debugPrint('DEBUG: Loading company data with token: ${token?.substring(0, 20)}...');
      
      // Fetch all data in parallel
      final results = await Future.wait([
        _dio.get(
          '${ApiConstants.baseUrl}/company/profile',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        ),
        _dio.get(
          '${ApiConstants.baseUrl}/company/stats',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        ),
        _dio.get(
          '${ApiConstants.baseUrl}/internships/my-internships',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        ),
      ]);

      debugPrint('DEBUG: Company profile loaded: ${results[0].data}');
      debugPrint('DEBUG: Stats loaded: ${results[1].data}');
      debugPrint('DEBUG: Internships loaded: ${results[2].data?.length ?? 0} items');

      if (mounted) {
        setState(() {
          _companyProfile = results[0].data;
          _stats = results[1].data ?? {};
          _internships = List.from(results[2].data ?? []);
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      debugPrint('DEBUG: DioException - ${e.message}');
      debugPrint('DEBUG: Response data - ${e.response?.data}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.response?.data['message'] ?? 
              'Failed to load company data. Please check your connection.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: General error - $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToCreateInternship() async {
    final isApproved = _companyProfile?['isApproved'] ?? false;
    
    if (!isApproved) {
      _showNotApprovedDialog();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateInternshipPage()),
    );
    if (result == true) _loadCompanyData();
  }

  void _showNotApprovedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.pending, color: Colors.orange),
            SizedBox(width: 12),
            Text('Approval Pending'),
          ],
        ),
        content: const Text(
          'Your company account is pending approval. You will be able to post internships once approved by our admin team.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditInternship(Map<String, dynamic> internship) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateInternshipPage(internship: internship)),
    );
    if (result == true) _loadCompanyData();
  }

  Future<void> _navigateToApplicants(String internshipId, String title) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicantsPage(internshipId: internshipId, internshipTitle: title),
      ),
    );
    // Refresh stats after viewing applicants
    _loadCompanyData();
  }

  Future<void> _toggleInternshipStatus(String id, bool currentStatus) async {
    if (_processingIds.contains(id)) return; // Prevent duplicate actions
    
    setState(() => _processingIds.add(id));
    
    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.put(
        '${ApiConstants.baseUrl}/internships/$id',
        data: {'isActive': !currentStatus},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? 'Internship activated' : 'Internship deactivated'),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadCompanyData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(id));
      }
    }
  }

  Future<void> _deleteInternship(String id) async {
    if (_processingIds.contains(id)) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Internship'),
        content: const Text('Are you sure you want to delete this internship? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    setState(() => _processingIds.add(id));

    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.delete(
        '${ApiConstants.baseUrl}/internships/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship deleted'),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadCompanyData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _hasError
                ? _buildError()
                : _buildBody(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            AssetConstants.loading,
            height: 150,
            errorBuilder: (_, __, ___) => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCompanyData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.deepGreen,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Internships',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.people_outline),
                if ((_stats['totalApplicants'] ?? 0) > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.people),
            label: 'Applicants',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return _buildInternshipsPage();
      case 2:
        return AllApplicantsPage(internships: _internships);
      case 3:
        return CompanyProfilePage(
          companyProfile: _companyProfile,
          onProfileUpdated: _loadCompanyData,
        );
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    final isApproved = _companyProfile?['isApproved'] ?? false;
    
    return RefreshIndicator(
      onRefresh: _loadCompanyData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isApproved),
            const SizedBox(height: 24),

            // Approval Banner
            if (!isApproved) ...[
              _buildApprovalBanner(),
              const SizedBox(height: 24),
            ],

            // Stats Cards
            _buildStatsGrid(),
            const SizedBox(height: 32),

            // Quick Actions
            _buildQuickActions(isApproved),
            const SizedBox(height: 32),

            // Recent Internships
            _buildRecentInternships(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isApproved) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              () {
                final name = _companyProfile?['companyName']?.toString() ?? '';
                return (name.isNotEmpty ? name[0] : 'C').toUpperCase();
              }(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                _companyProfile?['companyName'] ?? 'Company',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isApproved 
                ? Colors.green.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isApproved ? Icons.verified : Icons.pending,
                color: isApproved ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isApproved ? 'Verified' : 'Pending',
                style: TextStyle(
                  color: isApproved ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification in Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your account is being reviewed. You\'ll be notified once approved.',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Listings',
                '${_stats['activeInternships'] ?? 0}',
                Icons.work_outline,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Applicants',
                '${_stats['totalApplicants'] ?? 0}',
                Icons.people_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Shortlisted',
                '${_stats['shortlisted'] ?? 0}',
                Icons.star_outline,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Hired',
                '${_stats['hired'] ?? 0}',
                Icons.check_circle_outline,
                AppColors.deepGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isApproved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Post Internship',
                Icons.add_circle_outline,
                AppColors.deepGreen,
                isApproved ? _navigateToCreateInternship : _showNotApprovedDialog,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'View Applicants',
                Icons.people_outline,
                Colors.blue,
                () => setState(() => _selectedIndex = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInternships() {
    final recentInternships = _internships.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Internships',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_internships.length > 3)
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentInternships.isEmpty)
          _buildEmptyInternships()
        else
          ...recentInternships.map((internship) => _buildInternshipCard(internship)),
      ],
    );
  }

  Widget _buildEmptyInternships() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.work_outline, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No internships yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by posting your first internship',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternshipsPage() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            children: [
              // Wrap in Expanded to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Internships',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_internships.length} total listings',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _navigateToCreateInternship,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _internships.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        AssetConstants.empty,
                        height: 150,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.work_outline,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No internships posted yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Post your first internship to start receiving applications',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _navigateToCreateInternship,
                        icon: const Icon(Icons.add),
                        label: const Text('Post Internship'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCompanyData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _internships.length,
                    itemBuilder: (context, index) {
                      final internship = _internships[index];
                      return _buildInternshipCard(internship, showFullActions: true);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInternshipCard(Map<String, dynamic> internship, {bool showFullActions = false}) {
    final isActive = internship['isActive'] ?? true;
    final isProcessing = _processingIds.contains(internship['_id']);
    final stipend = internship['stipend'];
    String stipendText = 'Unpaid';
    if (stipend != null) {
      if (stipend is Map) {
        if (stipend['min'] != null) {
             stipendText = '₹${stipend['min']}';
             if (stipend['max'] != null && stipend['max'] != stipend['min']) {
               stipendText += '-${stipend['max']}';
             }
             stipendText += '/mo';
        } else if (stipend['amount'] != null) {
             stipendText = '₹${stipend['amount']}/mo';
        }
      } else if (stipend is num && stipend > 0) {
         stipendText = '₹$stipend/mo';
      }
    }
    
    // Safe location extraction - handle both String and Map types
    String getLocationString(dynamic loc) {
      if (loc == null) return 'Remote';
      if (loc is String) return loc;
      if (loc is Map) {
        final city = loc['city']?.toString() ?? '';
        final state = loc['state']?.toString() ?? '';
        if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
        if (city.isNotEmpty) return city;
        if (state.isNotEmpty) return state;
        return loc['address']?.toString() ?? 'Remote';
      }
      return 'Remote';
    }
    final location = getLocationString(internship['location']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive ? null : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            internship['title'] ?? 'Role',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      internship['workMode'] ?? 'Remote',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (showFullActions)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _navigateToEditInternship(internship);
                    } else if (value == 'view') {
                      _navigateToApplicants(internship['_id'], internship['title']);
                    } else if (value == 'toggle') {
                      _toggleInternshipStatus(internship['_id'], isActive);
                    } else if (value == 'delete') {
                      _deleteInternship(internship['_id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'view', child: Text('View Applicants')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(isActive ? 'Deactivate' : 'Activate'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
              else
                IconButton(
                  onPressed: () => _navigateToApplicants(
                    internship['_id'],
                    internship['title'],
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
            ],
          ),
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.attach_money, stipendText),
              _buildInfoChip(Icons.access_time, _getDuration(internship['duration'])),
              _buildInfoChip(Icons.location_on_outlined, location),
            ],
          ),
        ],
      ),
    );
  }

  String _getDuration(dynamic duration) {
    if (duration == null) return 'N/A';
    if (duration is Map && duration['displayString'] != null) {
      return duration['displayString'].toString();
    }
    if (duration is String) return duration;
    return duration.toString();
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          // Constrain text to prevent overflow with long labels
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
