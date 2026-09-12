import 'package:flutter/material.dart';

/// Digi-Kul design language — "Ink & Saffron".
/// Mirrors frontend/app/globals.css. Change both together.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF3730A3); // ink
  static const primaryLight = Color(0xFF6366F1); // ink bright
  static const primaryDark = Color(0xFF2A2880);
  static const primarySoft = Color(0xFFEEEDFB);

  static const accent = Color(0xFFF59E0B); // saffron
  static const accentLight = Color(0xFFFCD34D);
  static const accentSoft = Color(0xFFFFF7E6);
  static const accentInk = Color(0xFFB45309);

  // Semantic
  static const success = Color(0xFF059669);
  static const error = Color(0xFFE11D48);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // Session / connection states — identical to the web tokens
  static const live = Color(0xFFE11D48);
  static const liveSoft = Color(0xFFFFF1F2);
  static const scheduled = Color(0xFFF59E0B);
  static const scheduledSoft = Color(0xFFFFF7E6);
  static const ended = Color(0xFF64748B);
  static const endedSoft = Color(0xFFF1F5F9);
  static const offline = Color(0xFFB45309);
  static const offlineSoft = Color(0xFFFFF7E6);
  static const online = Color(0xFF059669);
  static const onlineSoft = Color(0xFFECFDF5);

  // Legacy aliases still referenced by widgets
  static const liveRed = live;
  static const audioGreen = online;
  static const chatOnly = ended;

  // Light surfaces
  static const surface = Color(0xFFF6F5FB);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF14132B);
  static const textSecondary = Color(0xFF5F5E7A);
  static const divider = Color(0xFFE6E4F0);
  static const shimmerBase = Color(0xFFE6E4F0);
  static const shimmerHighlight = Color(0xFFF6F5FB);

  // Call surface (live session) / dark theme
  static const darkSurface = Color(0xFF0E1020);
  static const darkCard = Color(0xFF171A2E);
  static const darkBorder = Color(0xFF262A44);
  static const darkTextPrimary = Color(0xFFEEF0FF);
  static const darkTextSecondary = Color(0xFF9DA2C4);
  static const darkLiveText = Color(0xFFFB7185);
  static const darkOnlineText = Color(0xFF34D399);
  static const darkWarnText = Color(0xFFFBBF24);
}
