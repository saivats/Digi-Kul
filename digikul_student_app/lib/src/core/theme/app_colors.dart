import 'package:flutter/material.dart';

/// Application color palette following Material Design 3 principles
/// Optimized for educational content and accessibility
class AppColors {
  // Primary Colors - Indigo theme for education and trust
  static const Color primary = Color(0xFF3F51B5);
  static const Color primaryLight = Color(0xFF7986CB);
  static const Color primaryDark = Color(0xFF303F9F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  // Secondary Colors - Complementary orange for highlights
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);
  static const Color onSecondary = Color(0xFF000000);
  
  // Tertiary Colors - Green for success states
  static const Color tertiary = Color(0xFF4CAF50);
  static const Color tertiaryLight = Color(0xFF81C784);
  static const Color tertiaryDark = Color(0xFF388E3C);
  static const Color onTertiary = Color(0xFFFFFFFF);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color onBackground = Color(0xFF1C1B1F);
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F3F3);
  static const Color surfaceTint = Color(0xFFE8F4FD);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF000000);
  static const Color textDisabled = Color(0xFF9E9E9E);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color onSuccess = Color(0xFFFFFFFF);
  
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFF000000);
  
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color onError = Color(0xFFFFFFFF);
  
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color onInfo = Color(0xFFFFFFFF);
  
  // Live Session Status Colors
  static const Color live = Color(0xFFE53E3E);
  static const Color liveBackground = Color(0xFFFFEBEE);
  
  static const Color upcoming = Color(0xFF38A169);
  static const Color upcomingBackground = Color(0xFFE8F5E8);
  
  static const Color ended = Color(0xFF718096);
  static const Color endedBackground = Color(0xFFF5F5F5);
  
  // Interactive Colors
  static const Color link = Color(0xFF1976D2);
  static const Color linkHover = Color(0xFF1565C0);
  static const Color linkVisited = Color(0xFF7B1FA2);
  
  // Border and Outline Colors
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocus = primary;
  
  // Shadow and Overlay Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowStrong = Color(0x4D000000);
  static const Color scrim = Color(0x80000000);
  
  // Overlay Colors for different states
  static const Color overlayLight = Color(0x0A000000);
  static const Color overlayMedium = Color(0x1F000000);
  static const Color overlayDark = Color(0x3D000000);
  
  // Network Status Colors
  static const Color networkGood = Color(0xFF4CAF50);
  static const Color networkPoor = Color(0xFFFF9800);
  static const Color networkOffline = Color(0xFFF44336);
  
  // Chat Colors
  static const Color chatBubbleStudent = Color(0xFFE3F2FD);
  static const Color chatBubbleTeacher = Color(0xFFF3E5F5);
  static const Color chatBubbleSystem = Color(0xFFFFF3E0);
  static const Color chatInputBackground = Color(0xFFF8F9FA);
  
  // Audio Player Colors
  static const Color audioPlayerBackground = Color(0xFF263238);
  static const Color audioPlayerText = Color(0xFFFFFFFF);
  static const Color audioProgress = primary;
  static const Color audioProgressBackground = Color(0xFFE0E0E0);
  
  // Download Status Colors
  static const Color downloadPending = Color(0xFF9E9E9E);
  static const Color downloadProgress = Color(0xFF2196F3);
  static const Color downloadComplete = Color(0xFF4CAF50);
  static const Color downloadError = Color(0xFFF44336);
  static const Color downloadPaused = Color(0xFFFF9800);
  
  // Shimmer Colors for Loading States
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  
  // Card Colors
  static const Color cardBackground = surface;
  static const Color cardBorder = outline;
  static const Color cardShadow = shadow;
  
  // Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonTextDisabled = Color(0xFF9E9E9E);
  
  // Input Field Colors
  static const Color inputBackground = surfaceVariant;
  static const Color inputBorder = outline;
  static const Color inputBorderFocus = primary;
  static const Color inputBorderError = error;
  static const Color inputText = textPrimary;
  static const Color inputHint = textHint;
  static const Color inputLabel = textSecondary;
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    primaryLight,
    primary,
    primaryDark,
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFFF8F9FA),
    Color(0xFFE9ECEF),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF81C784),
    success,
  ];
  
  static const List<Color> errorGradient = [
    Color(0xFFEF5350),
    error,
  ];
  
  // Dark Theme Colors (for future dark mode support)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnBackground = Color(0xFFE1E1E1);
  static const Color darkOnSurface = Color(0xFFE1E1E1);
  static const Color darkTextPrimary = Color(0xFFE1E1E1);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  
  // Accessibility Colors (high contrast)
  static const Color highContrastText = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  static const Color highContrastPrimary = Color(0xFF0D47A1);
  static const Color highContrastSecondary = Color(0xFFE65100);
  
  // Semantic Colors for different content types
  static const Color mathColor = Color(0xFF673AB7);
  static const Color scienceColor = Color(0xFF009688);
  static const Color languageColor = Color(0xFFE91E63);
  static const Color historyColor = Color(0xFF795548);
  static const Color artColor = Color(0xFFFF5722);
  
  // Helper method to get color by name
  static Color getColorByName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'primary':
        return primary;
      case 'secondary':
        return secondary;
      case 'success':
        return success;
      case 'warning':
        return warning;
      case 'error':
        return error;
      case 'info':
        return info;
      default:
        return primary;
    }
  }
  
  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'live':
        return live;
      case 'upcoming':
        return upcoming;
      case 'ended':
      case 'completed':
        return ended;
      case 'success':
        return success;
      case 'warning':
        return warning;
      case 'error':
      case 'failed':
        return error;
      default:
        return textSecondary;
    }
  }
}
