import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

/// Handles Firebase Cloud Messaging and local notifications.
///
/// Must be initialized in [main.dart] after Firebase.initializeApp().
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Initialize push + local notifications.
  static Future<void> initialize() async {
    // Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications setup
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Foreground handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  /// Get FCM token and save to Supabase for this user.
  static Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from(AppConstants.tableNotificationTokens)
          .upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': _platform(),
      });

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        await Supabase.instance.client
            .from(AppConstants.tableNotificationTokens)
            .upsert({
          'user_id': userId,
          'fcm_token': newToken,
          'platform': _platform(),
        });
      });
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'homeo_clinic',
      'HomeoClinic',
      channelDescription: 'Clinic notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF00D2B4),
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['reference_id'],
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle navigation — router will pick this up
    debugPrint('Notification tapped: ${response.payload}');
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
  }

  static String _platform() {
    // ignore: missing_enum_constant_in_switch
    return 'android'; // simplified; use Platform.isIOS for real device detection
  }
}

/// Background message handler — must be top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM message: ${message.messageId}');
}

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

