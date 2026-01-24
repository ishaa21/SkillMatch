import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/constants/api_constants.dart';
import '../company_profile_page.dart';
import '../../../../student_dashboard/presentation/pages/profile/change_password_page.dart'; // Reusing for now

class CompanySettingsPage extends StatefulWidget {
  const CompanySettingsPage({super.key});

  @override
  State<CompanySettingsPage> createState() => _CompanySettingsPageState();
}

class _CompanySettingsPageState extends State<CompanySettingsPage> {
  final Dio _dio = createDio();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;

  // Access & Security
  String _email = '';

  // Internship Preferences
  String _defaultDuration = '3 Months';
  String _defaultWorkMode = 'Remote';
  String _defaultStipendRange = '10k - 20k';
  bool _autoCloseAfterDeadline = true;

  // Application Management
  bool _acceptingApplications = true;
  bool _autoShortlisting = false;
  bool _autoRejectExpired = false;
  int _maxApplicationsPerInternship = 50;

  // Notifications
  bool _emailAlerts = true;
  bool _shortlistNotifications = true;
  bool _approvalRejectionNotifications = true;
  bool _systemAnnouncements = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      // Load Company Profile for Email/CIN status
      final profileResponse = await _dio.get(
        '${ApiConstants.baseUrl}/company/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (profileResponse.statusCode == 200) {
        final data = profileResponse.data;
        if (data['user'] != null && data['user']['email'] != null) {
          _email = data['user']['email'];
        }
      }

