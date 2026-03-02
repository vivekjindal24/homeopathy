import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/models.dart';

/// Repository for in-app notifications.
class NotificationRepository {
  final SupabaseClient _client;
  NotificationRepository(this._client);

  Future<List<NotificationModel>> fetchForUser(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.tableNotifications)
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from(AppConstants.tableNotifications)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  Future<void> markAllRead(String userId) async {
    try {
      await _client
          .from(AppConstants.tableNotifications)
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Real-time stream for a user's notifications.
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _client
        .from(AppConstants.tableNotifications)
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at')
        .map((rows) =>
            rows.map((e) => NotificationModel.fromJson(e)).toList());
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

