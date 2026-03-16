import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

/// Handy extension methods used across the codebase.

extension StringX on String {
  /// Capitalize the first letter.
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Convert snake_case to Title Case.
  String get snakeToTitle => split('_')
      .map((w) => w.capitalize)
      .join(' ');

  /// Trim and check for emptiness in one call.
  bool get isBlank => trim().isEmpty;

  /// True when this is not blank.
  bool get isNotBlank => !isBlank;

  /// Returns null when blank, otherwise the trimmed value.
  String? get nullIfBlank => isBlank ? null : trim();
}

extension DateTimeX on DateTime {
  /// True if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Strip time component — returns midnight of the same day.
  DateTime get dateOnly => DateTime(year, month, day);

  /// True if this is in the past (including today).
  bool get isPast => isBefore(DateTime.now());

  /// True if the appointment is within [hours] hours from now.
  bool isWithinHours(int hours) =>
      difference(DateTime.now()).inHours.abs() <= hours;
}

extension ContextX on BuildContext {
  /// MediaQuery shorthand.
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  bool get isSmallScreen => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;

  /// Theme shorthand.
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Show a branded snackbar.
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showErrorSnackBar(String message) =>
      showSnackBar(message, isError: true);
}

extension AppointmentStatusColorX on AppointmentStatus {
  Color get color {
    switch (this) {
      case AppointmentStatus.scheduled:
        return AppColors.statusScheduled;
      case AppointmentStatus.waiting:
        return AppColors.statusWaiting;
      case AppointmentStatus.inProgress:
        return AppColors.statusInProgress;
      case AppointmentStatus.completed:
        return AppColors.statusCompleted;
      case AppointmentStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }
}

extension UserRoleIconX on UserRole {
  IconData get icon {
    switch (this) {
      case UserRole.doctor:
        return Icons.medical_services_rounded;
      case UserRole.staff:
        return Icons.badge_rounded;
      case UserRole.receptionist:
        return Icons.support_agent_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.labPartner:
        return Icons.biotech_rounded;
      case UserRole.patient:
        return Icons.person_rounded;
    }
  }
}

extension ListX<T> on List<T> {
  /// Safe index access, returns null if out of range.
  T? safeGet(int index) => index >= 0 && index < length ? this[index] : null;
}

