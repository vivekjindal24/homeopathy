import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A styled card container matching the clinic design system.
class ClinicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool showBorder;
  final double borderRadius;

  const ClinicCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.showBorder = true,
    this.borderRadius = AppSpacing.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.overlay10,
          highlightColor: AppColors.overlay10,
          child: container,
        ),
      );
    }

    return container;
  }
}

/// A summary metric card (used on dashboard).
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: accentColor, size: AppSpacing.iconLg),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTypography.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

/// Horizontal key-value row inside a card.
class CardRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const CardRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTypography.bodySmall),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

