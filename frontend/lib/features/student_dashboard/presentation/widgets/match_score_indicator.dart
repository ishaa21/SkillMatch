import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MatchScoreIndicator extends StatelessWidget {
  final int percentage;
  final double size;

  const MatchScoreIndicator({super.key, required this.percentage, this.size = 50});

  @override
  Widget build(BuildContext context) {
    Color color = percentage >= 80 ? AppColors.primary : (percentage >= 50 ? Colors.orange : Colors.red);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 4,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
