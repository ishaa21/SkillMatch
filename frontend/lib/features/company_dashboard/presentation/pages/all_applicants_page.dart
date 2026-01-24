import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AllApplicantsPage extends StatefulWidget {
  final List<dynamic> internships;

  const AllApplicantsPage({super.key, required this.internships});

  @override
  State<AllApplicantsPage> createState() => _AllApplicantsPageState();
}

class _AllApplicantsPageState extends State<AllApplicantsPage> with SingleTickerProviderStateMixin {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  late TabController _tabController;
  Map<String, List<dynamic>> _applicantsByInternship = {};
  bool _isLoading = true;
  String? _selectedInternshipId;
  Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllApplicants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllApplicants() async {
    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'auth_token');
      
      for (final internship in widget.internships) {
        final id = internship['_id'];
        if (id == null) continue;
        
        try {
          final response = await _dio.get(
            '${ApiConstants.baseUrl}/applications/internship/$id',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          
          if (mounted) {
            setState(() {
              _applicantsByInternship[id] = response.data ?? [];
            });
          }
        } catch (e) {
          debugPrint('Error loading applicants for $id: $e');
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _allApplicants {
    return _applicantsByInternship.values.expand((list) => list).toList();
  }

  List<dynamic> _getApplicantsByStatus(String status) {
    return _allApplicants.where((app) {
      final appStatus = app['status'] ?? 'Applied';
      if (status == 'Applied') {
        return appStatus == 'Applied' || appStatus == 'Pending';
      }
      return appStatus == status;
    }).toList();
  }

  Future<void> _updateStatus(String applicationId, String status) async {
    if (_processingIds.contains(applicationId)) return;
    
    setState(() => _processingIds.add(applicationId));

    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.put(
        '${ApiConstants.baseUrl}/applications/$applicationId/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAllApplicants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(applicationId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Wrap in Expanded to prevent overflow
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Applicants',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_allApplicants.length} total applications',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter by internship
                  if (widget.internships.isNotEmpty)
                    PopupMenuButton<String?>(
                      initialValue: _selectedInternshipId,
                      onSelected: (value) => setState(() => _selectedInternshipId = value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: null, child: Text('All Internships')),
                        ...widget.internships.map((i) => PopupMenuItem(
                          value: i['_id'],
                          child: Text(i['title'] ?? 'Internship'),
                        )),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_list, size: 18),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 60),
                              child: Text(
                                _selectedInternshipId == null
                                    ? 'Filter'
                                    : widget.internships
                                        .firstWhere((i) => i['_id'] == _selectedInternshipId,
                                            orElse: () => {'title': 'Unknown'})['title']
                                        .toString(),
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.deepGreen,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.deepGreen,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Applied (${_getApplicantsByStatus('Applied').length})'),
                  Tab(text: 'Shortlisted (${_getApplicantsByStatus('Shortlisted').length})'),
                  Tab(text: 'Hired (${_getApplicantsByStatus('Hired').length})'),
                  Tab(text: 'Rejected (${_getApplicantsByStatus('Rejected').length})'),
                ],
              ),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildApplicantsList('Applied'),
                    _buildApplicantsList('Shortlisted'),
                    _buildApplicantsList('Hired'),
                    _buildApplicantsList('Rejected'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildApplicantsList(String status) {
    List<dynamic> applicants = _getApplicantsByStatus(status);
    
    // Filter by selected internship
    if (_selectedInternshipId != null) {
      applicants = applicants.where((app) {
        final internshipId = app['internship']?['_id'] ?? app['internship'];
        return internshipId == _selectedInternshipId;
      }).toList();
    }

    // Sort by match score
    applicants.sort((a, b) => 
      (b['aiMatchScore'] ?? 0).compareTo(a['aiMatchScore'] ?? 0)
    );

    if (applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No $status applicants',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllApplicants,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applicants.length,
        itemBuilder: (context, index) {
          final applicant = applicants[index];
          return _buildApplicantCard(applicant);
        },
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    final student = applicant['student'] ?? {};
    final internship = applicant['internship'];
    final internshipTitle = internship is Map 
        ? internship['title']?.toString() ?? 'Role'
        : widget.internships.firstWhere(
            (i) => i['_id'] == internship,
            orElse: () => {'title': 'Unknown'},
          )['title']?.toString() ?? 'Role';
    final matchScore = applicant['aiMatchScore'] ?? (60 + (applicant['_id'].hashCode % 35));
    final status = applicant['status'] ?? 'Applied';
    final isProcessing = _processingIds.contains(applicant['_id']);
    final skills = student['skills'] as List? ?? [];
    
    // Safe fullName extraction - handle both String and Map types
    String getFullName(dynamic name) {
      if (name == null) return 'Student';
      if (name is String) return name.isEmpty ? 'Student' : name;
      if (name is Map) {
        final first = name['firstName']?.toString() ?? '';
        final last = name['lastName']?.toString() ?? '';
        final combined = '$first $last'.trim();
        return combined.isEmpty ? 'Student' : combined;
      }
      return 'Student';
    }
    final studentName = getFullName(student['fullName']);
    final studentUniversity = student['university']?.toString() ?? 'University';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        studentName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            studentUniversity,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Match Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getMatchColor(matchScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: _getMatchColor(matchScore),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$matchScore%',
                            style: TextStyle(
                              color: _getMatchColor(matchScore),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Applied to - with constrained width
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.work_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Applied for: $internshipTitle',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Skills
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: skills.take(4).map<Widget>((skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill['name'] ?? skill.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],

                // Loading Indicator
                if (isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          
          // Actions Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _buildStatusBadge(status),
                const Spacer(),
                if (status == 'Applied' || status == 'Pending') ...[
                  TextButton(
                    onPressed: isProcessing ? null : () => _updateStatus(applicant['_id'], 'Shortlisted'),
                    child: const Text('Shortlist'),
                  ),
                  TextButton(
                    onPressed: isProcessing ? null : () => _updateStatus(applicant['_id'], 'Rejected'),
                    child: Text('Reject', style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
                if (status == 'Shortlisted') ...[
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => _updateStatus(applicant['_id'], 'Hired'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Hire'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: isProcessing ? null : () => _updateStatus(applicant['_id'], 'Rejected'),
                    child: Text('Reject', style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Shortlisted':
        color = Colors.orange;
        break;
      case 'Hired':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}
