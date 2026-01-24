import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import 'add_skill_modal.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import '../../../../auth/data/auth_service.dart';
import '../../../../auth/presentation/pages/login_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/constants/api_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../saved_internships_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _profileData;
  List<dynamic> _skills = [];
  String _resumeName = 'No resume uploaded';
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final _storage = const FlutterSecureStorage();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/student/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted && response.statusCode == 200) {
        debugPrint('DEBUG: Profile data fetched: ${response.data}');
        debugPrint('DEBUG: Bio value: ${response.data['bio']}');
        setState(() {
          _profileData = response.data;
          _skills = response.data['skills'] ?? [];
          final url = response.data['resumeUrl'];
          _resumeName = url != null ? url.split('/').last : 'No resume uploaded';
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

  int _calculateCompletionPercentage() {
    if (_profileData == null) return 0;
    
    int filled = 0;
    const int total = 7;

    if (_profileData!['fullName'] != null && _profileData!['fullName'].toString().isNotEmpty) filled++;
    if (_profileData!['phone'] != null && _profileData!['phone'].toString().isNotEmpty) filled++;
    if (_profileData!['university'] != null && _profileData!['university'].toString().isNotEmpty) filled++;
    if (_profileData!['degree'] != null && _profileData!['degree'].toString().isNotEmpty) filled++;
    if ((_profileData!['skills'] as List?)?.isNotEmpty ?? false) filled++;
    if (_profileData!['resumeUrl'] != null && _profileData!['resumeUrl'].toString().isNotEmpty) filled++;
    if (_profileData!['bio'] != null && _profileData!['bio'].toString().isNotEmpty) filled++;

    return ((filled / total) * 100).round();
  }

  Future<void> _updateResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() => _isLoading = true);
        
        FormData formData;
        
        if (kIsWeb) {
          if (result.files.single.bytes == null) {
            throw Exception("No file data found. Please try again.");
          }
          formData = FormData.fromMap({
            'resume': MultipartFile.fromBytes(
              result.files.single.bytes!,
              filename: result.files.single.name,
            ),
          });
        } else {
          if (result.files.single.path == null) throw Exception("No file path");
          formData = FormData.fromMap({
            'resume': await MultipartFile.fromFile(
              result.files.single.path!,
              filename: result.files.single.name,
            ),
          });
        }

        final token = await _storage.read(key: 'auth_token');
        
        final response = await _dio.post(
          '${ApiConstants.baseUrl}/student/resume',
          data: formData,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (mounted && response.statusCode == 200) {
          setState(() {
            _resumeName = result.files.single.name;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Resume uploaded successfully!'),
                ],
              ),
              backgroundColor: AppColors.deepGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddSkillModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSkillModal(
        onSkillAdded: (skillName, proficiency) async {
          // Update locally first
          setState(() {
            final existingIndex = _skills.indexWhere((s) => s['name'] == skillName);
            if (existingIndex != -1) {
              _skills[existingIndex]['proficiency'] = proficiency;
            } else {
              _skills.add({'name': skillName, 'proficiency': proficiency});
            }
          });

          // Update on server
          try {
            final token = await _storage.read(key: 'auth_token');
            await _dio.put(
              '${ApiConstants.baseUrl}/student/profile',
              data: {'skills': _skills},
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$skillName added with $proficiency level!'),
                  backgroundColor: AppColors.deepGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error saving skill: $e');
          }
        },
      ),
    );
  }

  void _removeSkill(int index) async {
    final skill = _skills[index];
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Skill'),
        content: Text('Are you sure you want to remove "${skill['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _skills.removeAt(index);
      });

      // Update on server
      try {
        final token = await _storage.read(key: 'auth_token');
        await _dio.put(
          '${ApiConstants.baseUrl}/student/profile',
          data: {'skills': _skills},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (e) {
        debugPrint('Error removing skill: $e');
      }
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          profileData: _profileData,
          onProfileUpdated: _fetchProfile,
        ),
      ),
    );

    if (result == true) {
      _fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: _navigateToEditProfile,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: AppColors.deepGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? _buildErrorState()
                : _buildProfileContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final completionPercent = _calculateCompletionPercentage();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(completionPercent),
          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 24),

          // About Me / Bio Section
          _buildSection(
            title: 'About Me',
            icon: Icons.info_outline,
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              onPressed: _navigateToEditProfile,
            ),
            child: _buildBioSection(),
          ),

          // Saved Internships Link
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bookmark, color: AppColors.primary),
              ),
              title: const Text(
                'Saved Internships',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedInternshipsPage()),
                );
              },
            ),
          ),

          // Resume Section
          _buildSection(
            title: 'Resume',
            icon: Icons.description_outlined,
            trailing: TextButton.icon(
              onPressed: _isLoading ? null : _updateResume,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Update'),
            ),
            child: _buildResumeCard(),
          ),

          // Skills Section
          _buildSection(
            title: 'Skills',
            icon: Icons.psychology_outlined,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, size: 24, color: AppColors.primary),
              onPressed: _showAddSkillModal,
            ),
            child: _skills.isEmpty
                ? _buildEmptySkills()
                : _buildSkillsList(),
          ),

          // Contact Info Section
          _buildSection(
            title: 'Contact Information',
            icon: Icons.contact_mail_outlined,
            child: _buildContactInfo(),
          ),

          // Education Section
          _buildSection(
            title: 'Education',
            icon: Icons.school_outlined,
            child: _buildEducationInfo(),
          ),

          const SizedBox(height: 24),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(int completionPercent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Progress Ring
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: completionPercent / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completionPercent < 50 
                        ? Colors.orange 
                        : completionPercent < 80 
                            ? AppColors.mediumGreen 
                            : AppColors.deepGreen,
                  ),
                ),
              ),
              // Avatar
              GestureDetector(
                onTap: _navigateToEditProfile,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _profileData?['fullName'] != null
                            ? _profileData!['fullName'][0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _profileData?['fullName'] ?? 'Student Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_profileData?['university'] ?? 'University'} • ${_profileData?['degree'] ?? 'Degree'}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildCompletionBadge(completionPercent),
          if (_profileData?['bio'] != null && _profileData!['bio'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _profileData!['bio'],
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.psychology_outlined,
            value: '${_skills.length}',
            label: 'Skills',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.description_outlined,
            value: _profileData?['resumeUrl'] != null ? '1' : '0',
            label: 'Resume',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.school_outlined,
            value: _profileData?['graduationYear']?.toString() ?? '—',
            label: 'Grad Year',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBadge(int percent) {
    Color badgeColor = percent < 50 
        ? Colors.orange 
        : percent < 80 
            ? AppColors.mediumGreen 
            : AppColors.deepGreen;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percent >= 100 ? Icons.verified : Icons.trending_up,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            '$percent% Profile Complete',
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Responsive header row that handles overflow
          Row(
            children: [
              // Title section wrapped in Flexible to prevent overflow
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    final bio = _profileData?['bio']?.toString() ?? '';
    
    if (bio.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.edit_note_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No bio added yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a bio to tell employers about yourself',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _navigateToEditProfile,
              child: const Text('Add Bio'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softMint.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mediumGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote, color: AppColors.mediumGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Bio',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCard() {
    final hasResume = _profileData?['resumeUrl'] != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasResume ? Colors.green.shade50 : Colors.grey.shade50,
        border: Border.all(
          color: hasResume ? Colors.green.shade200 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasResume ? Colors.green.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasResume ? Icons.picture_as_pdf : Icons.upload_file,
              color: hasResume ? Colors.red : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resumeName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  hasResume ? 'Uploaded successfully' : 'No resume uploaded yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (hasResume)
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: AppColors.primary),
              onPressed: () {
                // View resume functionality
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySkills() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No skills added yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your skills to get better matches',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _skills.asMap().entries.map((entry) {
        final index = entry.key;
        final skill = entry.value;
        return _buildSkillChip(
          skill['name'] ?? '',
          skill['proficiency'] ?? 'Intermediate',
          onRemove: () => _removeSkill(index),
        );
      }).toList(),
    );
  }

  Widget _buildSkillChip(String label, String level, {VoidCallback? onRemove}) {
    Color levelColor;
    switch (level) {
      case 'Expert':
        levelColor = AppColors.deepGreen;
        break;
      case 'Advanced':
        levelColor = AppColors.mediumGreen;
        break;
      default:
        levelColor = Colors.grey.shade600;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: levelColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        _buildInfoRow(Icons.email_outlined, 'Email', _profileData?['email'] ?? 'Not set'),
        const Divider(height: 24),
        _buildInfoRow(Icons.phone_outlined, 'Phone', _profileData?['phone'] ?? 'Not set'),
        if (_profileData?['linkedin'] != null) ...[
          const Divider(height: 24),
          _buildInfoRow(Icons.link, 'LinkedIn', _profileData!['linkedin']),
        ],
        if (_profileData?['github'] != null) ...[
          const Divider(height: 24),
          _buildInfoRow(Icons.code, 'GitHub', _profileData!['github']),
        ],
      ],
    );
  }

  Widget _buildEducationInfo() {
    return Column(
      children: [
        _buildInfoRow(Icons.school_outlined, 'University', _profileData?['university'] ?? 'Not set'),
        const Divider(height: 24),
        _buildInfoRow(Icons.book_outlined, 'Degree', _profileData?['degree'] ?? 'Not set'),
        const Divider(height: 24),
        _buildInfoRow(Icons.calendar_today_outlined, 'Graduation Year', 
            _profileData?['graduationYear']?.toString() ?? 'Not set'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 20),
        const SizedBox(width: 12),
        // Wrap in Expanded to prevent horizontal overflow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                // Handle long text (emails, URLs) with ellipsis
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}
