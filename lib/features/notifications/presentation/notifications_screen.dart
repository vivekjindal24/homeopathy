import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/clinic_app_bar.dart';
import '../../../shared/widgets/clinic_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import 'providers/notification_provider.dart';

/// Screen listing all in-app notifications with mark-read actions.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationNotifierProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: 'Notifications',
        subtitle: unread > 0 ? '$unread unread' : 'All caught up',
        showBack: false,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationNotifierProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: ShimmerList(count: 5),
        ),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: notifs.length,
            itemBuilder: (_, i) => _NotifTile(notification: notifs[i]),
          );
        },
      ),
    );
  }
}

class _NotifTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotifTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: n.isRead ? AppColors.card : AppColors.overlay10,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: n.isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _iconColor(n.type).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon(n.type), color: _iconColor(n.type), size: 20),
        ),
        title: Text(
          n.title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.body, style: AppTypography.bodySmall, maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(AppFormatters.dateTime(n.createdAt),
                style: AppTypography.labelSmall),
          ],
        ),
        trailing: !n.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!n.isRead) {
            ref
                .read(notificationNotifierProvider.notifier)
                .markRead(n.id);
          }
        },
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'prescription':
        return Icons.description_rounded;
      case 'lab_report':
        return Icons.science_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'appointment':
        return AppColors.secondary;
      case 'prescription':
        return AppColors.primary;
      case 'lab_report':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

