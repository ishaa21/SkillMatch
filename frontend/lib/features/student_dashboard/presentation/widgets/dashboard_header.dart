import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final String profileUrl;
  final int notificationCount;
  final double completionPercentage;
  final VoidCallback? onNotificationTap;

  const DashboardHeader({
    super.key, 
    required this.userName, 
    this.profileUrl = '', 
    this.notificationCount = 0,
    this.completionPercentage = 0.0,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w(context), vertical: 16.h(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile section
          Expanded(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                     SizedBox(
                      width: 58.w(context),
                      height: 58.w(context),
                      child: CircularProgressIndicator(
                        value: completionPercentage,
                        strokeWidth: 3.w(context),
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      ),
                     ),
                     Container(
                      width: 50.w(context),
                      height: 50.w(context),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                        border: Border.all(color: Colors.white, width: 3.w(context)),
                        image: profileUrl.isNotEmpty 
                            ? DecorationImage(image: NetworkImage(profileUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: profileUrl.isEmpty 
                          ? Icon(Icons.person, color: AppColors.textBody, size: 24.sp(context))
                          : null,
                    ),
                  ],
                ),
                SizedBox(width: 16.w(context)),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome back,',
                        style: GoogleFonts.inter(
                          color: AppColors.textBody,
                          fontSize: 14.sp(context),
                        ),
                      ),
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontSize: 22.sp(context),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w(context)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: Offset(0, 4.h(context)),
                      ),
                    ],
                  ),
                  child: Icon(Icons.notifications_none_rounded, color: AppColors.textDark, size: 24.sp(context)),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(5.w(context)),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w(context),
                        minHeight: 16.w(context),
                      ),
                      child: Center(
                        child: Text(
                          '$notificationCount',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
