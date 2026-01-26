import 'package:flutter/material.dart';
import '../../../../core/utils/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/asset_constants.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/enhanced_internship_card.dart';
import 'search/search_page.dart';
import 'applications/applications_page.dart';
import 'profile/profile_page.dart';
import 'search/internship_details_page.dart';
import 'notifications_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  // Data State
  List<dynamic> _internships = [];
  List<dynamic> _allInternships = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _userName = "Student";
  int _selectedIndex = 0;
  double _completionPercentage = 0.0;
  String _selectedFilter = 'All';
  Set<String> _appliedInternshipIds = {};
  
  // User Skills for matching
  List<String> _userSkills = [];


  final Dio _dio = createDio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late AnimationController _fadeController;

  // Filter Options
  final List<String> _filterOptions = ['All', 'Remote', 'Hybrid', 'On-site', '\$ High Pay', 'Best Match'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Initialize all data in parallel
  Future<void> _initializeData() async {
    await Future.wait([
      _loadUserData(),
      _fetchRecommendations(),
      _loadAppliedInternships(),
    ]);
  }

  // ===================== LOAD USER DATA =====================
  Future<void> _loadUserData() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/student/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted && response.statusCode == 200) {
        final data = response.data;

          setState(() {
            final rawName = data['fullName'];
            if (rawName is Map) {
              _userName = '${rawName['firstName'] ?? ''} ${rawName['lastName'] ?? ''}'.trim();
              if (_userName.isEmpty) _userName = 'Student';
            } else {
              _userName = rawName?.toString() ?? 'Student';
            }
          
            // Extract user skills for matching
            _userSkills = (data['skills'] as List?)?.map((s) {
                  if (s is Map) {
                     return (s['name'] ?? '').toString().toLowerCase();
                  }
                  return s.toString().toLowerCase();
                }).toList() ??
                [];

            // Calculate profile completion
            int filled = 0;
            const int total = 7;

            if (_userName.isNotEmpty && _userName != 'Student') filled++;
            if (data['phone'] != null && data['phone'].toString().isNotEmpty) filled++;
            if (data['university'] != null && data['university'].toString().isNotEmpty) filled++;
            if (data['degree'] != null && data['degree'].toString().isNotEmpty) filled++;
            if ((data['skills'] as List?)?.isNotEmpty ?? false) filled++;
            if (data['resumeUrl'] != null && data['resumeUrl'].toString().isNotEmpty) filled++;
            if (data['bio'] != null && data['bio'].toString().isNotEmpty) filled++;

            _completionPercentage = filled / total;
          });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  // ===================== LOAD APPLIED INTERNSHIPS =====================
  Future<void> _loadAppliedInternships() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/applications/my-applications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted && response.statusCode == 200) {
        final applications = response.data as List;
        setState(() {
          _appliedInternshipIds = applications
              .map((app) => (app['internship']?['_id'] ?? app['internshipId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading applied internships: $e');
    }
  }

  // ===================== FETCH INTERNSHIPS =====================
  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      // If no token, maybe use public endpoint? But Dashboard implies logged in.
      // We'll assume logged in for now.
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/internships/recommendations',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        var rawList = response.data is List ? List.from(response.data) : [];

        // Backend already provides matchPercentage, but we can verify/fallback
        // rawList is already sorted by backend usually
        
        if (mounted) {
          setState(() {
            _allInternships = rawList;
            _internships = _applyFilter(rawList);
            _isLoading = false;
            _fadeController.forward(from: 0);
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.response?.data['message'] ?? 
              'Unable to load internships. Please check your connection.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // ===================== CALCULATE MATCH PERCENTAGE =====================
  int _calculateMatchPercentage(Map<String, dynamic> internship) {
    if (_userSkills.isEmpty) {
      // Random score if no user skills
      return 60 + (internship['_id'].hashCode % 35);
    }

    final requiredSkills = (internship['skillsRequired'] as List?)
        ?.map((s) => s.toString().toLowerCase())
        .toList() ?? [];

    if (requiredSkills.isEmpty) return 70;

    int matchedSkills = 0;
    for (var skill in requiredSkills) {
      if (_userSkills.any((userSkill) => 
          userSkill.contains(skill) || skill.contains(userSkill))) {
        matchedSkills++;
      }
    }

    // Base match + skill match bonus
    int baseMatch = 50;
    int skillMatchPercentage = ((matchedSkills / requiredSkills.length) * 50).round();
    
    return (baseMatch + skillMatchPercentage).clamp(40, 99);
  }

  // ===================== APPLY FILTER =====================
  List<dynamic> _applyFilter(List<dynamic> internships) {
    if (_selectedFilter == 'All') {
      return internships;
    } else if (_selectedFilter == 'Remote') {
      return internships.where((i) => i['workMode'] == 'Remote').toList();
    } else if (_selectedFilter == 'Hybrid') {
      return internships.where((i) => i['workMode'] == 'Hybrid').toList();
    } else if (_selectedFilter == 'On-site') {
      return internships.where((i) => i['workMode'] == 'Onsite' || i['workMode'] == 'On-site').toList();
    } else if (_selectedFilter == '\$ High Pay') {
      return internships.where((i) {
        final stipend = i['stipend'];
        if (stipend is Map) {
          final amount = num.tryParse(stipend['max']?.toString() ?? 
                                    stipend['min']?.toString() ?? '0') ?? 0;
          return amount >= 10000; // Updated threshold
        }
        return false;
      }).toList();
    } else if (_selectedFilter == 'Best Match') {
      return internships.where((i) {
        final score = num.tryParse(i['matchPercentage']?.toString() ?? '0') ?? 0;
        return score >= 75;
      }).toList();
    }
    return internships;
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _internships = _applyFilter(_allInternships);
    });
  }

  /// Refresh all data
  Future<void> _refreshData() async {
    await _initializeData();
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeBody(),
            const SearchPage(),
            const ApplicationsPage(),
            const ProfilePage(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBody() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.deepGreen,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: DashboardHeader(
              userName: _userName,
              notificationCount: _appliedInternshipIds.length,
              completionPercentage: _completionPercentage,
              onNotificationTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildProfileCompletionCard()),
          SliverToBoxAdapter(child: _buildFilters()),
          SliverToBoxAdapter(child: _buildTitle()),
          
          // Content based on state
          if (_isLoading)
            SliverToBoxAdapter(child: _buildLoading())
          else if (_hasError)
            SliverToBoxAdapter(child: _buildError())
          else if (_internships.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _internships.length) {
                    return const SizedBox(height: 100);
                  }
                  final internship = _internships[index];
                  final isApplied = _appliedInternshipIds.contains(
                    internship['_id']?.toString() ?? ''
                  );
                  
                  return FadeTransition(
                    opacity: _fadeController,
                    child: EnhancedInternshipCard(
                      internship: internship,
                      isApplied: isApplied,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InternshipDetailsPage(
                              internship: internship,
                            ),
                          ),
                        );
                        // Refresh to sync status if user applied from details page
                        _loadAppliedInternships();
                      },
                      onApply: () => _handleQuickApply(internship),
                    ),
                  );
                },
                childCount: _internships.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleQuickApply(Map<String, dynamic> internship) async {
    final internshipId = internship['_id'].toString();
    
    // Optimistic Update
    setState(() {
      _appliedInternshipIds.add(internshipId);
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.post(
        '${ApiConstants.baseUrl}/applications',
        data: {
          'internshipId': internshipId,
          'coverLetter': 'I am interested in this role and would like to apply immediately.' // Standard One-Click Apply message
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application Sent Successfully!'),
            backgroundColor: AppColors.mediumTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _appliedInternshipIds.remove(internshipId);
        });
        
        String msg = 'Failed to apply';
        if (e is DioException) {
           if (e.response?.statusCode == 409) {
             msg = 'Already applied to this internship';
              // Keep it as applied since backend says so
             setState(() {
                _appliedInternshipIds.add(internshipId);
             });
           } else {
             msg = e.response?.data['message'] ?? 'Connection error';
           }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildProfileCompletionCard() {
    if (_completionPercentage >= 1.0) return const SizedBox.shrink();
    
    final percentage = (_completionPercentage * 100).round();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepGreen.withOpacity(0.1),
            AppColors.mediumGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mediumGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: _completionPercentage,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _completionPercentage < 0.5 
                        ? Colors.orange 
                        : AppColors.mediumGreen,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get better internship matches!',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedIndex = 3),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Lottie.asset(
              AssetConstants.loading,
              height: 150,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(color: AppColors.mediumGreen),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI is curating your best matches...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 60,
                color: Colors.red.shade300,
              ),
            ),
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
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Lottie.asset(
              AssetConstants.empty,
              height: 150,
              errorBuilder: (_, __, ___) => Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No internships found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'New opportunities are added daily. Check back soon!'
                  : 'Try changing your filter to see more results.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFilter != 'All')
              OutlinedButton(
                onPressed: () => _onFilterChanged('All'),
                child: const Text('Clear Filter'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recommended for You',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!_isLoading && _internships.isNotEmpty)
            Text(
              '${_internships.length} found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: _filterOptions.map((filter) => _filterChip(filter)).toList(),
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _onFilterChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepGreen : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.deepGreen : Colors.grey.shade300,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.deepGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Text(
                'Search roles, skills, companies...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.deepGreen,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.assignment_outlined),
                if (_appliedInternshipIds.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.assignment),
            label: 'Applications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
