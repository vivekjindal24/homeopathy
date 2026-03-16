import 'package:flutter/material.dart';

/// All color tokens for the homeopathy clinic design system.
/// White and purple modern minimalist palette.
class AppColors {
  AppColors._();

  // Brand — purple scale
  static const primary = Color(0xFF7C3AED);       // Violet-600
  static const primaryDark = Color(0xFF5B21B6);   // Violet-800
  static const primaryLight = Color(0xFFA78BFA);  // Violet-400

  static const secondary = Color(0xFF9333EA);     // Purple-600
  static const secondaryDark = Color(0xFF7E22CE); // Purple-800

  // Backgrounds
  static const background = Color(0xFFFFFFFF);    // Pure white
  static const surface = Color(0xFFF5F3FF);       // Violet-50
  static const card = Color(0xFFFFFFFF);          // White card
  static const cardElevated = Color(0xFFF3F0FF);  // Violet-100

  // Text
  static const textPrimary = Color(0xFF1E1B4B);   // Indigo-950 (near-black)
  static const textSecondary = Color(0xFF6B7280); // Gray-500
  static const textDisabled = Color(0xFFD1D5DB);  // Gray-300
  static const textInverse = Color(0xFFFFFFFF);   // White on purple buttons

  // Semantic
  static const success = Color(0xFF10B981);  // Emerald-500
  static const warning = Color(0xFFF59E0B);  // Amber-500
  static const error = Color(0xFFEF4444);    // Red-500
  static const info = Color(0xFF3B82F6);     // Blue-500

  // Status
  static const statusScheduled = Color(0xFF3B82F6);  // Blue
  static const statusWaiting = Color(0xFFF59E0B);    // Amber
  static const statusInProgress = Color(0xFF7C3AED); // Purple (primary)
  static const statusCompleted = Color(0xFF10B981);  // Green
  static const statusCancelled = Color(0xFFEF4444);  // Red

  // Vitals
  static const vitalNormal = Color(0xFF10B981);
  static const vitalWarning = Color(0xFFF59E0B);
  static const vitalDanger = Color(0xFFEF4444);

  // Borders & dividers
  static const border = Color(0xFFE5E7EB);    // Gray-200
  static const divider = Color(0xFFF3F4F6);   // Gray-100

  // Overlays (purple-tinted)
  static const overlay20 = Color(0x337C3AED); // 20 % violet
  static const overlay10 = Color(0x1A7C3AED); // 10 % violet

  // Chart palette
  static const chartColors = [
    Color(0xFF7C3AED),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFF9333EA),
  ];
}

