import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sora for display/headline/title (matches the web's Sora Variable),
/// IBM Plex Sans for body/labels. google_fonts caches the files after the
/// first download; bundle them under assets/fonts for fully offline builds.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _display({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.sora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: -0.2,
    );
  }

  static TextStyle _body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.ibmPlexSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static String get displayFamily => GoogleFonts.sora().fontFamily ?? 'Sora';
  static String get bodyFamily =>
      GoogleFonts.ibmPlexSans().fontFamily ?? 'IBM Plex Sans';

  static TextStyle displayLarge({Color? color}) =>
      _display(fontSize: 32, fontWeight: FontWeight.w700, color: color);

  static TextStyle displayMedium({Color? color}) =>
      _display(fontSize: 28, fontWeight: FontWeight.w700, color: color);

  static TextStyle headlineLarge({Color? color}) =>
      _display(fontSize: 24, fontWeight: FontWeight.w700, color: color);

  static TextStyle headlineMedium({Color? color}) =>
      _display(fontSize: 20, fontWeight: FontWeight.w600, color: color);

  static TextStyle headlineSmall({Color? color}) =>
      _display(fontSize: 18, fontWeight: FontWeight.w600, color: color);

  static TextStyle titleLarge({Color? color}) =>
      _display(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  static TextStyle titleMedium({Color? color}) =>
      _body(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  static TextStyle bodyLarge({Color? color}) =>
      _body(fontSize: 16, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle bodyMedium({Color? color}) =>
      _body(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle bodySmall({Color? color}) =>
      _body(fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle labelLarge({Color? color}) =>
      _body(fontSize: 14, fontWeight: FontWeight.w500, color: color);

  static TextStyle labelMedium({Color? color}) =>
      _body(fontSize: 12, fontWeight: FontWeight.w500, color: color);

  static TextStyle labelSmall({Color? color}) =>
      _body(fontSize: 10, fontWeight: FontWeight.w500, color: color);

  static TextStyle button({Color? color}) =>
      _body(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  static TextStyle caption({Color? color}) =>
      _body(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  /// 12px, +8% tracking, uppercase — section eyebrows (same as web `.eyebrow`).
  static TextStyle eyebrow({Color? color}) => _body(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ).copyWith(letterSpacing: 0.9);

  /// Big numbers on stat tiles.
  static TextStyle stat({Color? color}) =>
      _display(fontSize: 22, fontWeight: FontWeight.w700, color: color, height: 1.0);
}
