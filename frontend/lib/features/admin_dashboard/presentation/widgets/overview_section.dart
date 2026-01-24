import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/admin_stats_model.dart';

class OverviewSection extends StatelessWidget {
  final AdminStats stats;
  final VoidCallback onRefresh;
  final VoidCallback onNavigateToApprovals;

  const OverviewSection({
    super.key,
    required this.stats,
    required this.onRefresh,
    required this.onNavigateToApprovals,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary Stats Grid
            _buildPrimaryStatsGrid(stats.metrics),
            const SizedBox(height: 32),

            // Pending Actions Banner
            if (stats.metrics.pendingCompanies > 0) ...[
              _buildPendingActionsBanner(stats.metrics.pendingCompanies),
              const SizedBox(height: 32),
            ],

            // Two Column Layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;
                
                if (isMobile) {
                  return Column(
                     children: [
                       _buildApplicationStatusCard(stats.appStatusBreakdown),
                       const SizedBox(height: 24),
                       _buildRecentActivityCard(stats.recentActivity),
                       const SizedBox(height: 24),
                       _buildWorkModeDistribution(stats.workModeBreakdown),
                       const SizedBox(height: 24),
                       _buildTrendingInternships(stats.trendingInternships),
                     ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildApplicationStatusCard(stats.appStatusBreakdown),
                          const SizedBox(height: 24),
                          _buildRecentActivityCard(stats.recentActivity),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildWorkModeDistribution(stats.workModeBreakdown),
                          const SizedBox(height: 24),
                          _buildTrendingInternships(stats.trendingInternships),
                        ],
                      ),
                    ),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryStatsGrid(DashboardMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        
        if (isMobile) {
          return Column(
            children: [
              _buildStatCard(
                'Total Students',
                metrics.totalStudents.toString(),
                Icons.school_outlined,
                const Color(0xFF3B82F6),
                '+12%',
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Total Companies',
                metrics.totalCompanies.toString(),
                Icons.business_outlined,
                const Color(0xFFF59E0B),
                '${metrics.approvedCompanies} verified',
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Active Internships',
                metrics.activeInternships.toString(),
                Icons.work_outline,
                const Color(0xFF10B981),
                '${metrics.inactiveInternships} inactive',
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Applications',
                metrics.totalApplications.toString(),
                Icons.description_outlined,
                const Color(0xFF8B5CF6),
                'All time',
              ),
            ],
          );
        }

        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              'Total Students',
              metrics.totalStudents.toString(),
              Icons.school_outlined,
              const Color(0xFF3B82F6),
              '+12%',
            ),
            _buildStatCard(
              'Total Companies',
              metrics.totalCompanies.toString(),
              Icons.business_outlined,
              const Color(0xFFF59E0B),
              '${metrics.approvedCompanies} verified',
            ),
            _buildStatCard(
              'Active Internships',
              metrics.activeInternships.toString(),
              Icons.work_outline,
              const Color(0xFF10B981),
              '${metrics.inactiveInternships} inactive',
            ),
            _buildStatCard(
              'Applications',
              metrics.totalApplications.toString(),
              Icons.description_outlined,
              const Color(0xFF8B5CF6),
              'All time',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w(context)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w(context)),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24.sp(context)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp(context),
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h(context)),
            Text(
              value,
              style: TextStyle(
                fontSize: 32.sp(context),
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp(context),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingActionsBanner(int count) {
    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w(context)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF7ED),
              Color(0xFFFEF3C7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 500;

          final iconWidget = Container(
            padding: EdgeInsets.all(12.w(context)),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pending_actions, color: Colors.orange, size: 28.sp(context)),
          );

          final textWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count Companies Awaiting Approval',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp(context),
                  color: const Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'New company registrations require your review before they can post internships.',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 13.sp(context),
                ),
              ),
            ],
          );

          final buttonWidget = ElevatedButton(
            onPressed: onNavigateToApprovals,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w(context), vertical: 14.h(context)),
            ),
            child: const Text('Review Now'),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 16),
                    Expanded(child: textWidget),
                  ],
                ),
                const SizedBox(height: 16),
                buttonWidget,
              ],
            );
          }

          return Row(
            children: [
              iconWidget,
              const SizedBox(width: 20),
              Expanded(child: textWidget),
              const SizedBox(width: 16),
              buttonWidget,
            ],
          );
        },
      ),
    ),
  );
}

  Widget _buildApplicationStatusCard(List<StatusBreakdown> breakdown) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Application Status Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'All Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (breakdown.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No application data available',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...breakdown.map((item) => _buildStatusBar(
                  item.status,
                  item.count,
                  _getTotalFromBreakdown(breakdown),
                )),
        ],
      ),
    );
  }

  int _getTotalFromBreakdown(List<StatusBreakdown> breakdown) {
    return breakdown.fold(0, (sum, item) => sum + item.count);
  }

  Widget _buildStatusBar(String status, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;
    final color = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                '$count (${(percentage * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade100,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return const Color(0xFF3B82F6);
      case 'shortlisted':
        return const Color(0xFFF59E0B);
      case 'hired':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'withdrawn':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  Widget _buildRecentActivityCard(RecentActivity activity) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Last 7 Days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildActivityItem(
                      'Applications',
                      activity.applications.toString(),
                      Icons.description_outlined,
                      const Color(0xFF8B5CF6),
                      isHorizontal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityItem(
                      'New Students',
                      activity.students.toString(),
                      Icons.school_outlined,
                      const Color(0xFF3B82F6),
                      isHorizontal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityItem(
                      'New Companies',
                      activity.companies.toString(),
                      Icons.business_outlined,
                      const Color(0xFFF59E0B),
                      isHorizontal: true,
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildActivityItem(
                        'Applications',
                        activity.applications.toString(),
                        Icons.description_outlined,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActivityItem(
                        'New Students',
                        activity.students.toString(),
                        Icons.school_outlined,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActivityItem(
                        'New Companies',
                        activity.companies.toString(),
                        Icons.business_outlined,
                        const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String label, String value, IconData icon, Color color,
      {bool isHorizontal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: isHorizontal
          ? Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
    );
  }

  Widget _buildWorkModeDistribution(List<WorkModeBreakdown> breakdown) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Work Mode Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          if (breakdown.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...breakdown.map((item) {
              final icon = _getWorkModeIcon(item.mode);
              final color = _getWorkModeColor(item.mode);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.mode,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.count.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _getWorkModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'remote':
        return Icons.home_work_outlined;
      case 'on-site':
        return Icons.business_outlined;
      case 'hybrid':
        return Icons.compare_arrows;
      default:
        return Icons.work_outline;
    }
  }

  Color _getWorkModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'remote':
        return const Color(0xFF10B981);
      case 'on-site':
        return const Color(0xFF3B82F6);
      case 'hybrid':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  Widget _buildTrendingInternships(List<TrendingInternship> trending) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Trending Internships',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (trending.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No trending data',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...trending.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? const Color(0xFFFEF3C7)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index == 0
                                ? const Color(0xFFF59E0B)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.companyName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.softMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.applicationCount} apps',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
