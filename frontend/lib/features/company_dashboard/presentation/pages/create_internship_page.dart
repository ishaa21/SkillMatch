import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateInternshipPage extends StatefulWidget {
  final Map<String, dynamic>? internship; // For editing

  const CreateInternshipPage({super.key, this.internship});

  @override
  State<CreateInternshipPage> createState() => _CreateInternshipPageState();
}

class _CreateInternshipPageState extends State<CreateInternshipPage> {
  final _formKey = GlobalKey<FormState>();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _stipendController;
  late TextEditingController _durationController;
  late TextEditingController _locationController;
  late TextEditingController _responsibilitiesController;
  late TextEditingController _requirementsController;

  String _workMode = 'Remote';
  List<String> _selectedSkills = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  final List<String> _workModes = ['Remote', 'On-site', 'Hybrid'];
  
  final List<String> _availableSkills = [
    'Flutter', 'React', 'React Native', 'Node.js', 'Python', 'JavaScript',
    'TypeScript', 'Java', 'Kotlin', 'Swift', 'Go', 'Rust',
    'UI/UX Design', 'Figma', 'Adobe XD', 'SQL', 'PostgreSQL', 'MongoDB',
    'AWS', 'GCP', 'Azure', 'Docker', 'Kubernetes', 'GraphQL',
    'Machine Learning', 'Data Science', 'DevOps', 'Testing', 'Agile'
  ];

  final List<String> _durationOptions = [
    '1 Month', '2 Months', '3 Months', '4 Months', '6 Months', '12 Months'
  ];

  @override
  void initState() {
    super.initState();
    final internship = widget.internship;
    _titleController = TextEditingController(text: internship?['title'] ?? '');
    _descriptionController = TextEditingController(text: internship?['description'] ?? '');
    _stipendController = TextEditingController(
      text: internship?['stipend']?['amount']?.toString() ?? ''
    );
    _durationController = TextEditingController(text: internship?['duration'] ?? '');
    _locationController = TextEditingController(text: internship?['location'] ?? '');
    _responsibilitiesController = TextEditingController(
      text: (internship?['responsibilities'] as List?)?.join('\n') ?? ''
    );
    _requirementsController = TextEditingController(
      text: (internship?['requirements'] as List?)?.join('\n') ?? ''
    );
    
    if (internship != null) {
      _workMode = internship['workMode'] ?? 'Remote';
      _selectedSkills = List<String>.from(internship['skillsRequired'] ?? []);
    }

    // Listen for changes
    for (var controller in [
      _titleController, _descriptionController, _stipendController,
      _durationController, _locationController, _responsibilitiesController,
      _requirementsController
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
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

  Future<void> _saveInternship() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one required skill'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'auth_token');
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'workMode': _workMode,
        'skillsRequired': _selectedSkills,
        'stipend': {
          'amount': int.tryParse(_stipendController.text) ?? 0,
          'currency': 'USD',
          'period': 'Month'
        },
        'duration': _durationController.text.trim(),
        'location': _locationController.text.trim(),
        'responsibilities': _responsibilitiesController.text!.split('\n')
            .where((line) => line.trim().isNotEmpty).toList(),
        'requirements': _requirementsController.text.split('\n')
            .where((line) => line.trim().isNotEmpty).toList(),
        'isActive': true,
      };

      if (widget.internship == null) {
        // Create
        await _dio.post(
          '${ApiConstants.baseUrl}/internships',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } else {
        // Update
        await _dio.put(
          '${ApiConstants.baseUrl}/internships/${widget.internship!['_id']}',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(widget.internship == null 
                    ? 'Internship posted successfully!' 
                    : 'Internship updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.deepGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['message'] ?? 'Failed to save internship'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(widget.internship == null ? 'Post Internship' : 'Edit Internship'),
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
                onPressed: _isLoading ? null : _saveInternship,
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
                // Basic Info Section
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _titleController,
                  label: 'Role Title',
                  hint: 'e.g., Frontend Developer Intern',
                  icon: Icons.work_outline,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe the role, what the intern will be working on...',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // Work Details Section
                _buildSectionTitle('Work Details'),
                const SizedBox(height: 16),
                
                // Work Mode
                const Text('Work Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _workModes.map((mode) {
                    final isSelected = _workMode == mode;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mode == 'Remote' ? Icons.home_work_outlined :
                            mode == 'On-site' ? Icons.business_outlined :
                            Icons.sync_alt,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(mode),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.deepGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _workMode = mode;
                            _hasChanges = true;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'e.g., San Francisco, CA or Worldwide',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 600;
                    if (isSmall) {
                      return Column(
                        children: [
                          _buildTextField(
                            controller: _stipendController,
                            label: 'Monthly Stipend (USD)',
                            hint: '1500',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _durationOptions.contains(_durationController.text)
                                    ? _durationController.text
                                    : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.schedule, color: AppColors.mediumGreen),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                items: _durationOptions.map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                )).toList(),
                                onChanged: (value) {
                                  _durationController.text = value ?? '';
                                  _hasChanges = true;
                                },
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stipendController,
                            label: 'Monthly Stipend (USD)',
                            hint: '1500',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _durationOptions.contains(_durationController.text)
                                    ? _durationController.text
                                    : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.schedule, color: AppColors.mediumGreen),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                items: _durationOptions.map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                )).toList(),
                                onChanged: (value) {
                                  _durationController.text = value ?? '';
                                  _hasChanges = true;
                                },
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Skills Section
                _buildSectionTitle('Required Skills'),
                const SizedBox(height: 8),
                Text(
                  'Select skills that are required for this role',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSkills.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSkills.add(skill);
                          } else {
                            _selectedSkills.remove(skill);
                          }
                          _hasChanges = true;
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_selectedSkills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_selectedSkills.length} skill(s) selected',
                    style: TextStyle(
                      color: AppColors.deepGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Responsibilities Section
                _buildSectionTitle('Responsibilities (Optional)'),
                const SizedBox(height: 8),
                Text(
                  'Enter each responsibility on a new line',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _responsibilitiesController,
                  label: '',
                  hint: 'Work on frontend features\nCollaborate with the team\nParticipate in code reviews',
                  icon: Icons.checklist,
                  maxLines: 4,
                  showLabel: false,
                ),
                const SizedBox(height: 24),

                // Requirements Section
                _buildSectionTitle('Requirements (Optional)'),
                const SizedBox(height: 8),
                Text(
                  'Enter each requirement on a new line',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _requirementsController,
                  label: '',
                  hint: 'Currently pursuing CS degree\nFamiliar with React or Flutter\nGood communication skills',
                  icon: Icons.school_outlined,
                  maxLines: 4,
                  showLabel: false,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveInternship,
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
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.internship == null ? 'Post Internship' : 'Update Internship',
                            style: const TextStyle(
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
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool showLabel = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines > 1
                ? null
                : Icon(icon, color: AppColors.mediumGreen),
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stipendController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    _responsibilitiesController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }
}
