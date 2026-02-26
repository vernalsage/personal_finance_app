import '../entities/transaction.dart';
import '../entities/account.dart';
import '../entities/category.dart';
import '../entities/merchant.dart';
import '../core/result.dart';

/// Abstract repository interface for Transaction operations
abstract class ITransactionRepository {
  /// Create a new transaction
  Future<Result<Transaction, Exception>> createTransaction(Transaction transaction);

  /// Get a transaction by ID
  Future<Result<Transaction?, Exception>> getTransactionById(int id);

  /// Get all transactions for a profile
  Future<Result<List<Transaction>, Exception>> getTransactionsByProfile(int profileId);

  /// Get transactions for a profile with optional filters
  Future<Result<List<Transaction>, Exception>> getTransactions({
    required int profileId,
    int? accountId,
    int? categoryId,
    int? merchantId,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    bool? requiresReview,
    int? limit,
    int? offset,
  });

  /// Get transactions for a specific account
  Future<Result<List<Transaction>, Exception>> getTransactionsByAccount(
    int profileId,
    int accountId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  /// Get transactions requiring review
  Future<Result<List<Transaction>, Exception>> getTransactionsRequiringReview(
    int profileId, {
    int? limit,
    int? offset,
  });

  /// Create a transfer (atomic operation creating two linked transactions)
  Future<Result<List<Transaction>, Exception>> createTransfer({
    required int profileId,
    required int fromAccountId,
    required int toAccountId,
    required int amountMinor,
    required String description,
    required DateTime timestamp,
    String? note,
  });

  /// Get transactions by transfer ID
  Future<Result<List<Transaction>, Exception>> getTransactionsByTransferId(
    int profileId,
    String transferId,
  );

  /// Update an existing transaction
  Future<Result<Transaction, Exception>> updateTransaction(Transaction transaction);

  /// Delete a transaction by ID
  Future<Result<void, Exception>> deleteTransaction(int id);

  /// Get total amount by transaction type
  Future<Result<int, Exception>> getTotalAmountByType(
    int profileId,
    String type, {
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get transaction statistics for a profile
  Future<Result<TransactionStats, Exception>> getTransactionStats(
    int profileId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get transactions with joined details (account, category, merchant)
  Future<Result<List<TransactionWithJoinedDetails>, Exception>>
  getTransactionsWithDetails({
    int? profileId,
    int? accountId,
    int? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? requiresReview,
  });
}

/// Transaction with joined details from related tables
class TransactionWithJoinedDetails {
  const TransactionWithJoinedDetails({
    required this.transaction,
    required this.account,
    this.category,
    this.merchant,
  });

  final Transaction transaction;
  final Account account;
  final Category? category;
  final Merchant? merchant;
}

/// Transaction statistics for reports
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
