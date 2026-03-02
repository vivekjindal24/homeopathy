import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/models/models.dart';
import '../../data/notification_repository.dart';

/// Stream of notifications for the current user.
final notificationStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watchNotifications(userId);
});

/// Count of unread notifications — used for badge.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifAsync = ref.watch(notificationStreamProvider);
  return notifAsync.valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;
});

/// Notifier to mark notifications as read.
class NotificationNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return [];
    return ref.read(notificationRepositoryProvider).fetchForUser(userId);
  }

  Future<void> markRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    ref.invalidateSelf();
  }

  Future<void> markAllRead() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await ref.read(notificationRepositoryProvider).markAllRead(userId);
    ref.invalidateSelf();
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, List<NotificationModel>>(
        NotificationNotifier.new);

