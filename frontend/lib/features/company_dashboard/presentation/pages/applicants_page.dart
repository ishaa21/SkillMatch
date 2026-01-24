import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/asset_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';

class ApplicantsPage extends StatefulWidget {
  final String internshipId;
  final String internshipTitle;

  const ApplicantsPage({
    super.key,
    required this.internshipId,
    required this.internshipTitle,
  });

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  List<dynamic> _applicants = [];
  bool _isLoading = true;
  bool _hasError = false;
  Set<String> _processingIds = {};
  String _filterStatus = 'All';

  final List<String> _statusFilters = ['All', 'Applied', 'Shortlisted', 'Hired', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/applications/internship/${widget.internshipId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        var applicants = response.data as List? ?? [];
        // Sort by match score descending
        applicants.sort((a, b) => 
          (b['aiMatchScore'] ?? 0).compareTo(a['aiMatchScore'] ?? 0)
        );
        
        setState(() {
          _applicants = applicants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  List<dynamic> get _filteredApplicants {
    if (_filterStatus == 'All') return _applicants;
    return _applicants.where((app) => app['status'] == _filterStatus).toList();
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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Applicant $status'),
              ],
            ),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadApplicants();
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

  void _showApplicantDetails(Map<String, dynamic> applicant) {
    final student = applicant['student'] ?? {};
    final matchScore = applicant['aiMatchScore'] ?? 0;
    final skills = student['skills'] as List? ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
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
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            (student['fullName'] ?? 'S')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['fullName'] ?? 'Student',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student['university'] ?? 'University',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getMatchColor(matchScore).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, 
                                size: 16, 
                                color: _getMatchColor(matchScore),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$matchScore% Match',
                                style: TextStyle(
                                  color: _getMatchColor(matchScore),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Bio
                    if (student['bio'] != null && student['bio'].toString().isNotEmpty) ...[
                      _buildDetailSection('About', student['bio']),
                      const SizedBox(height: 20),
                    ],
                    
                    // Education
                    _buildDetailSection(
                      'Education',
                      '${student['degree'] ?? 'Degree'} at ${student['university'] ?? 'University'}'
                      '\nGraduation: ${student['graduationYear'] ?? 'N/A'}',
                    ),
                    const SizedBox(height: 20),
                    
                    // Skills
                    const Text(
                      'Skills',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.isEmpty
                          ? [const Text('No skills listed')]
                          : skills.map<Widget>((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill['name'] ?? skill.toString(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (skill['proficiency'] != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '• ${skill['proficiency']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )).toList(),
                    ),
                    const SizedBox(height: 20),
                    
                    // Cover Letter
                    if (applicant['coverLetter'] != null && 
                        applicant['coverLetter'].toString().isNotEmpty) ...[
                      _buildDetailSection('Cover Letter', applicant['coverLetter']),
                      const SizedBox(height: 20),
                    ],
                    
                    // Contact
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactRow(Icons.email_outlined, student['user']?['email'] ?? 'Email not available'),
                    const SizedBox(height: 8),
                    _buildContactRow(Icons.phone_outlined, student['phone'] ?? 'Phone not available'),
                    
                    // Resume
                    if (student['resumeUrl'] != null) ...[
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Open resume
                        },
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('View Resume'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Actions
                    if (applicant['status'] != 'Hired' && applicant['status'] != 'Rejected')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateStatus(applicant['_id'], 'Rejected');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateStatus(
                                  applicant['_id'],
                                  applicant['status'] == 'Shortlisted' ? 'Hired' : 'Shortlisted',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                applicant['status'] == 'Shortlisted' ? 'Hire' : 'Shortlist',
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.internshipTitle),
            Text(
              '${_applicants.length} applicants',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((status) {
                  final isSelected = _filterStatus == status;
                  final count = status == 'All'
                      ? _applicants.length
                      : _applicants.where((a) => a['status'] == status).length;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$status ($count)'),
                      selected: isSelected,
                      selectedColor: AppColors.deepGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() => _filterStatus = status);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Lottie.asset(
          AssetConstants.loading,
          height: 150,
          errorBuilder: (_, __, ___) => const CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text('Failed to load applicants'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadApplicants,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final applicants = _filteredApplicants;

    if (applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AssetConstants.empty,
              height: 150,
              errorBuilder: (_, __, ___) => Icon(
                Icons.inbox_outlined,
                size: 60,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _filterStatus == 'All'
                  ? 'No applications yet'
                  : 'No $_filterStatus applicants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new applications',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplicants,
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
    final matchScore = applicant['aiMatchScore'] ?? 0;
    final status = applicant['status'] ?? 'Applied';
    final skills = student['skills'] as List? ?? [];
    final isProcessing = _processingIds.contains(applicant['_id']);

    return GestureDetector(
      onTap: () => _showApplicantDetails(applicant),
      child: Container(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with Rank
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              (student['fullName'] ?? 'S')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (matchScore >= 85)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['fullName'] ?? 'Student',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student['university'] ?? 'University',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Match Badge
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
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Skills
                  if (skills.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills.take(4).map<Widget>((skill) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            skill['name'] ?? skill.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),

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
                      onPressed: isProcessing 
                          ? null 
                          : () => _updateStatus(applicant['_id'], 'Shortlisted'),
                      child: const Text('Shortlist'),
                    ),
                    TextButton(
                      onPressed: isProcessing 
                          ? null 
                          : () => _updateStatus(applicant['_id'], 'Rejected'),
                      child: Text('Reject', style: TextStyle(color: Colors.red.shade700)),
                    ),
                  ],
                  if (status == 'Shortlisted') ...[
                    ElevatedButton(
                      onPressed: isProcessing 
                          ? null 
                          : () => _updateStatus(applicant['_id'], 'Hired'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text('Hire'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: isProcessing 
                          ? null 
                          : () => _updateStatus(applicant['_id'], 'Rejected'),
                      child: Text('Reject', style: TextStyle(color: Colors.red.shade700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Shortlisted':
        color = Colors.orange;
        icon = Icons.star_outline;
        break;
      case 'Hired':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'Rejected':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.blue;
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 50) return Colors.blue;
    return Colors.grey;
  }
}
