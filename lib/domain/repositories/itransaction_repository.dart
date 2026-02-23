import '../entities/transaction.dart';
import '../entities/account.dart';
import '../entities/category.dart';
import '../entities/merchant.dart';
import '../repositories/transaction_repository.dart';

/// Abstract repository interface for Transaction operations
abstract class ITransactionRepository {
  /// Create a new transaction
  Future<Result<Transaction>> createTransaction(Transaction transaction);

  /// Get a transaction by ID
  Future<Result<Transaction?>> getTransactionById(int id);

  /// Get all transactions for a profile
  Future<Result<List<Transaction>>> getTransactionsByProfile(int profileId);

  /// Get transactions for a specific account
  Future<Result<List<Transaction>>> getTransactionsByAccount(int accountId);

  /// Get transactions by date range
  Future<Result<List<Transaction>>> getTransactionsByDateRange(
    int profileId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get transactions requiring review
  Future<Result<List<Transaction>>> getTransactionsRequiringReview(
    int profileId,
  );

  /// Get transfers for a profile
  Future<Result<List<Transaction>>> getTransfers(int profileId);

  /// Update an existing transaction
  Future<Result<Transaction>> updateTransaction(Transaction transaction);

  /// Delete a transaction by ID
  Future<Result<void>> deleteTransaction(int id);

  /// Get total amount by transaction type
  Future<Result<int>> getTotalAmountByType(
    int profileId,
    String type, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get transactions with joined details (account, category, merchant)
  Future<Result<List<TransactionWithJoinedDetails>>>
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
