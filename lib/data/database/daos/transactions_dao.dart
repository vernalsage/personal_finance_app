import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/transactions_table.dart';
import '../tables/accounts_table.dart';
import '../tables/categories_table.dart';
import '../tables/merchants_table.dart';

part 'transactions_dao.g.dart';

/// DAO for Transactions table
@DriftAccessor(tables: [Transactions, Accounts, Categories, Merchants])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  // CRUD Operations
  Future<Transaction> createTransaction(TransactionsCompanion entry) =>
      into(transactions).insertReturning(entry);

  Future<Transaction?> getTransaction(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Transaction>> getAllTransactions({
    int? profileId,
    int? accountId,
  }) {
    final query = select(transactions);
    if (profileId != null) {
      query.where((t) => t.profileId.equals(profileId));
    }
    if (accountId != null) {
      query.where((t) => t.accountId.equals(accountId));
    }
    return query.get();
  }

  Future<Transaction?> updateTransaction(TransactionsCompanion entry) async {
    final updated = await update(transactions).writeReturning(entry);
    return updated.isNotEmpty ? updated.first : null;
  }

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  // Custom Queries
  Future<List<TransactionWithDetails>> getTransactionsWithDetails({
    int? profileId,
    int? accountId,
    int? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? requiresReview,
  }) {
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      leftOuterJoin(merchants, merchants.id.equalsExp(transactions.merchantId)),
    ]);

    if (profileId != null) {
      query.where(transactions.profileId.equals(profileId));
    }
    if (accountId != null) {
      query.where(transactions.accountId.equals(accountId));
    }
    if (categoryId != null) {
      query.where(transactions.categoryId.equals(categoryId));
    }
    if (type != null) {
      query.where(transactions.type.equals(type));
    }
    if (startDate != null) {
      query.where(transactions.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.timestamp.isSmallerOrEqualValue(endDate));
    }
    if (requiresReview != null) {
      query.where(transactions.requiresReview.equals(requiresReview));
    }

    return query.map((row) {
      return TransactionWithDetails(
        transaction: row.readTable(transactions),
        account: row.readTable(accounts),
        category: row.readTableOrNull(categories),
        merchant: row.readTableOrNull(merchants),
      );
    }).get();
  }

  Future<List<Transaction>> getTransactionsRequiringReview(int profileId) {
    return (select(transactions)..where(
          (t) => t.profileId.equals(profileId) & t.requiresReview.equals(true),
        ))
        .get();
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    int profileId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(transactions)..where(
          (t) =>
              t.profileId.equals(profileId) &
              t.timestamp.isBetweenValues(startDate, endDate),
        ))
        .get();
  }

  Future<List<Transaction>> getTransfers(int profileId) {
    return (select(transactions)..where(
          (t) =>
              t.profileId.equals(profileId) &
              (t.type.equals('transfer_out') | t.type.equals('transfer_in')),
        ))
        .get();
  }

  Future<int> getTotalAmountByType(
    int profileId,
    String type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Use Drift's type-safe query builder instead of raw SQL
    var query = selectOnly(transactions);
    query.addColumns([transactions.amountMinor.sum()]);
    query.where(
      transactions.profileId.equals(profileId) & transactions.type.equals(type),
    );

    if (startDate != null) {
      query.where(transactions.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.timestamp.isSmallerOrEqualValue(endDate));
    }

    final result = await query.getSingle();
    return result.read(transactions.amountMinor.sum()) ?? 0;
  }
}

/// Transaction with joined details
class TransactionWithDetails {
  TransactionWithDetails({
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
