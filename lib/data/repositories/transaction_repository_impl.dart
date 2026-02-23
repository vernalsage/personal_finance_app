import '../database/daos/transactions_dao.dart';
import '../mappers/transaction_mapper.dart';
import '../mappers/account_mapper.dart';
import '../mappers/category_mapper.dart';
import '../mappers/merchant_mapper.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/transaction.dart' as domain;

/// Implementation of ITransactionRepository using Drift DAO
class TransactionRepositoryImpl implements ITransactionRepository {
  final TransactionsDao _transactionsDao;

  TransactionRepositoryImpl(this._transactionsDao);

  @override
  Future<Result<domain.Transaction>> createTransaction(
    domain.Transaction transaction,
  ) async {
    try {
      final companion = transaction.toCompanion();
      final createdTransaction = await _transactionsDao.createTransaction(
        companion,
      );
      return Result.success(createdTransaction.toEntity());
    } catch (e) {
      return Result.failure('Failed to create transaction: $e');
    }
  }

  @override
  Future<Result<domain.Transaction?>> getTransactionById(int id) async {
    try {
      final transaction = await _transactionsDao.getTransaction(id);
      return Result.success(transaction?.toEntity());
    } catch (e) {
      return Result.failure('Failed to get transaction by ID: $e');
    }
  }

  @override
  Future<Result<List<domain.Transaction>>> getTransactionsByProfile(
    int profileId,
  ) async {
    try {
      final transactions = await _transactionsDao.getAllTransactions(
        profileId: profileId,
      );
      final domainTransactions = transactions
          .map((transaction) => transaction.toEntity())
          .toList();
      return Result.success(domainTransactions);
    } catch (e) {
      return Result.failure('Failed to get transactions by profile: $e');
    }
  }

  @override
  Future<Result<List<domain.Transaction>>> getTransactionsByAccount(
    int accountId,
  ) async {
    try {
      final transactions = await _transactionsDao.getAllTransactions(
        accountId: accountId,
      );
      final domainTransactions = transactions
          .map((transaction) => transaction.toEntity())
          .toList();
      return Result.success(domainTransactions);
    } catch (e) {
      return Result.failure('Failed to get transactions by account: $e');
    }
  }

  @override
  Future<Result<List<domain.Transaction>>> getTransactionsByDateRange(
    int profileId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final transactions = await _transactionsDao.getTransactionsByDateRange(
        profileId,
        startDate,
        endDate,
      );
      final domainTransactions = transactions
          .map((transaction) => transaction.toEntity())
          .toList();
      return Result.success(domainTransactions);
    } catch (e) {
      return Result.failure('Failed to get transactions by date range: $e');
    }
  }

  @override
  Future<Result<List<domain.Transaction>>> getTransactionsRequiringReview(
    int profileId,
  ) async {
    try {
      final transactions = await _transactionsDao
          .getTransactionsRequiringReview(profileId);
      final domainTransactions = transactions
          .map((transaction) => transaction.toEntity())
          .toList();
      return Result.success(domainTransactions);
    } catch (e) {
      return Result.failure('Failed to get transactions requiring review: $e');
    }
  }

  @override
  Future<Result<List<domain.Transaction>>> getTransfers(int profileId) async {
    try {
      final transactions = await _transactionsDao.getTransfers(profileId);
      final domainTransactions = transactions
          .map((transaction) => transaction.toEntity())
          .toList();
      return Result.success(domainTransactions);
    } catch (e) {
      return Result.failure('Failed to get transfers: $e');
    }
  }

  @override
  Future<Result<domain.Transaction>> updateTransaction(
    domain.Transaction transaction,
  ) async {
    try {
      final companion = transaction.toUpdateCompanion();
      final updatedTransaction = await _transactionsDao.updateTransaction(
        companion,
      );
      if (updatedTransaction == null) {
        return Result.failure('Transaction not found for update');
      }
      return Result.success(updatedTransaction.toEntity());
    } catch (e) {
      return Result.failure('Failed to update transaction: $e');
    }
  }

  @override
  Future<Result<void>> deleteTransaction(int id) async {
    try {
      await _transactionsDao.deleteTransaction(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to delete transaction: $e');
    }
  }

  @override
  Future<Result<int>> getTotalAmountByType(
    int profileId,
    String type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final total = await _transactionsDao.getTotalAmountByType(
        profileId,
        type,
        startDate: startDate,
        endDate: endDate,
      );
      return Result.success(total);
    } catch (e) {
      return Result.failure('Failed to get total amount by type: $e');
    }
  }

  @override
  Future<Result<List<TransactionWithJoinedDetails>>>
  getTransactionsWithDetails({
    int? profileId,
    int? accountId,
    int? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? requiresReview,
  }) async {
    try {
      final transactionsWithDetails = await _transactionsDao
          .getTransactionsWithDetails(
            profileId: profileId,
            accountId: accountId,
            categoryId: categoryId,
            type: type,
            startDate: startDate,
            endDate: endDate,
            requiresReview: requiresReview,
          );

      final result = transactionsWithDetails.map((detail) {
        return TransactionWithJoinedDetails(
          transaction: detail.transaction.toEntity(),
          account: detail.account.toEntity(),
          category: detail.category?.toEntity(),
          merchant: detail.merchant?.toEntity(),
        );
      }).toList();

      return Result.success(result);
    } catch (e) {
      return Result.failure('Failed to get transactions with details: $e');
    }
  }
}
