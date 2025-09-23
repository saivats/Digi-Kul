import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Indigo theme for education
  static const Color primary = Color(0xFF3F51B5);
  static const Color primaryLight = Color(0xFF7986CB);
  static const Color primaryDark = Color(0xFF303F9F);
  
  // Secondary colors - Complementary orange
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Live session colors
  static const Color live = Color(0xFFE53E3E);
  static const Color upcoming = Color(0xFF38A169);
  static const Color ended = Color(0xFF718096);
  
  // Card and border colors
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFBDBDBD);
  
  // Gradient colors
  static const List<Color> primaryGradient = [
    primaryLight,
    primary,
    primaryDark,
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFFF8F9FA),
    Color(0xFFE9ECEF),
  ];
  
  // Network status colors
  static const Color networkGood = Color(0xFF4CAF50);
  static const Color networkPoor = Color(0xFFFF9800);
  static const Color networkOffline = Color(0xFFF44336);
  
  // Chat colors
  static const Color chatBubbleStudent = Color(0xFFE3F2FD);
  static const Color chatBubbleTeacher = Color(0xFFF3E5F5);
  static const Color chatBubbleSystem = Color(0xFFFFF3E0);
  
  // Material 3 inspired colors
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  
  // Disabled states
  static const Color disabled = Color(0xFF9E9E9E);
  static const Color disabledBackground = Color(0xFFE0E0E0);
  
  // Shimmer colors for loading states
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  
  // Overlay colors
  static const Color overlayLight = Color(0x1A000000);
  static const Color overlayMedium = Color(0x4D000000);
  static const Color overlayDark = Color(0x80000000);
}
