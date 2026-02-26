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
  Future<Transaction> createTransaction(TransactionsCompanion entry) {
    return transaction(() async {
      final created = await into(transactions).insertReturning(entry);

      // Update account balance
      if (entry.accountId.present && entry.amountMinor.present && entry.type.present) {
        final amount = entry.amountMinor.value;
        final type = entry.type.value;

        // Sign logic: debit/transfer_out are negative hits to balance,
        // credit/transfer_in are positive hits to balance.
        // NOTE: Screen usually provides absolute values for manual entry,
        // but we should be robust.
        int sign = 1;
        if (type == 'debit' || type == 'transfer_out') {
          sign = -1;
        }

        // We use absolute value from entry and apply sign to be safe, 
        // OR we trust the entry amount. Let's trust entry amount for now 
        // but ensure we don't double-negative.
        final effectiveChange = amount.abs() * sign;

        await _updateAccountBalance(entry.accountId.value, effectiveChange);
      }

      return created;
    });
  }

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

  Future<int> deleteTransaction(int id) {
    return transaction(() async {
      final transactionToDelete = await getTransaction(id);
      if (transactionToDelete == null) return 0;

      // Revert balance change
      int sign = 1;
      if (transactionToDelete.type == 'debit' || transactionToDelete.type == 'transfer_out') {
        sign = -1; // Original was negative
      }
      
      // To revert a negative change, we ADD the absolute amount.
      // To revert a positive change, we SUBTRACT the absolute amount.
      final revertChange = -(transactionToDelete.amountMinor.abs() * sign);

      await _updateAccountBalance(transactionToDelete.accountId, revertChange);

      return (delete(transactions)..where((t) => t.id.equals(id))).go();
    });
  }

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
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Use Drift's type-safe query builder instead of raw SQL
    var query = selectOnly(transactions);
    query.addColumns([transactions.amountMinor.sum()]);
    
    var predicate = transactions.profileId.equals(profileId) & 
                    transactions.type.equals(type);
    
    if (categoryId != null) {
      predicate &= transactions.categoryId.equals(categoryId);
    }
    
    query.where(predicate);

    if (startDate != null) {
      query.where(transactions.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.timestamp.isSmallerOrEqualValue(endDate));
    }

    final result = await query.getSingle();
    return result.read(transactions.amountMinor.sum()) ?? 0;
  }

  Future<List<Transaction>> getTransactionsByTransferId(
    int profileId,
    String transferId,
  ) {
    return (select(transactions)..where(
          (t) => t.profileId.equals(profileId) & t.transferId.equals(transferId),
        ))
        .get();
  }

  Future<int> getTransactionCount({
    required int profileId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = selectOnly(transactions);
    query.addColumns([transactions.id.count()]);
    query.where(transactions.profileId.equals(profileId));

    if (startDate != null) {
      query.where(transactions.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.timestamp.isSmallerOrEqualValue(endDate));
    }

    final result = await query.getSingle();
    return result.read(transactions.id.count()) ?? 0;
  }

  /// Atomic transfer: creates two linked transactions
  Future<List<Transaction>> executeTransfer({
    required TransactionsCompanion outEntry,
    required TransactionsCompanion inEntry,
  }) async {
    return transaction(() async {
      final outResult = await into(transactions).insertReturning(outEntry);
      final inResult = await into(transactions).insertReturning(inEntry);
      
      // Update account balances
      if (outEntry.accountId.present && outEntry.amountMinor.present) {
        await _updateAccountBalance(
          outEntry.accountId.value,
          -outEntry.amountMinor.value.abs(), // Always subtract for transfer_out
        );
      }
      if (inEntry.accountId.present && inEntry.amountMinor.present) {
        await _updateAccountBalance(
          inEntry.accountId.value,
          inEntry.amountMinor.value.abs(), // Always add for transfer_in
        );
      }
      
      return [outResult, inResult];
    });
  }

  Future<void> _updateAccountBalance(int accountId, int amountChange) async {
    await customStatement(
      'UPDATE accounts SET balance_minor = balance_minor + ? WHERE id = ?',
      [amountChange, accountId],
    );
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