      // Load Settings (Mock for now or real endpoint)
      try {
        final settingsResponse = await _dio.get(
          '${ApiConstants.baseUrl}/company/settings',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        
        if (settingsResponse.statusCode == 200) {
          final settings = settingsResponse.data;
          setState(() {
            _defaultDuration = settings['defaultDuration'] ?? '3 Months';
            _defaultWorkMode = settings['defaultWorkMode'] ?? 'Remote';
            _autoCloseAfterDeadline = settings['autoCloseAfterDeadline'] ?? true;
            _acceptingApplications = settings['acceptingApplications'] ?? true;
            _autoShortlisting = settings['autoShortlisting'] ?? false;
            _autoRejectExpired = settings['autoRejectExpired'] ?? false;
            _emailAlerts = settings['emailAlerts'] ?? true;
          });
        }
      } catch (e) {
        // Just use defaults if settings endpoint doesn't exist
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.put(
        '${ApiConstants.baseUrl}/company/settings',
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
        title: const Text('Company Settings'),
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
                // 1. Company Profile
                _buildSection(
                  title: 'Company Profile',
                  icon: Icons.business,
                  children: [
                    _buildActionTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile Details',
                      subtitle: 'Name, logo, description, industry',
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CompanyProfilePage()),
                        );
                      },
                    ),
                    _buildInfoTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Verification Status',
                      subtitle: 'Verified', // Should be dynamic
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  ],
                ),

                // 2. Account & Security
                _buildSection(
                  title: 'Account & Security',
                  icon: Icons.lock_outline,
                  children: [
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      title: 'Registered Email',
                      subtitle: _email.isNotEmpty ? _email : 'Not loading',
                    ),
                    _buildActionTile(
                      icon: Icons.password,
                      title: 'Change Password',
                      subtitle: 'Update your login password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                        );
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.logout,
                      title: 'Logout All Devices',
                      subtitle: 'Secure your account',
                      onTap: () {},
                    ),
                  ],
                ),

                // 3. Verification & Compliance
                _buildSection(
                  title: 'Verification & Compliance',
                  icon: Icons.shield_outlined,
                  children: [
                    _buildActionTile(
                      icon: Icons.badge_outlined,
                      title: 'Update CIN / Registration',
                      subtitle: 'Resubmit for verification',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.download_outlined,
                      title: 'Download Certificate',
                      subtitle: 'Get your verified badge certificate',
                      onTap: () {},
                    ),
                  ],
                ),

                // 4. Internship Preferences
                _buildSection(
                  title: 'Internship Preferences',
                  icon: Icons.work_outline,
                  children: [
                    _buildDropdownTile(
                      icon: Icons.timer_outlined,
                      title: 'Default Duration',
                      value: _defaultDuration,
                      items: ['1 Month', '2 Months', '3 Months', '6 Months'],
                      onChanged: (val) {
                        setState(() => _defaultDuration = val!);
                        _updateSetting('defaultDuration', val);
                      },
                    ),
                    _buildDropdownTile(
                      icon: Icons.apartment_outlined,
                      title: 'Default Work Mode',
                      value: _defaultWorkMode,
                      items: ['Remote', 'On-site', 'Hybrid'],
                      onChanged: (val) {
                        setState(() => _defaultWorkMode = val!);
                        _updateSetting('defaultWorkMode', val);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.auto_delete_outlined,
                      title: 'Auto-close Internships',
                      subtitle: 'Close application after deadline',
                      value: _autoCloseAfterDeadline,
                      onChanged: (val) {
                        setState(() => _autoCloseAfterDeadline = val);
                        _updateSetting('autoCloseAfterDeadline', val);
                      },
                    ),
                  ],
                ),

                // 5. Application Management
                _buildSection(
                  title: 'Application Management',
                  icon: Icons.people_outline,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.person_add_alt,
                      title: 'Accept Applications',
                      subtitle: 'Enable/disable student applications',
                      value: _acceptingApplications,
                      onChanged: (val) {
                        setState(() => _acceptingApplications = val);
                        _updateSetting('acceptingApplications', val);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.psychology_outlined,
                      title: 'AI Auto-Shortlist',
                      subtitle: 'Auto-shortlist high AI match scores',
                      value: _autoShortlisting,
                      onChanged: (val) {
                        setState(() => _autoShortlisting = val);
                        _updateSetting('autoShortlisting', val);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.cancel_outlined,
                      title: 'Auto-Reject Expired',
                      subtitle: 'Reject if internship closes',
                      value: _autoRejectExpired,
                      onChanged: (val) {
                        setState(() => _autoRejectExpired = val);
                        _updateSetting('autoRejectExpired', val);
                      },
                    ),
                  ],
                ),

                // 6. Notifications
                _buildSection(
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.email_outlined,
                      title: 'Email Alerts',
                      subtitle: 'Get emails for new applications',
                      value: _emailAlerts,
                      onChanged: (val) {
                        setState(() => _emailAlerts = val);
                        _updateSetting('emailAlerts', val);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.star_border,
                      title: 'Shortlist Alerts',
                      subtitle: 'Notify when candidates accept',
                      value: _shortlistNotifications,
                      onChanged: (val) => setState(() => _shortlistNotifications = val),
                    ),
                  ],
                ),

                // 7. Analytics & Reports
                _buildSection(
                  title: 'Analytics & Reports',
                  icon: Icons.bar_chart,
                  children: [
                    _buildActionTile(
                      icon: Icons.download,
                      title: 'Download Applicant Report',
                      subtitle: 'Export data to CSV/PDF',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.trending_up,
                      title: 'View Performance',
                      subtitle: 'Check application trends',
                      onTap: () {},
                    ),
                  ],
                ),

                // 8. Platform Controls
                _buildSection(
                  title: 'Platform Controls',
                  icon: Icons.settings_applications,
                  children: [
                     _buildActionTile(
                      icon: Icons.support_agent,
                      title: 'Request Support',
                      subtitle: 'Contact admin team',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Company Account',
                      subtitle: 'Permanently remove your account',
                      onTap: () {},
                      isDestructive: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                 Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // --- Helper Widgets ---

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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.deepGreen,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black,
        ),
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: trailing,
    );
  }
  
  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
        ),
      ),
    );
  }
}
