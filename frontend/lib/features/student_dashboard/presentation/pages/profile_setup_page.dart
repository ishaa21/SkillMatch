import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'student_dashboard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../../core/utils/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import 'package:dotted_border/dotted_border.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isLoading = false;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();
  final _degreeController = TextEditingController();
  final _graduationYearController = TextEditingController();

  final List<String> _skills = [];
  final _skillController = TextEditingController();

  final List<String> _interests = [];
  final _interestController = TextEditingController();
  String _workMode = 'Remote';

  String? _resumeFileName;

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _graduationYearController.dispose();
    _skillController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitProfile() async {
    setState(() => _isLoading = true);

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      // Use shared Dio configuration with timeouts
      final dio = createDio(); 
      dio.options.headers['Authorization'] = 'Bearer $token';

      final data = {
        'fullName': _fullNameController.text,
        'phone': _phoneController.text,
        'university': _universityController.text,
        'degree': _degreeController.text,
        'graduationYear': int.tryParse(_graduationYearController.text) ?? DateTime.now().year, 
        'skills': _skills
            .map((s) => {'name': s, 'proficiency': 'Intermediate'})
            .toList(),
        'interests': _interests,
        'internshipPreferences': {'type': _workMode},
      };
      
      print('Sending profile data: $data'); // Debug

      await dio.put('/student/profile', data: data);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
    } on DioException catch (e) {
      print('DioError: ${e.response?.data}');
      if (mounted) {
        String msg = 'Error saving profile';
        if (e.response?.statusCode == 500) msg = 'Server Error (500). details in log.';
        if (e.response?.data is Map && (e.response?.data as Map).containsKey('message')) {
            msg = e.response?.data['message'];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildPersonalStep(),
                  _buildAcademicStep(),
                  _buildSkillsStep(),
                  _buildPreferencesStep(),
                  _buildResumeStep(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(_getStepTitle(_currentStep),
                  style: const TextStyle(color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppColors.lightMint,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Info';
      case 1:
        return 'Education';
      case 2:
        return 'Skills';
      case 3:
        return 'Preferences';
      case 4:
        return 'Resume';
      default:
        return '';
    }
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(onPressed: _prevStep, child: const Text('Back')),
          const Spacer(),
          ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_currentStep == _totalSteps - 1
                    ? 'Complete'
                    : 'Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 32),
          content,
        ],
      ),
    );
  }

  Widget _buildPersonalStep() {
    return _buildStepContainer(
      title: 'Personal Information',
      subtitle: 'Tell us about yourself.',
      content: Column(
        children: [
          TextFormField(
              controller: _fullNameController,
              decoration:
                  const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 16),
          TextFormField(
              controller: _phoneController,
              decoration:
                  const InputDecoration(labelText: 'Phone Number')),
        ],
      ),
    );
  }

  Widget _buildAcademicStep() {
    return _buildStepContainer(
      title: 'Academic Background',
      subtitle: 'Your education details.',
      content: Column(
        children: [
          TextFormField(
              controller: _universityController,
              decoration:
                  const InputDecoration(labelText: 'University')),
          const SizedBox(height: 16),
          TextFormField(
              controller: _degreeController,
              decoration: const InputDecoration(labelText: 'Degree')),
          const SizedBox(height: 16),
          TextFormField(
              controller: _graduationYearController,
              decoration:
                  const InputDecoration(labelText: 'Graduation Year')),
        ],
      ),
    );
  }

  Widget _buildSkillsStep() {
    return _buildStepContainer(
      title: 'Skills',
      subtitle: 'Add your skills.',
      content: Column(
        children: [
          TextFormField(
            controller: _skillController,
            decoration: const InputDecoration(labelText: 'Add Skill'),
            onFieldSubmitted: (v) {
              if (v.isNotEmpty) {
                setState(() {
                  _skills.add(v);
                  _skillController.clear();
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _skills
                .map((s) => Chip(
                      label: Text(s),
                      onDeleted: () =>
                          setState(() => _skills.remove(s)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return _buildStepContainer(
      title: 'Preferences',
      subtitle: 'Your internship preferences.',
      content: Column(
        children: ['Remote', 'Hybrid', 'On-site']
            .map((m) => RadioListTile(
                  value: m,
                  groupValue: _workMode,
                  onChanged: (v) =>
                      setState(() => _workMode = v!),
                  title: Text(m),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildResumeStep() {
    return _buildStepContainer(
      title: 'Resume',
      subtitle: 'Upload your resume.',
      content: Center(
        child: GestureDetector(
          onTap: () {
            setState(() => _resumeFileName = 'resume.pdf');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mock resume selected')),
            );
          },
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: DottedBorder(
              color: AppColors.primary,
              dashPattern: const [6, 3],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightMint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _resumeFileName != null
                          ? Icons.description
                          : Icons.cloud_upload_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _resumeFileName ?? 'Tap to Upload Resume',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_resumeFileName != null)
                      TextButton(
                        onPressed: () =>
                            setState(() => _resumeFileName = null),
                        child: const Text('Remove'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
