import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/constants/api_constants.dart';
import 'change_password_page.dart';
import '../../../../auth/presentation/pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Dio _dio = createDio();
  final _storage = const FlutterSecureStorage();
  
  // Settings state
  bool _profileVisible = true;
  bool _allowResumeDownload = true;
  bool _pushNotifications = true;
  bool _applicationAlerts = true;
  bool _recommendationAlerts = true;
  bool _autoApplyConfirmation = true;
  bool _saveBeforeApplying = false;
  bool _darkMode = false;
  bool _reduceAnimations = false;
  
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final token = await _storage.read(key: 'auth_token');

      // 1. Fetch Profile (for Email)
      try {
        final profileResponse = await _dio.get(
          '${ApiConstants.baseUrl}/student/profile',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        if (profileResponse.statusCode == 200) {
          final data = profileResponse.data;
          // Extract email from nested user object or root
          if (data['user'] != null && data['user']['email'] != null) {
            _email = data['user']['email'];
          } else if (data['email'] != null) {
            _email = data['email'];
          }
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }

      // 2. Fetch Settings (for Toggles)
      try {
        final response = await _dio.get(
          '${ApiConstants.baseUrl}/student/settings',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (response.statusCode == 200) {
          final settings = response.data;
          // Apply settings if available
          _profileVisible = settings['profileVisible'] ?? true;
          _allowResumeDownload = settings['allowResumeDownload'] ?? true;
          _pushNotifications = settings['pushNotifications'] ?? true;
          _applicationAlerts = settings['applicationAlerts'] ?? true;
          _recommendationAlerts = settings['recommendationAlerts'] ?? true;
          _autoApplyConfirmation = settings['autoApplyConfirmation'] ?? true;
          _saveBeforeApplying = settings['saveBeforeApplying'] ?? false;
          _darkMode = settings['darkMode'] ?? false;
          _reduceAnimations = settings['reduceAnimations'] ?? false;
        }
      } catch (e) {
        // Settings endpoint might not exist yet, use defaults
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.put(
        '${ApiConstants.baseUrl}/student/settings',
        data: {key: value},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('Error updating setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSection(
                  title: 'Account Settings',
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: _email.isNotEmpty ? _email : 'Not set',
                      trailing: const Text(
                        'Read-only',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    _buildActionTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                _buildSection(
                  title: 'Profile Settings',
                  icon: Icons.edit_outlined,
                  children: [
                    _buildActionTile(
                      icon: Icons.person,
                      title: 'Edit Personal Details',
                      subtitle: 'Update name, university, degree',
                      onTap: () {
                        Navigator.pop(context); // Go back to profile
                        // Profile page has edit button
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.psychology_outlined,
                      title: 'Update Skills & Interests',
                      subtitle: 'Manage your skill set',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.description_outlined,
                      title: 'Update Resume',
                      subtitle: 'Upload new resume or portfolio',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),

                _buildSection(
                  title: 'Privacy & Security',
                  icon: Icons.security_outlined,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.visibility_outlined,
                      title: 'Profile Visibility',
                      subtitle: 'Allow companies to view your profile',
                      value: _profileVisible,
                      onChanged: (value) {
                        setState(() => _profileVisible = value);
                        _updateSetting('profileVisible', value);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.download_outlined,
                      title: 'Allow Resume Download',
                      subtitle: 'Companies can download your resume',
                      value: _allowResumeDownload,
                      onChanged: (value) {
                        setState(() => _allowResumeDownload = value);
                        _updateSetting('allowResumeDownload', value);
                      },
                    ),
                  ],
                ),

                _buildSection(
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Enable all notifications',
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() => _pushNotifications = value);
                        _updateSetting('pushNotifications', value);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.check_circle_outline,
                      title: 'Application Status Alerts',
                      subtitle: 'Get notified on application updates',
                      value: _applicationAlerts,
                      onChanged: (value) {
                        setState(() => _applicationAlerts = value);
                        _updateSetting('applicationAlerts', value);
                      },
                      enabled: _pushNotifications,
                    ),
                    _buildSwitchTile(
                      icon: Icons.lightbulb_outline,
                      title: 'Recommendation Alerts',
                      subtitle: 'New internship suggestions',
                      value: _recommendationAlerts,
                      onChanged: (value) {
                        setState(() => _recommendationAlerts = value);
                        _updateSetting('recommendationAlerts', value);
                      },
                      enabled: _pushNotifications,
                    ),
                  ],
                ),

                _buildSection(
                  title: 'Application Preferences',
                  icon: Icons.work_outline,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.check_outlined,
                      title: 'Auto-Apply Confirmation',
                      subtitle: 'Confirm before submitting application',
                      value: _autoApplyConfirmation,
                      onChanged: (value) {
                        setState(() => _autoApplyConfirmation = value);
                        _updateSetting('autoApplyConfirmation', value);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.bookmark_outline,
                      title: 'Save Before Applying',
                      subtitle: 'Auto-save internships you apply to',
                      value: _saveBeforeApplying,
                      onChanged: (value) {
                        setState(() => _saveBeforeApplying = value);
                        _updateSetting('saveBeforeApplying', value);
                      },
                    ),
                  ],
                ),

                _buildSection(
                  title: 'App Preferences',
                  icon: Icons.palette_outlined,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'Use dark theme (coming soon)',
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() => _darkMode = value);
                        _updateSetting('darkMode', value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dark mode coming soon!'),
                            backgroundColor: AppColors.mediumGreen,
                          ),
                        );
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.speed_outlined,
                      title: 'Reduce Animations',
                      subtitle: 'Better performance on low-end devices',
                      value: _reduceAnimations,
                      onChanged: (value) {
                        setState(() => _reduceAnimations = value);
                        _updateSetting('reduceAnimations', value);
                      },
                    ),
                  ],
                ),

                _buildSection(
                  title: 'Help & Support',
                  icon: Icons.help_outline,
                  children: [
                    _buildActionTile(
                      icon: Icons.quiz_outlined,
                      title: 'FAQ',
                      subtitle: 'Frequently asked questions',
                      onTap: () => _showFAQ(),
                    ),
                    _buildActionTile(
                      icon: Icons.support_agent_outlined,
                      title: 'Contact Support',
                      subtitle: 'Get help or report an issue',
                      onTap: () => _contactSupport(),
                    ),
                    _buildInfoTile(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      subtitle: '1.0.0 (Build 1)',
                    ),
                  ],
                ),

                _buildSection(
                  title: 'Legal',
                  icon: Icons.gavel_outlined,
                  children: [
                    _buildActionTile(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      subtitle: 'Read our terms of service',
                      onTap: () => _showTerms(),
                    ),
                    _buildActionTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'How we handle your data',
                      onTap: () => _showPrivacyPolicy(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? AppColors.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.deepGreen,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: trailing,
    );
  }

  void _showFAQ() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _buildFAQItem(
                      'How do I apply for an internship?',
                      'Browse internships on the Home tab, tap on one to view details, then click "Apply Now" button.',
                    ),
                    _buildFAQItem(
                      'Can I edit my application after submitting?',
                      'No, applications cannot be edited once submitted. However, you can withdraw and reapply.',
                    ),
                    _buildFAQItem(
                      'How does the AI matching work?',
                      'Our AI analyzes your skills, interests, and profile to match you with relevant internships.',
                    ),
                    _buildFAQItem(
                      'What if I forget my password?',
                      'Use the "Forgot Password" link on the login page to reset your password via email.',
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

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Reach out to us:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text('support@skillmatch.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text('+91-1800-SKILL-MATCH'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalDocumentPage(
          title: 'Terms & Conditions',
          content: '''
Terms & Conditions

Last updated: January 2026

1. Acceptance of Terms
By using SkillMatch, you agree to these terms and conditions.

2. User Accounts
- You must provide accurate information
- Keep your password secure
- You are responsible for all activities under your account

3. Internship Applications
- Applications are binding once submitted
- False information may result in account suspension
- Companies have the right to reject applications

4. Intellectual Property
All content and features are owned by SkillMatch.

5. Privacy
We respect your privacy. See our Privacy Policy for details.

6. Termination
We reserve the right to suspend or terminate accounts that violate these terms.

7. Changes to Terms
We may update these terms. Continued use implies acceptance.

8. Contact
For questions, contact support@skillmatch.com
          ''',
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalDocumentPage(
          title: 'Privacy Policy',
          content: '''
Privacy Policy

Last updated: January 2026

1. Information We Collect
- Personal information (name, email, phone)
- Educational details (university, degree)
- Professional skills and resume
- Application history

2. How We Use Your Information
- Match you with relevant internships
- Process your applications
- Improve our AI algorithms
- Send notifications about applications

3. Information Sharing
- Your profile is visible to approved companies
- Resume can be downloaded by companies (if enabled)
- We never sell your data to third parties

4. Data Security
- All data is encrypted in transit and at rest
- We use industry-standard security measures
- Regular security audits

5. Your Rights
- Access your data anytime
- Request data deletion
- Control profile visibility
- Opt-out of communications

6. Cookies
We use cookies to improve user experience.

7. Changes to Policy
We may update this policy. We'll notify you of significant changes.

8. Contact
Privacy questions? Email privacy@skillmatch.com
          ''',
        ),
      ),
    );
  }
}

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          content,
          style: const TextStyle(height: 1.6, fontSize: 14),
        ),
      ),
    );
  }
}
