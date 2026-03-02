import 'package:flutter/material.dart';

/// All color tokens for the homeopathy clinic design system.
/// Every value is DARK-MODE only.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF00D2B4);
  static const primaryDark = Color(0xFF009E87);
  static const primaryLight = Color(0xFF33DCC3);
  static const secondary = Color(0xFF3882FF);
  static const secondaryDark = Color(0xFF1F5FCC);

  // Backgrounds
  static const background = Color(0xFF060C18);
  static const surface = Color(0xFF0D1628);
  static const card = Color(0xFF111E35);
  static const cardElevated = Color(0xFF172540);

  // Text
  static const textPrimary = Color(0xFFE2EAF8);
  static const textSecondary = Color(0xFF6B7FA3);
  static const textDisabled = Color(0xFF3D4F6E);
  static const textInverse = Color(0xFF060C18);

  // Semantic
  static const success = Color(0xFF00C48C);
  static const warning = Color(0xFFFFD232);
  static const error = Color(0xFFFF508C);
  static const info = Color(0xFF3882FF);

  // Status
  static const statusScheduled = Color(0xFF3882FF);
  static const statusWaiting = Color(0xFFFFD232);
  static const statusInProgress = Color(0xFF00D2B4);
  static const statusCompleted = Color(0xFF00C48C);
  static const statusCancelled = Color(0xFFFF508C);

  // Vitals
  static const vitalNormal = Color(0xFF00C48C);
  static const vitalWarning = Color(0xFFFFD232);
  static const vitalDanger = Color(0xFFFF508C);

  // Borders & dividers
  static const border = Color(0xFF1E2F4A);
  static const divider = Color(0xFF0F1B2E);

  // Overlays
  static const overlay20 = Color(0x3300D2B4);
  static const overlay10 = Color(0x1A00D2B4);

  // Chart palette
  static const chartColors = [
    Color(0xFF00D2B4),
    Color(0xFF3882FF),
    Color(0xFFFFD232),
    Color(0xFFFF508C),
    Color(0xFF00C48C),
    Color(0xFFAB6BFF),
  ];
}

