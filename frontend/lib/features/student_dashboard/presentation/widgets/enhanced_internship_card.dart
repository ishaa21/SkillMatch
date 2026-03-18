import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smooth_card.dart';
import '../../../../core/widgets/match_score_ring.dart';

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
    
    // Parse the new AI score from aiServiceClient
    final score = num.tryParse(internship['matchScore']?.toString() ?? '0')?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
      child: SmoothCard(
        onTap: onTap,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Logo / Avater
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Main Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          internship['title']?.toString() ?? 'Role',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          companyName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textBody,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        
                        // Metadata Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTag(internship['workMode']?.toString() ?? 'Remote', Icons.work_outline),
                            _buildTag(_getDuration(), Icons.access_time),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // AI Match Score
                  if (internship['aiService'] == true) ...[
                    const SizedBox(width: 12),
                    MatchScoreRing(score: score, size: 48),
                  ]
                ],
              ),
            ),
            
            // Divider
            Divider(height: 1, color: AppColors.textBody.withValues(alpha: 0.1)),
            
            // Footer: Stipend & Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Stipend
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stipend',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textBody.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        stipendAmount,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  
                  // Apply Button
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: isApplied ? null : onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isApplied ? AppColors.background : AppColors.primary,
                        foregroundColor: isApplied ? AppColors.textBody : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isApplied ? 'Applied' : 'Apply Now',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textBody),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }

  String _getCompanyName() {
    try {
      if (internship['companyName'] != null) return internship['companyName'].toString();
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
      var stipend = internship['stipend'];
      if (stipend == null) return 'Unpaid';
      if (stipend is Map) {
        final min = num.tryParse(stipend['min']?.toString() ?? '0') ?? 0;
        final max = num.tryParse(stipend['max']?.toString() ?? '0') ?? 0;
        final currency = stipend['currency'] == 'USD' ? '\$' : '₹';
        final period = stipend['period'] == 'Month' ? 'mo' : 'yr';

        if (min <= 0 && max <= 0) return 'Unpaid';
        if (min == max) return '$currency$min/$period';
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
