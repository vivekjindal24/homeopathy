import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Primary CTA button used throughout the clinic app.
///
/// Supports three variants: [ClinicButtonVariant.primary],
/// [ClinicButtonVariant.secondary], and [ClinicButtonVariant.ghost].
enum ClinicButtonVariant { primary, secondary, ghost, danger }

class ClinicButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ClinicButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final double height;

  const ClinicButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ClinicButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case ClinicButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(AppColors.textInverse),
        );
      case ClinicButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(AppColors.primary),
        );
      case ClinicButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(AppColors.primary),
        );
      case ClinicButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textPrimary,
          ),
          child: _buildChild(AppColors.textPrimary),
        );
    }
  }

  Widget _buildChild(Color foreground) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: foreground,
          strokeWidth: 2,
        ),
      );
    }

    final labelWidget = Text(
      label,
      style: AppTypography.labelLarge.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    );

    if (prefixIcon == null && suffixIcon == null) return labelWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: AppSpacing.iconMd, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        labelWidget,
        if (suffixIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(suffixIcon, size: AppSpacing.iconMd, color: foreground),
        ],
      ],
    );
  }
}

/// Icon-only circular button.
class ClinicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const ClinicIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 40,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: size * 0.45,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

