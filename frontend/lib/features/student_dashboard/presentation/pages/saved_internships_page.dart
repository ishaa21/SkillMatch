import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/dio_client.dart';
import '../widgets/enhanced_internship_card.dart';
import 'search/internship_details_page.dart';

class SavedInternshipsPage extends StatefulWidget {
  const SavedInternshipsPage({super.key});

  @override
  State<SavedInternshipsPage> createState() => _SavedInternshipsPageState();
}

class _SavedInternshipsPageState extends State<SavedInternshipsPage> {
  final Dio _dio = createDio();
  final _storage = const FlutterSecureStorage();
  
  List<dynamic> _savedInternships = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchSavedInternships();
  }

  Future<void> _fetchSavedInternships() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/student/saved-internships',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted && response.statusCode == 200) {
        setState(() {
          _savedInternships = response.data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Saved Internships', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Failed to load saved internships', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchSavedInternships,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _savedInternships.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No saved internships yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _savedInternships.length,
                      itemBuilder: (context, index) {
                        final internship = _savedInternships[index];
                        // If the backend returns populated objects directly or nested in 'internship' field
                        // Adjust based on your API response structure. 
                        // Assuming list of internships based on controller logic.
                        
                        return EnhancedInternshipCard(
                          internship: internship,
                          isApplied: false, // We can't easily know this here without extra check, or we don't care on this screen
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InternshipDetailsPage(
                                  internship: internship,
                                ),
                              ),
                            ).then((_) => _fetchSavedInternships()); // Refresh on return
                          },
                          onApply: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InternshipDetailsPage(
                                  internship: internship,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
