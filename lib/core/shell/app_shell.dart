import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/empty_state.dart';

/// Main app shell — provides bottom navigation bar for authenticated users.
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final location = GoRouterState.of(context).matchedLocation;

    if (user == null) return const SizedBox.shrink();

    final navItems = _navItemsForRole(user.role, unreadCount);
    final selectedIndex = _indexForLocation(location, navItems);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (i) {
                final item = navItems[i];
                final isSelected = i == selectedIndex;
                return _NavItem(
                  icon: item.icon,
                  activeIcon: item.activeIcon,
                  label: item.label,
                  badge: item.badge,
                  isSelected: isSelected,
                  onTap: () => context.go(item.route),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  List<_NavItemData> _navItemsForRole(UserRole role, int unreadCount) {
    final baseItems = [
      _NavItemData(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        route: AppRoutes.dashboard,
      ),
    ];

    // Patients tab — all clinic staff see patients; lab partner and patient do not
    if (role != UserRole.labPartner && role != UserRole.patient) {
      baseItems.add(_NavItemData(
        label: 'Patients',
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        route: AppRoutes.patientList,
      ));
    }

    // Queue tab — clinic staff (except lab partner / patient)
    if (role != UserRole.labPartner && role != UserRole.patient) {
      baseItems.add(_NavItemData(
        label: 'Queue',
        icon: Icons.list_alt_outlined,
        activeIcon: Icons.list_alt_rounded,
        route: AppRoutes.queue,
      ));
    }

    // Commissions tab — doctor and admin only
    if (role == UserRole.doctor || role == UserRole.admin) {
      baseItems.add(_NavItemData(
        label: 'Commissions',
        icon: Icons.monetization_on_outlined,
        activeIcon: Icons.monetization_on_rounded,
        route: AppRoutes.commissions,
      ));
    }

    // Notifications tab — everyone
    baseItems.add(_NavItemData(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      route: AppRoutes.notifications,
      badge: unreadCount > 0 ? '$unreadCount' : null,
    ));

    return baseItems;
  }

  int _indexForLocation(String location, List<_NavItemData> items) {
    for (int i = items.length - 1; i >= 0; i--) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final String? badge;

  _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.badge,
  });
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: color,
                    size: AppSpacing.iconLg,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

