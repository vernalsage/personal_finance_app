import '../entities/transaction.dart';
import '../../data/models/transaction_model.dart';

/// Result wrapper for repository operations
class Result<T> {
  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  final T? data;
  final String? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

/// Repository interface for transaction operations
abstract class TransactionRepository {
  /// Create a new transaction
  Future<Result<Transaction>> createTransaction(Transaction transaction);

  /// Update an existing transaction
  Future<Result<Transaction>> updateTransaction(Transaction transaction);

  /// Delete a transaction
  Future<Result<void>> deleteTransaction(int transactionId);

  /// Get transaction by ID
  Future<Result<Transaction?>> getTransactionById(int transactionId);

  /// Get transactions for a profile with optional filters
  Future<Result<List<Transaction>>> getTransactions({
    required int profileId,
    int? accountId,
    int? categoryId,
    int? merchantId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    bool? requiresReview,
    int? limit,
    int? offset,
  });

  /// Get transactions for a specific account
  Future<Result<List<Transaction>>> getTransactionsByAccount(
    int profileId,
    int accountId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  /// Get transactions for a specific category
  Future<Result<List<Transaction>>> getTransactionsByCategory(
    int profileId,
    int categoryId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  /// Get transactions requiring review
  Future<Result<List<Transaction>>> getTransactionsRequiringReview(
    int profileId, {
    int? limit,
    int? offset,
  });

  /// Create a transfer (two linked transactions)
  Future<Result<List<Transaction>>> createTransfer({
    required int profileId,
    required int fromAccountId,
    required int toAccountId,
    required int amountMinor,
    required String description,
    required DateTime timestamp,
    String? note,
  });

  /// Get transactions by transfer ID
  Future<Result<List<Transaction>>> getTransactionsByTransferId(
    int profileId,
    String transferId,
  );

  /// Get transaction statistics for a profile
  Future<Result<TransactionStats>> getTransactionStats(
    int profileId, {
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Transaction statistics
class TransactionStats {
  const TransactionStats({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.transactionCount,
    required this.averageTransactionAmount,
  });

  final int totalIncome;
  final int totalExpenses;
  final int netIncome;
  final int transactionCount;
  final double averageTransactionAmount;
}
