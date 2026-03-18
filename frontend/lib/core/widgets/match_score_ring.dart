import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MatchScoreRing extends StatelessWidget {
  final int score;
  final double size;

  const MatchScoreRing({
    super.key,
    required this.score,
    this.size = 50.0,
  });

  Color _getScoreColor() {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return const Color(0xFFF59E0B); // Yellow
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
          Text(
            '$score%',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
