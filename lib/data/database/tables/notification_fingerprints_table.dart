import 'package:drift/drift.dart';

/// Table to store fingerprints of processed notifications to prevent duplicates
class NotificationFingerprints extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  /// The unique fingerprint of the notification (usually a hash of text + timestamp)
  TextColumn get fingerprint => text().unique()();
  
  /// When this notification was processed
  DateTimeColumn get processedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Reference to the transaction created (if any)
  IntColumn get transactionId => integer().nullable()();
}
