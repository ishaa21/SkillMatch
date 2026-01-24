import 'package:flutter/material.dart';
import 'dart:math';

/// Utility class for responsive design scaling and layout adaptation.
class Responsive {
  // Standard mobile design baseline (iPhone X/11/12/13/Mini dimensions approx)
  static const double _designWidth = 375.0;
  // static const double _designHeight = 812.0; // Not typically used for width-based scaling

  /// Returns a width that scales proportionally to the screen width.
  /// Used for padding, margins, standard widths.
  static double w(BuildContext context, double value) {
    double screenWidth = MediaQuery.of(context).size.width;
    // For tablets/desktop, we might want to cap the width scaling to avoid oversized elements
    // or switch to a different baseline. Here we cap strictly scaling relative to mobile.
    // effectiveWidth maps tablet width closer to mobile components scaling logic 
    // to prevent button/padding explosion.
    double effectiveWidth = screenWidth > 600 ? 500 + (screenWidth - 600) * 0.5 : screenWidth;
    return (value / _designWidth) * effectiveWidth;
  }

  /// Returns a font size that scales with screen width but is clamped 
  /// to maintain readability and avoid cartoonish sizes on tablets.
  static double sp(BuildContext context, double value) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scale = screenWidth / _designWidth;
    
    // Clamp scale factors
    if (scale > 1.4) scale = 1.4; // Max text scale for tablets
    if (scale < 0.85) scale = 0.85; // Min text scale for small phones
    
    return value * scale;
  }
  
  /// Helper checks for device type
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;
}

/// Extension for cleaner syntax: 24.sp(context), 16.w(context)
extension ResponsiveNum on num {
  double w(BuildContext context) => Responsive.w(context, this.toDouble());
  double h(BuildContext context) => Responsive.w(context, this.toDouble()); // Usually width-based scaling is preferred for UI consistency
  double sp(BuildContext context) => Responsive.sp(context, this.toDouble());
}

/// Responsive Spacing Constants
class AppSpacing {
  static double xs(BuildContext context) => 4.w(context);
  static double s(BuildContext context) => 8.w(context);
  static double m(BuildContext context) => 16.w(context);
  static double l(BuildContext context) => 24.w(context);
  static double xl(BuildContext context) => 32.w(context);
  static double xxl(BuildContext context) => 48.w(context);
}
