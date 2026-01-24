import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InternshipCard extends StatelessWidget {
  final Map<String, dynamic> internship;

  const InternshipCard({super.key, required this.internship});

  // Helper function to safely extract duration string
  String _getDuration() {
    final duration = internship['duration'];
    if (duration == null) return 'N/A';
    
    // If it's a Map with displayString
    if (duration is Map && duration['displayString'] != null) {
      return duration['displayString'].toString();
    }
    
    // If it's already a string
    if (duration is String) {
      return duration;
    }
    
    // Fallback
    return duration.toString();
  }

  @override
  Widget build(BuildContext context) {
    final matchPercentage = internship['matchPercentage'] ?? 0;
    
    // Determine Match Color
    Color matchColor;
    if (matchPercentage >= 80) {
      matchColor = AppColors.deepGreen;
    } else if (matchPercentage >= 50) {
      matchColor = Colors.orange;
    } else {
      matchColor = Colors.redAccent;
    }

    // Safely extract stipend amount
    // Safely extract stipend amount
    final stipend = internship['stipend'];
    String displayedStipend;
    
    if (stipend == null) {
      displayedStipend = 'N/A';
    } else if (stipend is Map) {
       final currency = stipend['currency'] ?? '₹';
       final amount = stipend['amount']?.toString() ?? '0';
       displayedStipend = (amount == '0') ? 'Unpaid' : '$currency$amount';
    } else if (stipend is String) {
       // If it contains "INR", replace it with symbol
       String cleanStipend = stipend.replaceAll('INR', '₹').trim();
       
       // Check for "0" or "Unpaid" patterns
       if (cleanStipend == '0' || cleanStipend == '₹0' || cleanStipend.toLowerCase().contains('unpaid')) {
         displayedStipend = 'Unpaid';
       } else {
         // If it's just a number string like "5000", add symbol
         if (RegExp(r'^\d+$').hasMatch(cleanStipend)) {
            displayedStipend = '₹$cleanStipend';
         } else if (!cleanStipend.startsWith('₹') && !cleanStipend.startsWith('\$')) {
            // If it has no symbol but isn't just digits (e.g. "5000/mo")
            // Try to detect if it starts with a number
            if (RegExp(r'^\d').hasMatch(cleanStipend)) {
               displayedStipend = '₹$cleanStipend';
            } else {
               displayedStipend = cleanStipend;
            }
         } else {
            displayedStipend = cleanStipend;
         }
       }
    } else if (stipend is num) {
       displayedStipend = (stipend == 0) ? 'Unpaid' : '₹$stipend';
    } else {
       displayedStipend = 'N/A';
    }
    
    // Company Name Logic
    final companyName = (internship['companyDetails'] != null ? internship['companyDetails']['companyName'] : (internship['company'] is Map ? internship['company']['companyName'] : 'Company')) ?? 'Company';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigation handled by parent or GestureDetector
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Match Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            internship['title'] ?? 'Internship Role',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.deepGreen,
                                      AppColors.mediumGreen,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.deepGreen.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    fontSize: 14, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  companyName,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Match Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            matchColor.withOpacity(0.15),
                            matchColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: matchColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: matchColor),
                          const SizedBox(height: 2),
                          Text(
                            '$matchPercentage%',
                            style: TextStyle(
                              color: matchColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Info Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildInfoChip(
                        Icons.location_on_outlined, 
                        internship['workMode'] ?? 'Remote',
                        Colors.blue.shade50,
                        Colors.blue.shade700,
                      ),
                      const SizedBox(width: 10),
                      _buildInfoChip(
                        Icons.schedule_outlined, 
                        _getDuration(),
                        Colors.orange.shade50,
                        Colors.orange.shade800,
                      ),
                      const SizedBox(width: 10),
                      _buildInfoChip(
                        Icons.payments_outlined, 
                        displayedStipend,
                        Colors.green.shade50,
                        Colors.green.shade800,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // View Details Button with Visual Indication only (Parent handles tap)
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
