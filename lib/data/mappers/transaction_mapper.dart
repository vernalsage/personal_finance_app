import 'package:drift/drift.dart';
import '../database/app_database_simple.dart';
import '../../domain/entities/transaction.dart' as domain;

/// Extension methods to map between Drift Transaction and Domain Transaction
extension TransactionMapper on Transaction {
  /// Convert Drift Transaction to Domain Transaction
  domain.Transaction toEntity() {
    return domain.Transaction(
      id: id,
      profileId: profileId,
      accountId: accountId,
      categoryId: categoryId,
      merchantId: merchantId,
      amountMinor: amountMinor,
      type: type,
      description: description,
      timestamp: timestamp,
      confidenceScore: confidenceScore,
      requiresReview: requiresReview,
      transferId: transferId,
      note: note,
    );
  }
}

/// Extension methods to map from Domain Transaction to Drift objects
extension DomainTransactionMapper on domain.Transaction {
  /// Convert Domain Transaction to Drift TransactionsCompanion for inserts
  TransactionsCompanion toCompanion() {
    return TransactionsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      profileId: Value(profileId),
      accountId: Value(accountId),
      categoryId: Value.absentIfNull(categoryId),
      merchantId: Value.absentIfNull(merchantId),
      amountMinor: Value(amountMinor),
      type: Value(type),
      description: Value(description),
      timestamp: Value(timestamp),
      confidenceScore: Value(confidenceScore),
      requiresReview: Value(requiresReview),
      transferId: transferId != null
          ? Value(transferId!)
          : const Value.absent(),
      note: note != null ? Value(note!) : const Value.absent(),
    );
  }

  /// Convert Domain Transaction to Drift TransactionsCompanion for updates
  TransactionsCompanion toUpdateCompanion() {
    return TransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      categoryId: Value.absentIfNull(categoryId),
      merchantId: Value.absentIfNull(merchantId),
      amountMinor: Value(amountMinor),
      type: Value(type),
      description: Value(description),
      timestamp: Value(timestamp),
      confidenceScore: Value(confidenceScore),
      requiresReview: Value(requiresReview),
      transferId: transferId != null
          ? Value(transferId!)
          : const Value.absent(),
      note: note != null ? Value(note!) : const Value.absent(),
    );
  }
}
