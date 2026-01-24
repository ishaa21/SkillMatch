import 'package:flutter/material.dart';
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
        children: [
          // Profile section with flexible width
          Expanded(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                     SizedBox(
                      width: 58.w(context),
                      height: 58.w(context), // Maintain aspect ratio using width
                      child: CircularProgressIndicator(
                        value: completionPercentage,
                        strokeWidth: 3.w(context),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                     ),
                     Container(
                      width: 50.w(context),
                      height: 50.w(context),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.white, width: 3.w(context)),
                        image: profileUrl.isNotEmpty 
                            ? DecorationImage(image: NetworkImage(profileUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: profileUrl.isEmpty 
                          ? Icon(Icons.person, color: AppColors.primary, size: 24.sp(context))
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
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.sp(context),
                        ),
                      ),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 22.sp(context),
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
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w(context)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4.h(context)),
                      ),
                    ],
                  ),
                  child: Icon(Icons.notifications_outlined, color: AppColors.textDark, size: 24.sp(context)),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w(context)),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w(context),
                        minHeight: 16.w(context),
                      ),
                      child: Text(
                        '$notificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp(context),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
