import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import '../../../../../core/utils/dio_client.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/constants/asset_constants.dart';
import '../../widgets/enhanced_internship_card.dart';
import 'internship_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = createDio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String _selectedFilter = 'All';
  RangeValues _stipendRange = const RangeValues(0, 10000);
  String _selectedDuration = 'Any';
  
  List<dynamic> _allInternships = [];
  List<dynamic> _searchResults = [];
  Set<String> _appliedInternshipIds = {};
  bool _isLoading = true;
  bool _hasError = false;


  final List<String> _filterOptions = ['All', 'Remote', 'Hybrid', 'On-site', 'High Pay'];
  final List<String> _durationOptions = ['Any', '1 Month', '3 Months', '6 Months'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchInternships();
    _loadAppliedInternships();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch();
  }

  Future<void> _loadAppliedInternships() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/applications/my-applications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted && response.statusCode == 200) {
        final applications = response.data as List;
        setState(() {
          _appliedInternshipIds = applications
              .map((app) => (app['internship']?['_id'] ?? app['internshipId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading applied internships: $e');
    }
  }

  Future<void> _fetchInternships() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/internships/public',
      );

      if (response.statusCode == 200) {
        var rawList = response.data is List ? List.from(response.data) : [];

        // Add mock match percentage
        for (var internship in rawList) {
          internship['matchPercentage'] = 60 + (internship['_id'].hashCode % 35);
        }

        if (mounted) {
          setState(() {
            _allInternships = rawList;
            _searchResults = rawList;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch() {

    
    final query = _searchController.text.toLowerCase().trim();
    List<dynamic> results = List.from(_allInternships);

    // Text search
    if (query.isNotEmpty) {
      results = results.where((internship) {
        final title = (internship['title'] ?? '').toString().toLowerCase();
        final company = _getCompanyName(internship).toLowerCase();
        final skills = (internship['skillsRequired'] as List?)
            ?.map((s) => s.toString().toLowerCase())
            .toList() ?? [];
        
        return title.contains(query) ||
            company.contains(query) ||
            skills.any((skill) => skill.contains(query));
      }).toList();
    }

    // Filter by work mode (Case Insensitive)
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'High Pay') {
        results = results.where((i) => 
          (_getStipendAmount(i)) >= 10000
        ).toList();
      } else {
        results = results.where((i) {
          final workMode = (i['workMode'] ?? '').toString().toLowerCase();
          final filter = _selectedFilter.toLowerCase();
          
          if (filter == 'on-site' || filter == 'onsite') {
            return workMode == 'onsite' || workMode == 'on-site';
          }
          return workMode == filter;
        }).toList();
      }
    }

    // Filter by stipend range
    results = results.where((i) {
      final amount = _getStipendAmount(i);
      return amount >= _stipendRange.start && amount <= _stipendRange.end;
    }).toList();

    // Filter by duration
    if (_selectedDuration != 'Any') {
      results = results.where((i) {
        final duration = (i['duration'] ?? '').toString().toLowerCase();
        return duration.contains(_selectedDuration.toLowerCase().split(' ')[0]);
      }).toList();
    }

    setState(() {
      _searchResults = results;
    });
  }

  String _getCompanyName(Map<String, dynamic> internship) {
    // Check root level first (Normalized data)
    if (internship['companyName'] != null) return internship['companyName'];
    
    if (internship['companyDetails'] != null) {
      return internship['companyDetails']['companyName'] ?? 'Company';
    }
    if (internship['company'] is Map) {
      return internship['company']['companyName'] ?? 'Company';
    }
    return 'Company';
  }

  int _getStipendAmount(Map<String, dynamic> internship) {
    final stipend = internship['stipend'];
    if (stipend == null) return 0;
    if (stipend is Map) {
       // Check keys prioritized: amount -> max -> min
       if (stipend['amount'] != null) return num.tryParse(stipend['amount'].toString())?.toInt() ?? 0;
       if (stipend['max'] != null) return num.tryParse(stipend['max'].toString())?.toInt() ?? 0;
       if (stipend['min'] != null) return num.tryParse(stipend['min'].toString())?.toInt() ?? 0;
       return 0;
    }
    if (stipend is int) return stipend;
    if (stipend is num) return stipend.toInt();
    return 0;
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'All';
      _stipendRange = const RangeValues(0, 100000);
      _selectedDuration = 'Any';
      _searchController.clear();
    });
    _performSearch();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Filter Internships',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Work Mode Filter
                  Text(
                    'Work Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filterOptions.map((filter) {
                      return ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        selectedColor: AppColors.primary.withOpacity(0.1),
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedFilter = selected ? filter : 'All';
                          });
                        },
                        labelStyle: TextStyle(
                          color: _selectedFilter == filter ? AppColors.primary : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: _selectedFilter == filter ? AppColors.primary : Colors.grey.shade300,
                        ),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Stipend Range
                  Text(
                    'Stipend Range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${_stipendRange.start.round()}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '\$${_stipendRange.end.round()}+',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _stipendRange,
                    min: 0,
                    max: 100000,
                    divisions: 20,
                    activeColor: AppColors.deepGreen,
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (RangeValues newValues) {
                      setModalState(() {
                        _stipendRange = newValues;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Duration Filter
                  Text(
                    'Duration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _durationOptions.map((duration) {
                      return ChoiceChip(
                        label: Text(duration),
                        selected: _selectedDuration == duration,
                        selectedColor: AppColors.primary.withOpacity(0.1),
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedDuration = selected ? duration : 'Any';
                          });
                        },
                        labelStyle: TextStyle(
                          color: _selectedDuration == duration ? AppColors.primary : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: _selectedDuration == duration ? AppColors.primary : Colors.grey.shade300,
                        ),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Apply and Clear Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _clearFilters();
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _performSearch();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Refresh the main page results after modal closes
      setState(() {});
    });
  }

  Widget _buildFilterChip(String filter) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(filter),
        selected: _selectedFilter == filter,
        selectedColor: AppColors.primary.withOpacity(0.1),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? filter : 'All';
            _performSearch();
          });
        },
        labelStyle: TextStyle(
          color: _selectedFilter == filter ? AppColors.primary : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: _selectedFilter == filter ? AppColors.primary : Colors.grey.shade300,
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Find Internships'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.primary),
                onPressed: _showFilterModal,
              ),
              if (_selectedFilter != 'All' || _selectedDuration != 'Any')
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Job title, keyword, or company',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) => 
                      _buildFilterChip(filter)
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Results Count & Clear
          if (_searchController.text.isNotEmpty || _selectedFilter != 'All')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_searchResults.length} results found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          
          // Results List
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return Center(
        child: Lottie.asset(
          AssetConstants.loading,
          height: 150,
          errorBuilder: (_, __, ___) => const CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load internships',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchInternships,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AssetConstants.empty,
              height: 150,
              errorBuilder: (_, __, ___) => Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No internships found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInternships,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final internship = _searchResults[index];
          final isApplied = _appliedInternshipIds.contains(
            internship['_id']?.toString() ?? ''
          );
          
          return EnhancedInternshipCard(
            internship: internship,
            isApplied: isApplied,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InternshipDetailsPage(internship: internship),
                ),
              );
              if (result == true) {
                _loadAppliedInternships();
              }
            },
            onApply: () async {
              // Simple one-click apply or redirect to details
              // For search page, let's redirect to details to encourage viewing more info
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InternshipDetailsPage(internship: internship),
                ),
              );
              if (result == true) {
                 _loadAppliedInternships();
              }
            },
          );
        },
      ),
    );
  }


}
