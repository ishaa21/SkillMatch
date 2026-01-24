import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/constants/asset_constants.dart';
import '../../../../../core/utils/dio_client.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';

class InternshipDetailsPage extends StatefulWidget {
  final Map<String, dynamic> internship;

  const InternshipDetailsPage({super.key, required this.internship});

  @override
  State<InternshipDetailsPage> createState() => _InternshipDetailsPageState();
}

class _InternshipDetailsPageState extends State<InternshipDetailsPage> {
  bool _isApplying = false;
  bool _hasApplied = false;
  bool _isCheckingStatus = true;
  bool _isSaved = false;
  final Dio _dio = createDio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        setState(() => _isCheckingStatus = false);
        return;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/applications/my-applications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted && response.statusCode == 200) {
        final applications = response.data as List;
        final internshipId = widget.internship['_id']?.toString() ?? '';
        
        final alreadyApplied = applications.any((app) {
          final appInternshipId = app['internship']?['_id']?.toString() ?? 
              app['internshipId']?.toString() ?? '';
          return appInternshipId == internshipId;
        });

        setState(() {
          _hasApplied = alreadyApplied;
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking application status: $e');
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _applyToInternship() async {
    if (_hasApplied) return;
    
    setState(() => _isApplying = true);
    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.post(
        '${ApiConstants.baseUrl}/applications',
        data: {
          'internshipId': widget.internship['_id'],
          'coverLetter': 'I am interested in this role and believe my skills align well with your requirements.'
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        setState(() => _hasApplied = true);
        _showSuccessDialog();
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to apply';
        
        if (e.response?.statusCode == 400 || e.response?.statusCode == 409) {
          final message = e.response?.data['message'] ?? '';
          if (message.toLowerCase().contains('already applied')) {
            setState(() => _hasApplied = true);
            errorMessage = 'You have already applied to this internship';
          } else {
            errorMessage = message;
          }
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Session expired. Please login again.';
        } else if (e.response?.statusCode == 500) {
          debugPrint('Server Error Details: ${e.response?.data}');
          errorMessage = 'Server error: ${e.response?.data['message'] ?? 'Please try again later.'}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
       }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                AssetConstants.success,
                height: 150,
                repeat: false,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Application Sent!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Good luck! The company will review your profile soon. You can track your application status in the Applications tab.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                    Navigator.pop(context, true); // Close Page with result
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSave() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.post(
        '${ApiConstants.baseUrl}/student/saved-internships/${widget.internship['_id']}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      setState(() => _isSaved = !_isSaved);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSaved ? 'Saved to bookmarks' : 'Removed from bookmarks'),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = _getCompanyName();
    final matchPercentage = widget.internship['matchPercentage'] ?? 0;
    final skills = _getSkills();

    return Scaffold(
      body: Stack(
        children: [
          // Background Header
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.deepGreen,
                  AppColors.mediumGreen.withOpacity(0.9),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _toggleSave,
                            icon: Icon(
                              _isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              Share.share(
                                'Check out this ${widget.internship['title']} at ${companyName}!\n\nApply here: https://skillmatch.app/internship/${widget.internship['_id']}',
                              );
                            },
                            icon: const Icon(Icons.share, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Content Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company Logo & Basic Info
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.deepGreen,
                                        AppColors.mediumGreen,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.deepGreen.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.internship['title']?.toString() ?? 'Internship Role',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  companyName,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Match Badge
                                if (matchPercentage > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _getMatchColor(matchPercentage).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.stars,
                                          size: 18,
                                          color: _getMatchColor(matchPercentage),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$matchPercentage% Match',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getMatchColor(matchPercentage),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Key Details - Responsive layout
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Use scroll on smaller screens
                                if (constraints.maxWidth < 320) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildDetailItem(
                                          Icons.location_on_outlined,
                                          widget.internship['workMode']?.toString() ?? 'Remote',
                                          'Work Mode',
                                        ),
                                        const SizedBox(width: 16),
                                        _buildDivider(),
                                        const SizedBox(width: 16),
                                        _buildDetailItem(
                                          Icons.schedule_outlined,
                                          _getDuration(),
                                          'Duration',
                                        ),
                                        const SizedBox(width: 16),
                                        _buildDivider(),
                                        const SizedBox(width: 16),
                                        _buildDetailItem(
                                          Icons.payments_outlined,
                                          '${_getFormattedStipend()}/mo',
                                          'Stipend',
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                // Normal layout for larger screens
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Flexible(
                                      child: _buildDetailItem(
                                        Icons.location_on_outlined,
                                        widget.internship['workMode']?.toString() ?? 'Remote',
                                        'Work Mode',
                                      ),
                                    ),
                                    _buildDivider(),
                                    Flexible(
                                      child: _buildDetailItem(
                                        Icons.schedule_outlined,
                                        _getDuration(),
                                        'Duration',
                                      ),
                                    ),
                                    _buildDivider(),
                                    Flexible(
                                      child: _buildDetailItem(
                                        Icons.payments_outlined,
                                        '${_getFormattedStipend()}/mo',
                                        'Stipend',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // About Section
                          _buildSectionTitle('About the Role'),
                          const SizedBox(height: 12),
                          Text(
                            widget.internship['description']?.toString() ?? 
                                'Join our dynamic team and work on exciting projects that make a real impact. You will collaborate with experienced professionals and gain valuable industry experience.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.6,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Responsibilities
                          _buildSectionTitle('Responsibilities'),
                          const SizedBox(height: 12),
                          ..._buildResponsibilities(),
                          const SizedBox(height: 28),

                          // Skills Section
                          _buildSectionTitle('Skills Required'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills.map<Widget>((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 28),

                          // Company Info
                          _buildSectionTitle('About the Company'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      companyName.isNotEmpty ? companyName[0] : 'C',
                                      style: const TextStyle(
                                        fontSize: 20,
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
                                        companyName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Technology & Software',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('View'),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 120), // Space for bottom button
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Apply Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
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
              child: _buildApplyButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    if (_isCheckingStatus) {
      return const Center(
        child: SizedBox(
          height: 50,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasApplied) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.mediumGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mediumGreen),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.mediumGreen),
            SizedBox(width: 8),
            Text(
              'Already Applied',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.mediumGreen,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isApplying ? null : _applyToInternship,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.deepGreen,
        disabledBackgroundColor: Colors.grey,
      ),
      child: _isApplying
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Apply Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade300,
    );
  }

  List<Widget> _buildResponsibilities() {
    final responsibilities = [
      'Collaborate with cross-functional teams',
      'Develop and maintain code quality',
      'Participate in code reviews',
      'Work on real-world projects',
    ];

    return responsibilities.map((r) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              r,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  String _getCompanyName() {
    try {
      if (widget.internship['companyDetails'] != null && widget.internship['companyDetails'] is Map) {
        return widget.internship['companyDetails']['companyName']?.toString() ?? 'Company';
      }
      final company = widget.internship['company'];
      if (company is Map) {
        return company['companyName']?.toString() ?? 'Company';
      }
      return 'Company';
    } catch (e) {
      return 'Company';
    }
  }

  List<String> _getSkills() {
    try {
      final skills = widget.internship['skillsRequired'];
      if (skills == null) return ['General Skills'];
      if (skills is List) {
        return skills.map((s) => s.toString()).toList();
      }
      return ['General Skills'];
    } catch (e) {
      return ['General Skills'];
    }
  }

  String _getDuration() {
    try {
      final duration = widget.internship['duration'];
      if (duration == null) return 'N/A';
      
      // If it's a Map with displayString
      if (duration is Map && duration['displayString'] != null) {
        return duration['displayString'].toString();
      }
      
      // If it's already a string
      if (duration is String) {
        return duration;
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getFormattedStipend() {
    try {
      final stipend = widget.internship['stipend'];
      if (stipend == null) return 'Unpaid';
      
      if (stipend is Map) {
        final min = num.tryParse(stipend['min']?.toString() ?? '0') ?? 0;
        final max = num.tryParse(stipend['max']?.toString() ?? '0') ?? 0;
        final currency = stipend['currency'] == 'USD' ? '\$' : '₹';
        // Note: '/mo' is added in the UI widget call, so we just return the value here 
        // OR we can return value without /mo if consistent with the caller.
        // Looking at usage: '${_getFormattedStipend()}/mo', so we should return just the amount part.
        
        if (min <= 0 && max <= 0) return 'Unpaid';

        if (min == max) {
          return '$currency$min';
        }
        return '$currency$min - $currency$max';
      }

      if (stipend is String) return stipend;
      
      return 'Unpaid';
    } catch (e) {
      return 'Unpaid';
    }
  }


  Color _getMatchColor(int percentage) {
    if (percentage >= 85) return Colors.green.shade600;
    if (percentage >= 70) return Colors.orange.shade600;
    return Colors.blue.shade600;
  }
}
