import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle displayLarge({Color? color}) =>
      _inter(fontSize: 32, fontWeight: FontWeight.w700, color: color);

  static TextStyle displayMedium({Color? color}) =>
      _inter(fontSize: 28, fontWeight: FontWeight.w700, color: color);

  static TextStyle headlineLarge({Color? color}) =>
      _inter(fontSize: 24, fontWeight: FontWeight.w600, color: color);

  static TextStyle headlineMedium({Color? color}) =>
      _inter(fontSize: 20, fontWeight: FontWeight.w600, color: color);

  static TextStyle headlineSmall({Color? color}) =>
      _inter(fontSize: 18, fontWeight: FontWeight.w600, color: color);

  static TextStyle titleLarge({Color? color}) =>
      _inter(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  static TextStyle titleMedium({Color? color}) =>
      _inter(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  static TextStyle bodyLarge({Color? color}) =>
      _inter(fontSize: 16, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle bodyMedium({Color? color}) =>
      _inter(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle bodySmall({Color? color}) =>
      _inter(fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle labelLarge({Color? color}) =>
      _inter(fontSize: 14, fontWeight: FontWeight.w500, color: color);

  static TextStyle labelMedium({Color? color}) =>
      _inter(fontSize: 12, fontWeight: FontWeight.w500, color: color);

  static TextStyle labelSmall({Color? color}) =>
      _inter(fontSize: 10, fontWeight: FontWeight.w500, color: color);

  static TextStyle button({Color? color}) =>
      _inter(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  static TextStyle caption({Color? color}) =>
      _inter(fontSize: 12, fontWeight: FontWeight.w400, color: color);
}
