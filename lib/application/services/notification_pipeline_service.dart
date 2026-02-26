import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/transaction_parser_service.dart';
import '../../platform/notifications/bank_notification_listener.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../domain/entities/transaction.dart';

/// Service that orchestrates the complete notification parsing pipeline
class NotificationPipelineService {
  NotificationPipelineService({
    required this.transactionParserService,
    required this.bankNotificationListener,
    required this.createTransactionUseCase,
  });

  final TransactionParserService transactionParserService;
  final BankNotificationListener bankNotificationListener;
  final CreateTransactionUseCase createTransactionUseCase;

  bool _isInitialized = false;
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  /// Stream for pipeline status updates
  Stream<String> get statusStream => _statusController.stream;

  /// Initialize the complete pipeline
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _statusController.add('Initializing notification pipeline...');

      // Initialize the bank notification listener
      await bankNotificationListener.initialize();

      _isInitialized = true;
      _statusController.add('Notification pipeline initialized successfully');
    } catch (e) {
      _statusController.add('Failed to initialize pipeline: $e');
      // Re-throw to allow caller to handle the error
      rethrow;
    }
  }

  /// Process a notification text manually (for testing or manual entry)
  Future<bool> processNotificationText({
    required String packageName,
    required String text,
    bool forceProcess = false,
  }) async {
    try {
      _statusController.add('Processing notification from $packageName...');

      // Parse the transaction
      final parsedResult = transactionParserService.parseNotification(text);

      // Check if we have minimum viable data
      if (parsedResult.amountMinor == null ||
          parsedResult.transactionType == null) {
        _statusController.add(
          'Insufficient data parsed: amount or type missing',
        );
        return false;
      }

      // Create transaction entity
      final transaction = await _createTransactionFromParsedResult(
        parsedResult,
      );
      if (transaction == null) {
        _statusController.add('Failed to create transaction from parsed data');
        return false;
      }

      // Add transaction via use case
      final result = await createTransactionUseCase(transaction);

      if (result.isSuccess) {
        _statusController.add(
          'Transaction created successfully (confidence: ${parsedResult.confidenceScore}%)',
        );
        return true;
      } else {
        _statusController.add('Failed to create transaction: ${result.failureData}');
        return false;
      }
    } catch (e) {
      _statusController.add('Error processing notification: $e');
      return false;
    }
  }

  /// Create Transaction entity from parsed result
  Future<Transaction?> _createTransactionFromParsedResult(
    ParsedTransactionResult parsedResult,
  ) async {
    try {
      final now = DateTime.now();

      return Transaction(
        id: 0, // Will be set by database
        profileId: 1, // Using default profile for MVP
        accountId: 1, // Using default account for MVP
        categoryId: 1, // Using default category for MVP
        merchantId: 1, // Using default merchant for MVP
        amountMinor: parsedResult.amountMinor!,
        type: parsedResult.transactionType!,
        description: parsedResult.merchantString ?? 'Bank Transaction',
        timestamp: parsedResult.timestamp ?? now,
        confidenceScore: parsedResult.confidenceScore,
        requiresReview: parsedResult.requiresReview,
      );
    } catch (e) {
      _statusController.add('Error creating transaction: $e');
      return null;
    }
  }

  /// Get pipeline statistics
  Future<Map<String, dynamic>> getPipelineStats() async {
    return {
      'isInitialized': _isInitialized,
      'hasPermission': await bankNotificationListener.isPermissionGranted(),
      'approvedPackages': [
        'com.gtbank.gtworld',
        'com.zenithbank.mobile',
        'com.opay.client',
        'com.moniepoint.personalapp',
        'com.transsnet.palmpay',
      ],
    };
  }

  /// Request notification listener permission
  Future<bool> requestNotificationPermission() async {
    try {
      _statusController.add('Requesting notification listener permission...');
      final granted = await bankNotificationListener.requestPermission();

      if (granted) {
        _statusController.add('Notification listener permission granted');
      } else {
        _statusController.add('Notification listener permission denied');
      }

      return granted;
    } catch (e) {
      _statusController.add('Error requesting permission: $e');
      return false;
    }
  }

  /// Stop the pipeline and cleanup resources
  Future<void> dispose() async {
    try {
      _statusController.add('Shutting down notification pipeline...');

      await bankNotificationListener.dispose();
      await _statusController.close();

      _isInitialized = false;
      _statusController.add('Pipeline shutdown complete');
    } catch (e) {
      _statusController.add('Error during shutdown: $e');
    }
  }
}

/// Provider for the notification pipeline service
final notificationPipelineServiceProvider = Provider<NotificationPipelineService>((
  ref,
) {
  // Using placeholder implementations for MVP - these should be replaced with proper DI
  final transactionParserService = TransactionParserService();

  // For MVP, using placeholder implementations
  final createTransactionUseCase = CreateTransactionUseCase(
    // Placeholder repository for MVP - will be implemented later
    throw UnimplementedError(
      'Transaction repository provider not implemented - MVP placeholder',
    ),
    // Placeholder merchant repository for MVP - will be implemented later
    throw UnimplementedError(
      'Merchant repository provider not implemented - MVP placeholder',
    ),
  );

  final bankNotificationListener = BankNotificationListener(
    transactionParserService: transactionParserService,
    createTransactionUseCase: createTransactionUseCase,
    localNotifications: FlutterLocalNotificationsPlugin(),
  );

  return NotificationPipelineService(
    transactionParserService: transactionParserService,
    bankNotificationListener: bankNotificationListener,
    createTransactionUseCase: createTransactionUseCase,
  );
});
