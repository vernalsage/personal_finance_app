import '../database/daos/transactions_dao.dart';
import '../mappers/transaction_mapper.dart';
import '../mappers/account_mapper.dart';
import '../mappers/category_mapper.dart';
import '../mappers/merchant_mapper.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/transaction.dart' as domain;

/// Implementation of ITransactionRepository using Drift DAO
class TransactionRepositoryImpl implements ITransactionRepository {
  final TransactionsDao _transactionsDao;

  TransactionRepositoryImpl(this._transactionsDao);

  @override
  Future<Result<domain.Transaction, Exception>> createTransaction(
    domain.Transaction transaction,
  ) async {
    try {
      final companion = transaction.toCompanion();
      final createdTransaction = await _transactionsDao.createTransaction(
        companion,
      );
      return Success(createdTransaction.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to create transaction: $e'));
    }
  }

  @override
  Future<Result<domain.Transaction?, Exception>> getTransactionById(int id) async {
    try {
      final transaction = await _transactionsDao.getTransaction(id);
      return Success(transaction?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get transaction by ID: $e'));
    }
  }

  @override
  Future<Result<List<domain.Transaction>, Exception>> getTransactionsByProfile(
    int profileId,
  ) async {
    try {
      final transactions = await _transactionsDao.getAllTransactions(
        profileId: profileId,
      );
      final domainTransactions = transactions
          .map((transaction) => transaction.toEntity())
          .toList();
      return Success(domainTransactions);
    } catch (e) {
      return Failure(Exception('Failed to get transactions by profile: $e'));
    }
  }

  @override
  Future<Result<List<domain.Transaction>, Exception>> getTransactions({
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
  }) async {
    try {
      final transactions = await _transactionsDao.getTransactionsWithDetails(
        profileId: profileId,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        requiresReview: requiresReview,
      );
      final domainTransactions = transactions
          .map((detail) => detail.transaction.toEntity())
          .toList();
      return Success(domainTransactions);
    } catch (e) {
      return Failure(Exception('Failed to get transactions: $e'));
    }
  }

  @override
  Future<Result<List<domain.Transaction>, Exception>> getTransactionsByAccount(
    int profileId,
    int accountId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final transactions = await _transactionsDao.getAllTransactions(
        profileId: profileId,
        accountId: accountId,
      );
      final domainTransactions = transactions
          .map((transaction) => transaction.toEntity())
          .toList();
      return Success(domainTransactions);
    } catch (e) {
      return Failure(Exception('Failed to get transactions by account: $e'));
    }
  }

  @override
  Future<Result<List<domain.Transaction>, Exception>> getTransactionsRequiringReview(
    int profileId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final transactions = await _transactionsDao
          .getTransactionsRequiringReview(profileId);
      final domainTransactions = transactions
          .map((transaction) => transaction.toEntity())
          .toList();
      return Success(domainTransactions);
    } catch (e) {
      return Failure(Exception('Failed to get transactions requiring review: $e'));
    }
  }

  @override
  Future<Result<List<domain.Transaction>, Exception>> createTransfer({
    required int profileId,
    required int fromAccountId,
    required int toAccountId,
    required int amountMinor,
    required String description,
    required DateTime timestamp,
    String? note,
  }) async {
    try {
      // For now, this is sequential. Phase 2 will make this atomic in the DAO.
      final transferId = timestamp.millisecondsSinceEpoch.toString();

      final outTransaction = domain.Transaction(
        id: 0,
        profileId: profileId,
        accountId: fromAccountId,
        categoryId: 1, // Default/Transfer category
        merchantId: 1, // System merchant
        amountMinor: -amountMinor,
        type: 'transfer_out',
        description: description,
        timestamp: timestamp,
        confidenceScore: 100,
        requiresReview: false,
        transferId: transferId,
        note: note,
      );

      final inTransaction = domain.Transaction(
        id: 0,
        profileId: profileId,
        accountId: toAccountId,
        categoryId: 1,
        merchantId: 1,
        amountMinor: amountMinor,
        type: 'transfer_in',
        description: description,
        timestamp: timestamp,
        confidenceScore: 100,
        requiresReview: false,
        transferId: transferId,
        note: note,
      );

      final results = await _transactionsDao.executeTransfer(
        outEntry: outTransaction.toCompanion(),
        inEntry: inTransaction.toCompanion(),
      );

      return Success(results.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Failure(Exception('Failed to create transfer: $e'));
    }
  }

  @override
  Future<Result<List<domain.Transaction>, Exception>> getTransactionsByTransferId(
    int profileId,
    String transferId,
  ) async {
    try {
      final transactions = await _transactionsDao.getTransactionsByTransferId(
          profileId, transferId);
      return Success(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Failure(Exception('Failed to get transactions by transfer ID: $e'));
    }
  }

  @override
  Future<Result<domain.Transaction, Exception>> updateTransaction(
    domain.Transaction transaction,
  ) async {
    try {
      final companion = transaction.toUpdateCompanion();
      final updatedTransaction = await _transactionsDao.updateTransaction(
        companion,
      );
      if (updatedTransaction == null) {
        return Failure(Exception('Transaction not found for update'));
      }
      return Success(updatedTransaction.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update transaction: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> deleteTransaction(int id) async {
    try {
      await _transactionsDao.deleteTransaction(id);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to delete transaction: $e'));
    }
  }

  @override
  Future<Result<int, Exception>> getTotalAmountByType(
    int profileId,
    String type, {
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final total = await _transactionsDao.getTotalAmountByType(
        profileId,
        type,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );
      return Success(total);
    } catch (e) {
      return Failure(Exception('Failed to get total amount by type: $e'));
    }
  }

  @override
  Future<Result<TransactionStats, Exception>> getTransactionStats(
    int profileId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final income = await _transactionsDao.getTotalAmountByType(
        profileId,
        'credit',
        startDate: startDate,
        endDate: endDate,
      );
      final expense = await _transactionsDao.getTotalAmountByType(
        profileId,
        'debit',
        startDate: startDate,
        endDate: endDate,
      );

      final count = await _transactionsDao.getTransactionCount(
        profileId: profileId,
        startDate: startDate,
        endDate: endDate,
      );

      return Success(TransactionStats(
        totalIncome: income,
        totalExpenses: expense,
        netIncome: income - expense,
        transactionCount: count,
        averageTransactionAmount: count > 0 ? (expense / count) : 0,
      ));
    } catch (e) {
      return Failure(Exception('Failed to get transaction stats: $e'));
    }
  }

  @override
  Future<Result<List<TransactionWithJoinedDetails>, Exception>>
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

      return Success(result);
    } catch (e) {
      return Failure(Exception('Failed to get transactions with details: $e'));
    }
  }
}
