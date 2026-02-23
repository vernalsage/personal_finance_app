import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../../core/errors/exceptions.dart';

/// Service for handling notifications
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification services
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Request notification listener permission
    final isGranted = await NotificationListenerService.isPermissionGranted();
    if (!isGranted) {
      await NotificationListenerService.requestPermission();
    }
  }

  /// Check if notification listener permission is granted
  Future<bool> isNotificationListenerPermissionGranted() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  /// Request notification listener permission
  Future<bool> requestNotificationListenerPermission() async {
    return await NotificationListenerService.requestPermission();
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'personal_finance_channel',
      'Personal Finance',
      channelDescription: 'Notifications for personal finance app',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Start listening for notifications
  Future<void> startListening(
    Function(Map<String, dynamic>) onNotification,
  ) async {
    try {
      // Check if permission is granted
      final isGranted = await NotificationListenerService.isPermissionGranted();
      if (!isGranted) {
        throw SecurityException(
          'Notification listener permission not granted',
          'PERMISSION_DENIED',
        );
      }

      // Note: The notification_listener_service package doesn't provide direct listening methods
      // This is a placeholder implementation that would need to be customized
      // based on the actual package API or platform-specific implementation

      // TODO: Implement actual notification listening based on package capabilities
      // For now, we'll just indicate that listening would start here
    } catch (e) {
      throw SecurityException(
        'Failed to start notification listening: $e',
        'LISTENING_ERROR',
      );
    }
  }

  /// Stop listening for notifications
  Future<void> stopListening() async {
    try {
      // TODO: Implement actual notification stopping based on package capabilities
      // For now, we'll just indicate that listening would stop here
    } catch (e) {
      throw SecurityException(
        'Failed to stop notification listening: $e',
        'LISTENING_ERROR',
      );
    }
  }

  /// Check if notification service is running
  Future<bool> isListening() async {
    try {
      // Check if permission is granted as a basic indicator
      return await NotificationListenerService.isPermissionGranted();
    } catch (e) {
      return false;
    }
  }
}
