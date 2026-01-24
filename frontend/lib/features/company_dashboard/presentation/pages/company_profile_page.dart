import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'settings/company_settings_page.dart';

class CompanyProfilePage extends StatefulWidget {
  final Map<String, dynamic>? companyProfile;
  final VoidCallback? onProfileUpdated;

  const CompanyProfilePage({
    super.key,
    this.companyProfile,
    this.onProfileUpdated,
  });

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  bool _isEditing = false;

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _industryController;
  late TextEditingController _websiteController;
  late TextEditingController _locationController;
  late TextEditingController _sizeController;

  @override
  void initState() {
    super.initState();
    _profile = widget.companyProfile;
    _initControllers();
    if (_profile == null) _fetchProfile();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _profile?['companyName'] ?? '');
    _descriptionController = TextEditingController(text: _profile?['description'] ?? '');
    _industryController = TextEditingController(text: _profile?['industry'] ?? '');
    _websiteController = TextEditingController(text: _profile?['website'] ?? '');
    
    // Handle location which might be a Map or String
    var location = _profile?['location'];
    String locationText = '';
    if (location is Map) {
      final city = location['city']?.toString() ?? '';
      final state = location['state']?.toString() ?? '';
      if (city.isNotEmpty && state.isNotEmpty) {
        locationText = '$city, $state';
      } else {
        locationText = city.isNotEmpty ? city : (state.isNotEmpty ? state : '');
      }
      if (locationText.isEmpty) locationText = location['address']?.toString() ?? '';
    } else if (location is String) {
      locationText = location;
    }
    _locationController = TextEditingController(text: locationText);
    
    _sizeController = TextEditingController(text: _profile?['companySize'] ?? '');
  }
  String _getLogoChar() {
    final name = _profile?['companyName'];
    if (name != null && name.toString().isNotEmpty) {
      return name.toString()[0].toUpperCase();
    }
    return 'C';
  }

  @override
  void didUpdateWidget(CompanyProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.companyProfile != oldWidget.companyProfile) {
      _profile = widget.companyProfile;
      _initControllers();
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/company/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        setState(() {
          _profile = response.data;
          _initControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.put(
        '${ApiConstants.baseUrl}/company/profile',
        data: {
          'companyName': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'industry': _industryController.text.trim(),
          'website': _websiteController.text.trim(),
          'location': _locationController.text.trim(),
          'companySize': _sizeController.text.trim(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        widget.onProfileUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
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

    if (confirm == true) {
      await AuthService().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = _profile?['isApproved'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          // Header Row - responsive layout to prevent overflow
          LayoutBuilder(
            builder: (context, constraints) {
              // Use vertical layout on very small screens
              final isSmallScreen = constraints.maxWidth < 320;
              
              if (isSmallScreen && _isEditing) {
                // Stack vertically on small screens when editing
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Company Profile',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _initControllers();
                            setState(() => _isEditing = false);
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                );
              }
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title with flexible width to prevent overflow
                  Flexible(
                    child: Text(
                      'Company Profile',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isEditing)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CompanySettingsPage()),
                            );
                          },
                          tooltip: 'Settings',
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            _initControllers();
                            setState(() => _isEditing = false);
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Profile Card
          Container(
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
                // Company Logo & Name
                Row(
                  children: [
                    Container(
                      width: 72.w(context),
                      height: 72.w(context),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          _getLogoChar(),
                          style: TextStyle(
                            fontSize: 32.sp(context),
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
                          if (_isEditing)
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                                isDense: true,
                              ),
                            )
                          else
                            Text(
                              _profile?['companyName'] ?? 'Company Name',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                  size: 14,
                                  color: isApproved ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isApproved ? 'Verified Company' : 'Pending Verification',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isApproved ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Profile Fields
                _buildField(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: _profile?['description'] ?? 'No description added',
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                
                _buildField(
                  icon: Icons.business_outlined,
                  label: 'Industry',
                  value: _profile?['industry'] ?? 'Not specified',
                  controller: _industryController,
                ),
                const SizedBox(height: 20),
                
                _buildField(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: _locationController.text.isEmpty ? 'Not specified' : _locationController.text,
                  controller: _locationController,
                ),
                const SizedBox(height: 20),
                
                _buildField(
                  icon: Icons.language,
                  label: 'Website',
                  value: _profile?['website'] ?? 'Not specified',
                  controller: _websiteController,
                ),
                const SizedBox(height: 20),
                
                _buildField(
                  icon: Icons.people_outline,
                  label: 'Company Size',
                  value: _profile?['companySize'] ?? 'Not specified',
                  controller: _sizeController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.contact_mail_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.email_outlined, 'Email', _profile?['email'] ?? 'Not available'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.phone_outlined, 'Phone', _profile?['phone'] ?? 'Not available'),
              ],
            ),
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

  Widget _buildField({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              if (_isEditing)
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                Text(
                  value.isEmpty ? 'Not specified' : value,
                  style: TextStyle(
                    fontSize: 15,
                    color: value.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
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
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
                // Handle long text with ellipsis
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _sizeController.dispose();
    super.dispose();
  }
}
