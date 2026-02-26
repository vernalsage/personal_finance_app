import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:notification_listener_service/notification_listener_service.dart';
import '../../core/di/usecase_providers.dart';
import '../../core/di/repository_providers.dart';
import '../../domain/repositories/inotification_fingerprint_repository.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../application/services/transaction_parser_service.dart';

/// Service for listening to bank notifications and processing transactions
class BankNotificationListener {
  BankNotificationListener({
    required this.transactionParserService,
    required this.createTransactionUseCase,
    required this.localNotifications,
    required this.fingerprintRepository,
  });

  final TransactionParserService transactionParserService;
  final CreateTransactionUseCase createTransactionUseCase;
  final FlutterLocalNotificationsPlugin localNotifications;
  final INotificationFingerprintRepository fingerprintRepository;

  // Approved bank package names as specified in requirements
  static const List<String> _approvedPackages = [
    'com.gtbank.gtworld',
    'com.zenithbank.mobile',
    'com.opay.client',
    'com.moniepoint.personalapp',
    'com.transsnet.palmpay',
  ];

  StreamSubscription? _notificationSubscription;

  /// Initialize the notification listener
  Future<void> initialize() async {
    final granted = await isPermissionGranted();
    if (!granted) return;

    // Start listening to notifications - Placeholder for when package is available
    /*
    _notificationSubscription = NotificationListenerService.notificationsStream.listen(
      _handleNotification,
    );
    */

    // Initial check of existing notifications
    await _checkCurrentNotifications();
  }

  /// Check current active notifications
  Future<void> _checkCurrentNotifications() async {
    try {
      // Placeholder for when package is available
      /*
      final notifications = await NotificationListenerService.getNotifications();
      for (final notification in notifications) {
        if (!_approvedPackages.contains(notification.packageName)) continue;
        
        final fingerprint = _generateFingerprint(notification.text);
        final existsResult = await fingerprintRepository.exists(fingerprint);
        if (existsResult.isSuccess && existsResult.successData == true) continue;
        
        final parsedResult = transactionParserService.parseNotification(notification.text);
        if (parsedResult.amountMinor != null && parsedResult.transactionType != null) {
          final transaction = await _createTransactionFromParsedResult(parsedResult);
          if (transaction != null) {
            final result = await createTransactionUseCase(transaction);
            if (result.isSuccess) {
              final created = result.successData!;
              if (created.requiresReview) {
                await _sendReviewNotification(created);
              }
              await fingerprintRepository.markAsProcessed(fingerprint, transactionId: created.id);
            }
          }
        }
      }
      */
    } catch (e) {
      // Log error
    }
  }

  /*
  /// Handle incoming notification
  void _handleNotification(ServiceNotificationEvent event) async {
    if (!_approvedPackages.contains(event.packageName)) return;

    final fingerprint = _generateFingerprint(event.content);
    final existsResult = await fingerprintRepository.exists(fingerprint);
    if (existsResult.isSuccess && existsResult.successData == true) return;

    final parsedResult = transactionParserService.parseNotification(event.content);
    if (parsedResult.amountMinor != null && parsedResult.transactionType != null) {
      final transaction = await _createTransactionFromParsedResult(parsedResult);
      if (transaction != null) {
        final result = await createTransactionUseCase(transaction);
        if (result.isSuccess) {
          final created = result.successData!;
          if (created.requiresReview) {
            await _sendReviewNotification(created);
          }
          await fingerprintRepository.markAsProcessed(fingerprint, transactionId: created.id);
        }
      }
    }
  }
  */

  /// Generate SHA256 fingerprint for duplicate detection
  String _generateFingerprint(String text) {
    final bytes = utf8.encode(text.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create transaction entity from parsed result
  Future<dynamic> _createTransactionFromParsedResult(ParsedTransactionResult parsed) async {
    return null; // Implementation deferred to use cases
  }

  /// Send a local notification for review
  Future<void> _sendReviewNotification(dynamic transaction) async {
    const androidDetails = AndroidNotificationDetails(
      'finance_review',
      'Transaction Review',
      channelDescription: 'Notifications for transactions that need review',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await localNotifications.show(
      transaction.id.hashCode,
      'New Transaction to Review',
      'A transaction of ${transaction.amountMinor} needs your attention.',
      details,
    );
  }

  /// Stop listening and cleanup resources
  Future<void> dispose() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  /// Check if notification listener permission is granted
  Future<bool> isPermissionGranted() async {
    // return await NotificationListenerService.isPermissionGranted();
    return false;
  }

  /// Request notification listener permission
  Future<void> requestPermission() async {
    // await NotificationListenerService.requestPermission();
  }
}

/// Provider for BankNotificationListener
final bankNotificationListenerProvider = Provider<BankNotificationListener>((
  ref,
) {
  final transactionParserService = TransactionParserService();
  final createTransactionUseCase = ref.read(createTransactionUseCaseProvider);
  final fingerprintRepository = ref.read(notificationFingerprintRepositoryProvider);
  final localNotifications = FlutterLocalNotificationsPlugin();

  return BankNotificationListener(
    transactionParserService: transactionParserService,
    createTransactionUseCase: createTransactionUseCase,
    localNotifications: localNotifications,
    fingerprintRepository: fingerprintRepository,
  );
});
