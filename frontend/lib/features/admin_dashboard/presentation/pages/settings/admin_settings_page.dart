import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../student_dashboard/presentation/pages/profile/change_password_page.dart'; // Reusing

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final Dio _dio = createDio();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;

  // Account & Security
  String _lastLogin = 'Today, 10:30 AM';
  String _ipAddress = '192.168.1.1';

  // AI Matching Configuration
  bool _aiMatchingEnabled = true;
  double _skillsWeight = 0.4;
  double _experienceWeight = 0.3;
  double _domainWeight = 0.2;
  double _locationWeight = 0.1;

  // User Management
  bool _studentAccountsEnabled = true;
  bool _companyAccountsEnabled = true;

  // Company Compliance
  bool _mcaVerificationRequired = true;
  bool _manualCompanyApproval = true;

  // System & Platform
  int _internshipLimitPerCompany = 10;
  int _applicationLimitPerStudent = 50;
  bool _stipendMandatory = true;
  bool _remoteInternshipsEnabled = true;

  // Content Moderation
  bool _autoFlagging = true;
  bool _profanityDetection = true;

  // Analytics
  bool _analyticsTracking = true;

  // App Config
  bool _maintenanceMode = false;
  bool _apiRateLimiting = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      try {
        final response = await _dio.get(
          '${ApiConstants.baseUrl}/admin/settings',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (response.statusCode == 200) {
          final s = response.data;
          setState(() {
            _aiMatchingEnabled = s['aiMatchingEnabled'] ?? true;
            _skillsWeight = (s['skillsWeight'] ?? 40) / 100.0;
            _experienceWeight = (s['experienceWeight'] ?? 30) / 100.0;
            _domainWeight = (s['domainWeight'] ?? 20) / 100.0;
            _locationWeight = (s['locationWeight'] ?? 10) / 100.0;
            _studentAccountsEnabled = s['studentAccountsEnabled'] ?? true;
            _mcaVerificationRequired = s['mcaVerificationRequired'] ?? true;
            _maintenanceMode = s['maintenanceMode'] ?? false;
          });
        }
      } catch (e) {
        // Use defaults
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
        '${ApiConstants.baseUrl}/admin/settings',
        data: {key: value},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('Error updating setting: $e');
    }
  }

  void _resetAIWeights() {
    setState(() {
      _skillsWeight = 0.4;
      _experienceWeight = 0.3;
      _domainWeight = 0.2;
      _locationWeight = 0.1;
    });
    // Call API to reset
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Admin Settings'),
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
                // 1. Account & Security
                _buildSection(
                  title: 'Account & Security',
                  icon: Icons.security,
                  children: [
                    _buildInfoTile(
                      icon: Icons.history,
                      title: 'Last Login',
                      subtitle: '$_lastLogin (IP: $_ipAddress)',
                    ),
                    _buildActionTile(
                      icon: Icons.password,
                      title: 'Change Admin Password',
                      subtitle: 'Update your credentials',
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                        );
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.logout,
                      title: 'Logout All Session',
                      subtitle: 'Force logout all admin sessions',
                      onTap: () {},
                    ),
                  ],
                ),

                // 2. User Management
                _buildSection(
                  title: 'User Management',
                  icon: Icons.people_outline,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.school_outlined,
                      title: 'Student Accounts',
                      subtitle: 'Enable/disable student logins',
                      value: _studentAccountsEnabled,
                      onChanged: (v) => setState(() => _studentAccountsEnabled = v),
                    ),
                    _buildSwitchTile(
                      icon: Icons.business_outlined,
                      title: 'Company Accounts',
                      subtitle: 'Enable/disable company logins',
                      value: _companyAccountsEnabled,
                      onChanged: (v) => setState(() => _companyAccountsEnabled = v),
                    ),
                    _buildActionTile(
                      icon: Icons.lock_reset,
                      title: 'Reset User Passwords',
                      subtitle: 'Manual or forced reset',
                      onTap: () {},
                    ),
                  ],
                ),

                // 3. Company Verification
                _buildSection(
                  title: 'Verification & Compliance',
                  icon: Icons.verified_user_outlined,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.policy_outlined,
                      title: 'MCA Verification Required',
                      subtitle: 'Companies must provide valid CIN',
                      value: _mcaVerificationRequired,
                      onChanged: (v) => setState(() => _mcaVerificationRequired = v),
                    ),
                    _buildSwitchTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Manual Approval',
                      subtitle: 'Admin must approve companies',
                      value: _manualCompanyApproval,
                      onChanged: (v) => setState(() => _manualCompanyApproval = v),
                    ),
                  ],
                ),

                // 4. AI Matching Config
                _buildSection(
                  title: 'AI Matching Configuration',
                  icon: Icons.psychology,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.power_settings_new,
                      title: 'Enable AI Engine',
                      subtitle: 'Turn on smart matching',
                      value: _aiMatchingEnabled,
                      onChanged: (v) => setState(() => _aiMatchingEnabled = v),
                    ),
                    if (_aiMatchingEnabled) ...[
                      const Divider(),
                      _buildSlider('Skills Weight', _skillsWeight, (v) => setState(() => _skillsWeight = v)),
                      _buildSlider('Experience Weight', _experienceWeight, (v) => setState(() => _experienceWeight = v)),
                      _buildSlider('Domain Relevance', _domainWeight, (v) => setState(() => _domainWeight = v)),
                      _buildSlider('Location Preference', _locationWeight, (v) => setState(() => _locationWeight = v)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: OutlinedButton.icon(
                          onPressed: _resetAIWeights,
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset to Default'),
                        ),
                      ),
                    ],
                  ],
                ),

                // 5. System & Platform
                _buildSection(
                  title: 'System & Platform',
                  icon: Icons.settings_system_daydream,
                  children: [
                    _buildInfoTile(
                      icon: Icons.post_add,
                      title: 'Internship Post Limit',
                      subtitle: 'Max $_internshipLimitPerCompany per company',
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {},
                      ),
                    ),
                     _buildInfoTile(
                      icon: Icons.person_add,
                      title: 'Application Limit',
                      subtitle: 'Max $_applicationLimitPerStudent per student',
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {},
                      ),
                    ),
                    _buildSwitchTile(
                      icon: Icons.money,
                      title: 'Mandatory Stipend',
                      subtitle: 'Require stipend for all posts',
                      value: _stipendMandatory,
                      onChanged: (v) => setState(() => _stipendMandatory = v),
                    ),
                    _buildSwitchTile(
                      icon: Icons.laptop_mac,
                      title: 'Global Remote Work',
                      subtitle: 'Allow remote internships',
                      value: _remoteInternshipsEnabled,
                      onChanged: (v) => setState(() => _remoteInternshipsEnabled = v),
                    ),
                  ],
                ),

                // 6. Content Moderation
                _buildSection(
                  title: 'Content Moderation',
                  icon: Icons.gavel,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.flag_outlined,
                      title: 'Auto-Flagging',
                      subtitle: 'Flag suspicious content',
                      value: _autoFlagging,
                      onChanged: (v) => setState(() => _autoFlagging = v),
                    ),
                    _buildSwitchTile(
                      icon: Icons.block,
                      title: 'Profanity Filter',
                      subtitle: 'Block offensive keywords',
                      value: _profanityDetection,
                      onChanged: (v) => setState(() => _profanityDetection = v),
                    ),
                  ],
                ),

                // 7. Analytics
                _buildSection(
                  title: 'Analytics & Logs',
                  icon: Icons.analytics_outlined,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.insights,
                      title: 'Analytics Tracking',
                      subtitle: 'Collect usage data',
                      value: _analyticsTracking,
                      onChanged: (v) => setState(() => _analyticsTracking = v),
                    ),
                     _buildActionTile(
                      icon: Icons.file_download,
                      title: 'Export Reports',
                      subtitle: 'Users, Internships, Logs',
                      onTap: () {},
                    ),
                    _buildActionTile(
                      icon: Icons.error_outline,
                      title: 'View Error Logs',
                      subtitle: 'Read-only system logs',
                      onTap: () {},
                    ),
                  ],
                ),

                // 8. App Configuration
                _buildSection(
                  title: 'App Configuration',
                  icon: Icons.build_circle_outlined,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.construction,
                      title: 'Maintenance Mode',
                      subtitle: 'Pause app for all users',
                      value: _maintenanceMode,
                      onChanged: (v) => setState(() => _maintenanceMode = v),
                    ),
                    _buildSwitchTile(
                      icon: Icons.speed,
                      title: 'API Rate Limiting',
                      subtitle: 'Prevent abuse',
                      value: _apiRateLimiting,
                      onChanged: (v) => setState(() => _apiRateLimiting = v),
                    ),
                    _buildInfoTile(
                      icon: Icons.info,
                      title: 'Min App Version',
                      subtitle: 'v1.0.0',
                      trailing: const Icon(Icons.edit, size: 18),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // Helper Widgets

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
                Icon(icon, color: AppColors.deepGreen, size: 20),
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
      leading: Icon(icon, color: AppColors.deepGreen),
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
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.deepGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
      leading: Icon(icon, color: AppColors.deepGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: trailing,
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${(value * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.deepGreen,
        ),
      ],
    );
  }
}
