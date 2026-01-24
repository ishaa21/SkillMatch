import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EnhancedInternshipCard extends StatelessWidget {
  final Map<String, dynamic> internship;
  final VoidCallback onTap;
  final VoidCallback onApply;
  final bool isApplied;

  const EnhancedInternshipCard({
    super.key,
    required this.internship,
    required this.onTap,
    required this.onApply,
    this.isApplied = false,
  });

  @override
  Widget build(BuildContext context) {
    final companyName = _getCompanyName();
    final stipendAmount = _getStipend();
    final isRemote = (internship['workMode'] ?? '') == 'Remote';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isApplied ? AppColors.mediumTeal.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepGreen.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.softMint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Main Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          internship['title']?.toString() ?? 'Role',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Metadata Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildDotInfo(internship['workMode']?.toString() ?? 'Remote'),
                              const SizedBox(width: 4),
                              _buildDot(),
                              const SizedBox(width: 4),
                              _buildDotInfo(_getDuration()),
                              const SizedBox(width: 4),
                              if (isRemote) ...[
                                _buildDot(),
                                const SizedBox(width: 4),
                                _buildDotInfo('Remote'),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Divider(height: 1, color: Colors.grey.shade100),
            
            // Footer: Stipend & Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Stipend
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stipend',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        stipendAmount,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  
                  // Apply Button
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: isApplied ? null : onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isApplied ? Colors.grey.shade100 : AppColors.deepGreen,
                        foregroundColor: isApplied ? Colors.grey : Colors.white,
                        elevation: isApplied ? 0 : 2,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isApplied ? 'Applied' : 'Apply Now',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotInfo(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textGrey,
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  String _getCompanyName() {
    try {
      if (internship['companyDetails'] != null && internship['companyDetails'] is Map) {
        return internship['companyDetails']['companyName']?.toString() ?? 'Company';
      }
      final company = internship['company'];
      if (company is Map) {
        return company['companyName']?.toString() ?? 'Company';
      }
      return 'Company';
    } catch (e) {
      return 'Company';
    }
  }

  String _getStipend() {
    try {
      final stipend = internship['stipend'];
      if (stipend == null) return 'Unpaid';
      
      // Expected structure: {min, max, currency, period}
      if (stipend is Map) {
        final min = num.tryParse(stipend['min']?.toString() ?? '0') ?? 0;
        final max = num.tryParse(stipend['max']?.toString() ?? '0') ?? 0;
        final currency = stipend['currency'] == 'USD' ? '\$' : '₹';
        final period = stipend['period'] == 'Month' ? 'mo' : 'yr';

        if (min <= 0 && max <= 0) return 'Unpaid';

        if (min == max) {
          return '$currency$min/$period';
        }
        return '$currency$min - $currency$max / $period';
      }
      
      return 'Unpaid';
    } catch (e) {
      return 'Unpaid';
    }
  }

  String _getDuration() {
    try {
      final duration = internship['duration'];
      if (duration == null) return 'N/A';
      if (duration is Map && duration['displayString'] != null) {
        return duration['displayString'].toString();
      }
      if (duration is String) return duration;
      return duration.toString();
    } catch (e) {
      return 'N/A';
    }
  }
}
