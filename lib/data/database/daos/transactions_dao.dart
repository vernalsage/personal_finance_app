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
      // Sign logic: debit/transfer_out are negative hits to balance,
      // credit/transfer_in are positive hits to balance.
      int sign = 1;
      if (entry.type.present) {
        final type = entry.type.value;
        if (type == 'debit' || type == 'transfer_out') {
          sign = -1;
        }
      }

      // Ensure amountMinor is saved with the correct sign in the transactions table
      final signedAmount = (entry.amountMinor.value.abs() * sign);
      final entryWithSign = entry.copyWith(
        amountMinor: Value(signedAmount),
      );

      final created = await into(transactions).insertReturning(entryWithSign);

      // Update account balance using the same signed amount
      if (entry.accountId.present) {
        await _updateAccountBalance(entry.accountId.value, signedAmount);
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
    query.orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return query.get();
  }

  Future<Transaction?> updateTransaction(TransactionsCompanion entry) async {
    return transaction(() async {
      final oldTx = await getTransaction(entry.id.value);
      if (oldTx == null) return null;

      // 1. Revert old balance
      await _updateAccountBalance(oldTx.accountId, -oldTx.amountMinor);

      // 2. Prepare new entry with correct sign
      // Determine sign based on entry type or old type
      int sign = 1;
      final type = entry.type.present ? entry.type.value : oldTx.type;
      if (type == 'debit' || type == 'transfer_out') {
        sign = -1;
      }

      int newSignedAmount;
      if (entry.amountMinor.present) {
        newSignedAmount = entry.amountMinor.value.abs() * sign;
      } else {
        newSignedAmount = oldTx.amountMinor.abs() * sign;
      }

      final entryWithSign = entry.copyWith(
        amountMinor: Value(newSignedAmount),
      );

      // 3. Update transaction record
      final updatedResult = await (update(transactions)
            ..where((t) => t.id.equals(entry.id.value)))
          .writeReturning(entryWithSign);
      
      if (updatedResult.isEmpty) return null;
      final newTx = updatedResult.first;

      // 4. Apply new balance to the (potentially new) account
      await _updateAccountBalance(newTx.accountId, newTx.amountMinor);

      // 5. Sync linked transfer if applicable
      if (newTx.transferId != null) {
        await _syncLinkedTransfer(newTx, entry);
      }

      return newTx;
    });
  }

  Future<void> _syncLinkedTransfer(Transaction tx, TransactionsCompanion entry) async {
    // Find the sibling transaction
    final sibling = await (select(transactions)
          ..where((t) => t.transferId.equals(tx.transferId!) & t.id.equals(tx.id).not()))
        .getSingleOrNull();

    if (sibling == null) return;

    // Check currencies to decide if we should sync the amount
    final txAccount = await (select(accounts)..where((a) => a.id.equals(tx.accountId))).getSingle();
    final siblingAccount = await (select(accounts)..where((a) => a.id.equals(sibling.accountId))).getSingle();
    final currenciesMatch = txAccount.currency == siblingAccount.currency;

    // Shared fields to sync
    var siblingUpdate = TransactionsCompanion(
      timestamp: entry.timestamp.present ? entry.timestamp : Value(tx.timestamp),
      description: entry.description.present ? entry.description : Value(tx.description),
      note: entry.note.present ? entry.note : Value(tx.note),
      categoryId: entry.categoryId.present ? entry.categoryId : Value(tx.categoryId),
      merchantId: entry.merchantId.present ? entry.merchantId : Value(tx.merchantId),
    );

    // Only sync amount if currencies match to avoid corrupting conversion rates
    if (currenciesMatch && entry.amountMinor.present) {
      siblingUpdate = siblingUpdate.copyWith(amountMinor: Value(-tx.amountMinor));
    }

    // Revert sibling old balance
    await _updateAccountBalance(sibling.accountId, -sibling.amountMinor);
    
    // Update sibling record
    await (update(transactions)..where((t) => t.id.equals(sibling.id))).write(siblingUpdate);

    // Apply sibling new balance
    final updatedSibling = await getTransaction(sibling.id);
    if (updatedSibling != null) {
      await _updateAccountBalance(updatedSibling.accountId, updatedSibling.amountMinor);
    }
  }

  Future<int> deleteTransaction(int id) {
    return transaction(() async {
      final tx = await getTransaction(id);
      if (tx == null) return 0;

      // 1. Revert balance change
      await _updateAccountBalance(tx.accountId, -tx.amountMinor);

      // 2. Handle linked transfer
      if (tx.transferId != null) {
        final sibling = await (select(transactions)
              ..where((t) => t.transferId.equals(tx.transferId!) & t.id.equals(id).not()))
            .getSingleOrNull();
        
        if (sibling != null) {
          // Revert sibling balance
          await _updateAccountBalance(sibling.accountId, -sibling.amountMinor);
          // Delete sibling
          await (delete(transactions)..where((t) => t.id.equals(sibling.id))).go();
        }
      }

      // 3. Delete primary transaction
      return (delete(transactions)..where((t) => t.id.equals(id))).go();
    });
  }

  // Custom Queries
  Future<List<TransactionWithJoinedData>> getTransactionsWithDetails({
    int? profileId,
    int? accountId,
    int? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? requiresReview,
  }) {
    final query = select(transactions).join([
      leftOuterJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
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

    query.orderBy([OrderingTerm.desc(transactions.timestamp)]);

    return query.map((row) {
      return TransactionWithJoinedData(
        transaction: row.readTable(transactions),
        account: row.readTableOrNull(accounts),
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
      // Ensure amounts are correctly signed in the transactions table
      final signedOutAmount = -outEntry.amountMinor.value.abs();
      final signedInAmount = inEntry.amountMinor.value.abs();

      final outEntryWithSign = outEntry.copyWith(
        amountMinor: Value(signedOutAmount),
      );
      final inEntryWithSign = inEntry.copyWith(
        amountMinor: Value(signedInAmount),
      );

      final outResult = await into(transactions).insertReturning(outEntryWithSign);
      final inResult = await into(transactions).insertReturning(inEntryWithSign);
      
      // Update account balances
      if (outEntry.accountId.present) {
        await _updateAccountBalance(
          outEntry.accountId.value,
          signedOutAmount,
        );
      }
      if (inEntry.accountId.present) {
        await _updateAccountBalance(
          inEntry.accountId.value,
          signedInAmount,
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

/// Transaction with joined data from Drift
class TransactionWithJoinedData {
  TransactionWithJoinedData({
    required this.transaction,
    this.account,
    this.category,
    this.merchant,
  });

  final Transaction transaction;
  final Account? account;
  final Category? category;
  final Merchant? merchant;
}
