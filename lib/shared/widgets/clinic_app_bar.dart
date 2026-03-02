import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Branded app bar used across all clinic screens.
class ClinicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const ClinicAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.leading,
    this.centerTitle = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTypography.headlineMedium),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTypography.bodySmall,
            ),
        ],
      ),
      centerTitle: centerTitle,
      leading: leading ??
          (showBack && Navigator.of(context).canPop()
              ? IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                )
              : null),
      automaticallyImplyLeading: showBack,
      actions: actions,
      bottom: bottom,
      backgroundColor: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const Border(
        bottom: BorderSide(color: AppColors.border, width: 1),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (subtitle != null ? 20 : 0) + (bottom?.preferredSize.height ?? 0),
      );
}

/// Page header used in dashboard-style pages (not a full AppBar).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final Widget? trailingWidget;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headlineSmall),
        if (trailingWidget != null)
          trailingWidget!
        else if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Gradient header tile used on profile / patient detail pages.
class ClinicGradientHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const ClinicGradientHeader({
    super.key,
    required this.child,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.card],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: child,
    );
  }
}

