import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_stats_model.dart';

class AnalyticsSection extends StatefulWidget {
  final AdminStats stats;
  final AdminAnalytics analytics;
  final VoidCallback onRefresh;

  const AnalyticsSection({
    super.key,
    required this.stats,
    required this.analytics,
    required this.onRefresh,
  });

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  String _selectedTimeRange = 'Last 30 Days';

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // KPIs Row
            _buildKPIRow(),
            const SizedBox(height: 32),

            // Charts Row 1
            // Charts Row 1
            LayoutBuilder(
              builder: (context, constraints) {
                 if (constraints.maxWidth < 900) {
                     return Column(
                         children: [
                             _buildApplicationsTrendChart(),
                             const SizedBox(height: 24),
                             _buildTopSkillsCard(),
                         ],
                     );
                 }
                 return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildApplicationsTrendChart(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildTopSkillsCard(),
                    ),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),

            // Charts Row 2
            LayoutBuilder(
              builder: (context, constraints) {
                 if (constraints.maxWidth < 900) {
                     return Column(
                         children: [
                             _buildIndustryDistribution(),
                             const SizedBox(height: 24),
                             _buildPlatformHealthCard(),
                         ],
                     );
                 }
                 return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildIndustryDistribution(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: _buildPlatformHealthCard(),
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

  Widget _buildKPIRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        
        if (isMobile) {
          return Column(
            children: [
              _buildKPICard(
                'Success Rate',
                '${widget.analytics.successRate}%',
                const Color(0xFF10B981),
                Icons.check_circle_outline,
                'Hired vs Applied',
              ),
              const SizedBox(height: 16),
              _buildKPICard(
                'Avg Match Score',
                '${widget.analytics.avgMatchScore}',
                const Color(0xFF8B5CF6),
                Icons.psychology,
                'AI Algorithm',
              ),
              const SizedBox(height: 16),
              _buildKPICard(
                'Total Applications',
                widget.stats.metrics.totalApplications.toString(),
                const Color(0xFF3B82F6),
                Icons.description_outlined,
                'All time volume',
              ),
              const SizedBox(height: 16),
              _buildKPICard(
                'Active Internships',
                widget.stats.metrics.activeInternships.toString(),
                const Color(0xFFF59E0B),
                Icons.work_outline,
                'Currently listed',
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Success Rate',
                '${widget.analytics.successRate}%',
                const Color(0xFF10B981),
                Icons.check_circle_outline,
                'Hired vs Applied',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildKPICard(
                'Avg Match Score',
                '${widget.analytics.avgMatchScore}',
                const Color(0xFF8B5CF6),
                Icons.psychology,
                'AI Algorithm',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildKPICard(
                'Total Applications',
                widget.stats.metrics.totalApplications.toString(),
                const Color(0xFF3B82F6),
                Icons.description_outlined,
                'All time volume',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildKPICard(
                'Active Internships',
                widget.stats.metrics.activeInternships.toString(),
                const Color(0xFFF59E0B),
                Icons.work_outline,
                'Currently listed',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String label, String value, Color color, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTrendChart() {
    final spots = widget.analytics.applicationsTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applications Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Daily application volume',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedTimeRange,
                underline: const SizedBox(),
                items: ['Last 30 Days', 'Last 7 Days', 'All Time']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTimeRange = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade100,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                         if (index >= 0 && index < widget.analytics.applicationsTrend.length) {
                             if (index % 5 == 0) {
                                 final dateStr = widget.analytics.applicationsTrend[index].date;
                                 final parts = dateStr.split('-');
                                 final label = parts.length > 2 ? '${parts[1]}/${parts[2]}' : dateStr; 
                                 return SideTitleWidget(
                                     axisSide: meta.axisSide,
                                     child: Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                );
                             }
                         }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (widget.analytics.applicationsTrend.length - 1).toDouble() > 0 
                      ? (widget.analytics.applicationsTrend.length - 1).toDouble() 
                      : 10,
                minY: 0,
                maxY: (spots.isNotEmpty 
                        ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2 
                        : 10),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: AppColors.deepGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.deepGreen.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSkillsCard() {
    final skills = widget.analytics.topSkills;
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
            'Top Skills in Demand',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          if (skills.isEmpty)
             Center(child: Text("No skills data", style: TextStyle(color: Colors.grey.shade500)))
          else
           SingleChildScrollView(
            child: Column(
              children: skills.asMap().entries.map((entry) {
                final skill = entry.value;
                final name = skill.name;
                final count = skill.count;
                final maxCount = skills.fold<int>(0, (prev, element) => prev > element.count ? prev : element.count);
                final percentage = maxCount > 0 ? count / maxCount : 0.0;

                return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                             Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                     Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                     Text('$count', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                 ],
                             ),
                             const SizedBox(height: 6),
                             ClipRRect(
                                 borderRadius: BorderRadius.circular(4),
                                 child: LinearProgressIndicator(
                                     value: percentage,
                                     backgroundColor: Colors.grey.shade100,
                                     color: const Color(0xFF3B82F6),
                                     minHeight: 8,
                                 ),
                             ),
                        ],
                    ),
                );
              }).toList(),
            ),
           ),
        ],
      ),
    );
  }

  Widget _buildIndustryDistribution() {
    final industries = widget.stats.industryBreakdown;
    
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
            'Industry Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          if (industries.isEmpty)
             Center(child: Text("No industry data", style: TextStyle(color: Colors.grey.shade500)))
          else
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: industries.take(5).map((industry) {
                    final index = industries.indexOf(industry);
                    final count = industry.count;
                    const colors = [
                      Color(0xFF3B82F6),
                      Color(0xFF10B981),
                      Color(0xFFF59E0B),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ];
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: count.toDouble(),
                      title: '${count}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
           const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: industries.take(5).map((industry) {
                  final index = industries.indexOf(industry);
                   const colors = [
                      Color(0xFF3B82F6),
                      Color(0xFF10B981),
                      Color(0xFFF59E0B),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(industry.industry, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  );
              }).toList(),
            )
        ],
      ),
    );
  }

  Widget _buildPlatformHealthCard() {
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
            'Platform Health',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          _buildHealthItem('Server Status', 'Operational', Colors.green),
          _buildHealthItem('Database Response', '12ms', Colors.green),
          _buildHealthItem('AI Engine', 'Online', Colors.purple),
          _buildHealthItem('Error Rate', '0.01%', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
