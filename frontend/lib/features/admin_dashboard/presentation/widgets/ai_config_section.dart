import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_stats_model.dart';


class AIConfigSection extends StatefulWidget {
  final AIConfigModel config;
  final Function(Map<String, double>) onSave;
  final VoidCallback onRefresh;

  const AIConfigSection({
    super.key,
    required this.config,
    required this.onSave,
    required this.onRefresh,
  });


  @override
  State<AIConfigSection> createState() => _AIConfigSectionState();
}

class _AIConfigSectionState extends State<AIConfigSection> {
  late Map<String, double> _weights;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeWeights();
  }

  @override
  void didUpdateWidget(AIConfigSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _initializeWeights();
    }
  }

  void _initializeWeights() {
    final configWeights = widget.config.weights;
    _weights = {
      'skills': configWeights['skills'] ?? 0.40,
      'domains': configWeights['domains'] ?? 0.20,
      'preferences': configWeights['preferences'] ?? 0.15,
      'location': configWeights['location'] ?? 0.10,
      'experience': configWeights['experience'] ?? 0.15,
    };
    _hasChanges = false;
  }

  double get _totalWeight => _weights.values.fold(0.0, (sum, v) => sum + v);
  bool get _isValidSum => _totalWeight >= 0.95 && _totalWeight <= 1.05;

  void _updateWeight(String key, double value) {
    setState(() {
      _weights[key] = value;
      _hasChanges = true;
    });
  }

  void _handleSave() async {
    if (!_isValidSum) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weights must sum to approximately 1.0 (currently ${_totalWeight.toStringAsFixed(2)})',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(_weights);
      setState(() => _hasChanges = false);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetToDefaults() {
    setState(() {
      _weights = {
        'skills': 0.40,
        'domains': 0.20,
        'preferences': 0.15,
        'location': 0.10,
        'experience': 0.15,
      };
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lastUpdated = widget.config.updatedAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              return Container(
                padding: EdgeInsets.all(isSmall ? 20 : 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.deepGreen, Color(0xFF2D5A4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Matching Engine',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure how the AI ranks and matches students with internship opportunities. '
                        'Adjustments apply in real-time without requiring redeployment.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.update, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Last updated: ${_formatDate(lastUpdated)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),

          const SizedBox(height: 32),

          // Weight Balance Indicator
          _buildWeightBalanceIndicator(),
          const SizedBox(height: 32),

          // Weight Sliders
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return Column(
                  children: [
                    Column(
                      children: [
                        _buildWeightCard(
                          'skills',
                          'Skill Set Matching',
                          'How closely student technical skills match required internship skills',
                          Icons.code,
                          const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 20),
                        _buildWeightCard(
                          'domains',
                          'Domain & Interest Alignment',
                          'Match between student interests and internship domains/keywords',
                          Icons.category,
                          const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(height: 20),
                        _buildWeightCard(
                          'experience',
                          'Experience Level',
                          'Weight for matching experience requirements and proficiency levels',
                          Icons.workspace_premium,
                          const Color(0xFFEC4899),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        _buildWeightCard(
                          'preferences',
                          'Work Preferences',
                          'Match for work mode (Remote/Hybrid/On-site) and stipend expectations',
                          Icons.tune,
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 20),
                        _buildWeightCard(
                          'location',
                          'Location Compatibility',
                          'Geographic proximity and location preference matching',
                          Icons.location_on,
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoCard(),
                      ],
                    ),
                  ],
                );
              }
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildWeightCard(
                          'skills',
                          'Skill Set Matching',
                          'How closely student technical skills match required internship skills',
                          Icons.code,
                          const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 20),
                        _buildWeightCard(
                          'domains',
                          'Domain & Interest Alignment',
                          'Match between student interests and internship domains/keywords',
                          Icons.category,
                          const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(height: 20),
                        _buildWeightCard(
                          'experience',
                          'Experience Level',
                          'Weight for matching experience requirements and proficiency levels',
                          Icons.workspace_premium,
                          const Color(0xFFEC4899),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildWeightCard(
                          'preferences',
                          'Work Preferences',
                          'Match for work mode (Remote/Hybrid/On-site) and stipend expectations',
                          Icons.tune,
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 20),
                        _buildWeightCard(
                          'location',
                          'Location Compatibility',
                          'Geographic proximity and location preference matching',
                          Icons.location_on,
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoCard(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Action Buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _hasChanges ? _resetToDefaults : null,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Defaults'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _hasChanges && !_isSaving ? _handleSave : null,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _hasChanges ? AppColors.deepGreen : Colors.grey,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _hasChanges ? _resetToDefaults : null,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Defaults'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _hasChanges && !_isSaving ? _handleSave : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: _hasChanges ? AppColors.deepGreen : Colors.grey,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeightBalanceIndicator() {
    final isBalanced = _isValidSum;
    // ... (logic)

    return Container(
      padding: const EdgeInsets.all(20),
      // ... decoration
      child: LayoutBuilder(
        builder: (context, constraints) {
           final isMobile = constraints.maxWidth < 600;
           if (isMobile) {
             return Column(
               children: [
                 Row(
                   children: [
                     Container(
                        // Icon
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isBalanced ? Colors.green.shade50 : Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isBalanced ? Icons.check_circle : Icons.warning_amber,
                          color: isBalanced ? Colors.green : Colors.orange,
                          size: 28,
                        ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBalanced ? 'Weights Balanced' : 'Weights Imbalanced',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isBalanced ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isBalanced
                                  ? 'Total: ${(_totalWeight * 100).toStringAsFixed(0)}% (Valid)'
                                  : 'Total: ${(_totalWeight * 100).toStringAsFixed(0)}% (Invalid)',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 // Visual representation full width
                 Column(
                    children: [
                      Row(
                        children: _weights.entries.map((e) {
                          return Expanded(
                            flex: (e.value * 100).round(),
                            child: Container(
                              height: 8,
                              color: _getWeightColor(e.key),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0%', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          Text('100%', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                 ),
               ],
             );
           }

           // Desktop Row Layout
           return Row(
              // ... existing Row implementation but simpler
              children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isBalanced ? Colors.green.shade50 : Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBalanced ? Icons.check_circle : Icons.warning_amber,
                      color: isBalanced ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBalanced ? 'Weights Balanced' : 'Weights Imbalanced',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isBalanced ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBalanced
                              ? 'Total weight: ${(_totalWeight * 100).toStringAsFixed(0)}% - Configuration is valid'
                              : 'Total weight: ${(_totalWeight * 100).toStringAsFixed(0)}% - Should be approximately 100%',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        Row(
                          children: _weights.entries.map((e) {
                            return Expanded(
                              flex: (e.value * 100).round(),
                              child: Container(
                                height: 8,
                                color: _getWeightColor(e.key),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0%', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            Text('100%', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
           );
        },
      ),
    );
  }

  Color _getWeightColor(String key) {
    switch (key) {
      case 'skills':
        return const Color(0xFF3B82F6);
      case 'domains':
        return const Color(0xFF8B5CF6);
      case 'preferences':
        return const Color(0xFFF59E0B);
      case 'location':
        return const Color(0xFF10B981);
      case 'experience':
        return const Color(0xFFEC4899);
      default:
        return Colors.grey;
    }
  }

  Widget _buildWeightCard(
    String key,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final value = _weights[key] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: (v) => _updateWeight(key, v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text('50%', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text('100%', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.softMint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightMint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.deepGreen, size: 24),
              const SizedBox(width: 12),
              const Text(
                'How It Works',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.deepGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Weights determine importance of each factor in ranking'),
          _buildInfoItem('Higher weight = more influence on match score'),
          _buildInfoItem('Total weights should sum to approximately 100%'),
          _buildInfoItem('Changes apply instantly to all new recommendations'),
          _buildInfoItem('AI recalculates scores using current weights'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.mediumGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textDark.withOpacity(0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

}
