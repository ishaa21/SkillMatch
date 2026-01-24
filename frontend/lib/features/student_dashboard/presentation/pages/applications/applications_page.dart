import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/utils/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import '../../../../../core/constants/asset_constants.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> with SingleTickerProviderStateMixin {
  final Dio _dio = createDio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _applications = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late TabController _tabController;
  
  // Stats
  int _totalApplications = 0;
  int _shortlistedCount = 0;
  int _hiredCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/applications/my-applications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        final apps = response.data as List;
        setState(() {
          _applications = apps;
          _isLoading = false;
          _calculateStats();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Unable to load applications. Pull down to retry.';
        });
      }
    }
  }

  void _calculateStats() {
    _totalApplications = _applications.length;
    _shortlistedCount = _applications.where((a) => a['status'] == 'Shortlisted').length;
    _hiredCount = _applications.where((a) => a['status'] == 'Hired').length;
    _pendingCount = _applications.where((a) => 
      a['status'] == 'Applied' || a['status'] == 'Pending' || a['status'] == 'Under Review'
    ).length;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.deepGreen,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: AppColors.deepGreen,
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 2),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: [
                Tab(text: 'All ($_totalApplications)'),
                Tab(text: 'Pending ($_pendingCount)'),
                Tab(text: 'Shortlisted ($_shortlistedCount)'),
                Tab(text: 'Hired ($_hiredCount)'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? _buildLoadingState()
        : _hasError 
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationList('all'),
                _buildApplicationList('pending'),
                _buildApplicationList('shortlisted'),
                _buildApplicationList('hired'),
              ],
            ),
    );
  }

  // Helper method removed as no longer needed
  // Widget _buildSliverAppBar(bool innerBoxIsScrolled) { ... }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            AssetConstants.loading,
            height: 150,
            errorBuilder: (_, __, ___) => const CircularProgressIndicator(
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your applications...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 48,
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchApplications,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationList(String filter) {
    List<dynamic> filteredApps;
    
    switch (filter) {
      case 'pending':
        filteredApps = _applications.where((app) {
          final status = app['status'] ?? 'Pending';
          return status == 'Applied' || status == 'Pending' || status == 'Under Review';
        }).toList();
        break;
      case 'shortlisted':
        filteredApps = _applications.where((app) => app['status'] == 'Shortlisted').toList();
        break;
      case 'hired':
        filteredApps = _applications.where((app) => app['status'] == 'Hired').toList();
        break;
      default:
        filteredApps = _applications;
    }

    return RefreshIndicator(
      onRefresh: _fetchApplications,
      color: AppColors.deepGreen,
      child: filteredApps.isEmpty
          ? _buildEmptyState(filter)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredApps.length,
              itemBuilder: (context, index) => _buildApplicationCard(filteredApps[index]),
            ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;
    
    switch (filter) {
      case 'pending':
        message = 'No pending applications';
        icon = Icons.hourglass_empty;
        break;
      case 'shortlisted':
        message = 'No shortlisted applications yet';
        icon = Icons.star_border;
        break;
      case 'hired':
        message = 'No offers yet. Keep applying!';
        icon = Icons.celebration;
        break;
      default:
        message = 'No applications yet.\nStart exploring internships!';
        icon = Icons.assignment_outlined;
    }

    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApplicationCard(dynamic app) {
    final internship = app['internship'] ?? {};
    final status = app['status']?.toString() ?? 'Pending';
    final companyName = _getSafeCompanyName(internship);
    final title = internship['title']?.toString() ?? 'Position';
    final appliedDate = _formatDate(app['createdAt'] ?? app['appliedAt']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showApplicationDetails(app),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.deepGreen.withOpacity(0.1),
                            AppColors.mediumGreen.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and Company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            companyName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 16),
                // Applied Date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'Applied on $appliedDate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Tracker
                _buildProgressTracker(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'shortlisted':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.star;
        break;
      case 'hired':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.celebration;
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.close;
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(String status) {
    // Using shorter labels to prevent overflow
    final steps = ['Apply', 'Review', 'Short', 'Hired'];
    final fullSteps = ['Applied', 'Reviewing', 'Shortlisted', 'Hired'];
    int currentStep = 0;
    
    switch (status.toLowerCase()) {
      case 'applied':
      case 'pending':
        currentStep = 0;
        break;
      case 'under review':
        currentStep = 1;
        break;
      case 'shortlisted':
        currentStep = 2;
        break;
      case 'hired':
        currentStep = 3;
        break;
      case 'rejected':
        currentStep = -1; // Special case
        break;
    }

    if (currentStep == -1) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.red.shade400, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This application was not selected. Keep trying!',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use shorter labels on smaller screens
        final useShortLabels = constraints.maxWidth < 300;
        final displaySteps = useShortLabels ? steps : fullSteps;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(displaySteps.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector line
              final stepIndex = index ~/ 2;
              final isActive = stepIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [AppColors.deepGreen, AppColors.mediumGreen],
                          )
                        : null,
                    color: isActive ? null : Colors.grey.shade200,
                  ),
                ),
              );
            } else {
              // Step circle
              final stepIndex = index ~/ 2;
              final isActive = stepIndex <= currentStep;
              final isCurrent = stepIndex == currentStep;
              
              return Flexible(
                flex: 0,
                child: SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isCurrent ? 24 : 20,
                        height: isCurrent ? 24 : 20,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [AppColors.deepGreen, AppColors.mediumGreen],
                                )
                              : null,
                          color: isActive ? null : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.deepGreen.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isActive
                              ? Icon(
                                  stepIndex < currentStep ? Icons.check : Icons.circle,
                                  size: stepIndex < currentStep ? 12 : 6,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displaySteps[stepIndex],
                        style: TextStyle(
                          fontSize: 8,
                          color: isActive ? AppColors.deepGreen : Colors.grey.shade500,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
          }),
        );
      },
    );
  }

  String _getSafeCompanyName(dynamic internship) {
    try {
      if (internship is! Map) return 'Company';
      final company = internship['company'];
      if (company is Map) {
        return company['companyName']?.toString() ?? 'Company';
      }
      return company?.toString() ?? 'Company';
    } catch (e) {
      return 'Company';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showApplicationDetails(dynamic app) {
    final internship = app['internship'] ?? {};
    final status = app['status']?.toString() ?? 'Pending';
    final companyName = _getSafeCompanyName(internship);
    final title = internship['title']?.toString() ?? 'Position';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.deepGreen.withOpacity(0.1),
                                AppColors.mediumGreen.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                              style: TextStyle(
                                color: AppColors.deepGreen,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
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
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                companyName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildStatusBadge(status),
                    const SizedBox(height: 24),
                    // Timeline
                    const Text(
                      'Application Timeline',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeline(app),
                    const SizedBox(height: 24),
                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              status == 'Hired'
                                  ? '🎉 Congratulations! Reach out to the employer for next steps.'
                                  : 'Keep your profile updated to improve your chances!',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(dynamic app) {
    final timeline = app['timeline'] as List? ?? [];
    
    if (timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.timeline, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Text(
              'Application submitted. Awaiting updates.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: timeline.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == timeline.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isLast ? AppColors.deepGreen : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['status']?.toString() ?? 'Update',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLast ? AppColors.deepGreen : Colors.grey.shade700,
                      ),
                    ),
                    if (event['timestamp'] != null)
                      Text(
                        _formatDate(event['timestamp']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
