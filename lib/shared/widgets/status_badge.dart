import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/extensions.dart';

/// Pill-shaped status badge with appointment status color.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  /// Named constructor for [AppointmentStatus].
  factory StatusBadge.fromStatus(AppointmentStatus status) {
    return StatusBadge(
      label: status.displayName,
      color: status.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Role badge (doctor / staff / patient).
class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.doctor => AppColors.primary,
      UserRole.staff => AppColors.secondary,
      UserRole.patient => AppColors.warning,
    };

    return StatusBadge(label: role.name.toUpperCase(), color: color);
  }
}

