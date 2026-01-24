import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/constants/api_constants.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({
    super.key,
    this.profileData,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool _hasChanges = false;

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _universityController;
  late TextEditingController _degreeController;
  late TextEditingController _bioController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _portfolioController;
  
  String _selectedYear = '2025';
  final List<String> _years = ['2023', '2024', '2025', '2026', '2027', '2028', '2029', '2030', '2031'];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final data = widget.profileData ?? {};
    _fullNameController = TextEditingController(text: data['fullName'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _universityController = TextEditingController(text: data['university'] ?? '');
    _degreeController = TextEditingController(text: data['degree'] ?? '');
    _bioController = TextEditingController(text: data['bio'] ?? '');
    _linkedinController = TextEditingController(text: data['linkedin'] ?? '');
    _githubController = TextEditingController(text: data['github'] ?? '');
    _portfolioController = TextEditingController(text: data['portfolio'] ?? '');
    
    // Validate that graduation year exists in the list, default to 2025 if not
    final gradYear = data['graduationYear']?.toString() ?? '2025';
    _selectedYear = _years.contains(gradYear) ? gradYear : '2025';
    
    // Listen for changes
    for (var controller in [
      _fullNameController,
      _phoneController,
      _universityController,
      _degreeController,
      _bioController,
      _linkedinController,
      _githubController,
      _portfolioController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _bioController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'auth_token');
      
      final updateData = {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'university': _universityController.text.trim(),
        'degree': _degreeController.text.trim(),
        'bio': _bioController.text.trim(),
        'graduationYear': int.tryParse(_selectedYear) ?? 2025,
        'linkedin': _linkedinController.text.trim(),
        'github': _githubController.text.trim(),
        'portfolio': _portfolioController.text.trim(),
      };

      debugPrint('DEBUG: Sending update data: $updateData');

      final response = await _dio.put(
        '${ApiConstants.baseUrl}/student/profile',
        data: updateData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('DEBUG: Response status: ${response.statusCode}');
      debugPrint('DEBUG: Response data: ${response.data}');

      if (mounted && response.statusCode == 200) {
        widget.onProfileUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['message'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _onWillPop()) Navigator.pop(context);
            },
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _fullNameController.text.isNotEmpty
                              ? _fullNameController.text[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: Icons.info_outline,
                  maxLines: 3,
                  hintText: 'Tell us about yourself...',
                ),
                const SizedBox(height: 32),

                // Education Section
                _buildSectionTitle('Education'),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _universityController,
                  label: 'University/College',
                  icon: Icons.school_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your university';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _degreeController,
                  label: 'Degree',
                  icon: Icons.book_outlined,
                  hintText: 'e.g., B.Tech Computer Science',
                ),
                const SizedBox(height: 16),
                
                _buildDropdown(
                  label: 'Graduation Year',
                  value: _selectedYear,
                  items: _years,
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                      _hasChanges = true;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Social Links Section
                _buildSectionTitle('Social Links'),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _linkedinController,
                  label: 'LinkedIn URL',
                  icon: Icons.link,
                  keyboardType: TextInputType.url,
                  hintText: 'https://linkedin.com/in/yourprofile',
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _githubController,
                  label: 'GitHub URL',
                  icon: Icons.code,
                  keyboardType: TextInputType.url,
                  hintText: 'https://github.com/yourusername',
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _portfolioController,
                  label: 'Portfolio URL',
                  icon: Icons.web,
                  keyboardType: TextInputType.url,
                  hintText: 'https://yourportfolio.com',
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.mediumGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, color: AppColors.mediumGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: items.map((year) => DropdownMenuItem(
        value: year,
        child: Text(year),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
