import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Circular avatar for a patient — shows image if URL provided, else initials.
class PatientAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;

  const PatientAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.overlay20,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => _initials(),
                errorWidget: (_, __, ___) => _initials(),
              ),
            )
          : _initials(),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }

  Widget _initials() {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Text(
      initials,
      style: AppTypography.headlineSmall.copyWith(
        fontSize: radius * 0.65,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

