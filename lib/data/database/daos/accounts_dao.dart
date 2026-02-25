import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../app_database_simple.dart';
import '../tables/accounts_table.dart';
import '../../../application/services/hybrid_currency_service.dart';

part 'accounts_dao.g.dart';

/// DAO for Accounts table
@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  // CRUD Operations
  Future<Account> createAccount(AccountsCompanion entry) =>
      into(accounts).insertReturning(entry);

  Future<Account> getAccount(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingle();

  Future<List<Account>> getAllAccounts({
    int? profileId,
    bool? isActive,
    String? type,
  }) {
    final query = select(accounts);
    if (profileId != null) query.where((a) => a.profileId.equals(profileId));
    if (isActive != null) query.where((a) => a.isActive.equals(isActive));
    if (type != null) query.where((a) => a.type.equals(type));
    return query.get();
  }

  Future<Account> updateAccount(AccountsCompanion entry) =>
      (update(accounts)..where((a) => a.id.equals(entry.id.value)))
          .writeReturning(entry)
          .then((accounts) => accounts.first);

  Future<int> deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();

  // Custom Queries
  Future<Account> updateAccountBalance(int accountId, int newBalanceMinor) {
    return (update(accounts)..where((a) => a.id.equals(accountId)))
        .writeReturning(AccountsCompanion(balanceMinor: Value(newBalanceMinor)))
        .then((accounts) => accounts.first);
  }

  Future<int> getAccountBalance(int accountId) {
    return (selectOnly(accounts)
          ..addColumns([accounts.balanceMinor])
          ..where(accounts.id.equals(accountId)))
        .get()
        .then((result) => result.firstOrNull?.read(accounts.balanceMinor) ?? 0);
  }

  Future<int> getTotalBalance(
    int profileId, {
    bool? isActive,
    String? excludeType,
  }) {
    // 1. Define the aggregate measure as a variable
    final balanceSum = accounts.balanceMinor.sum();

    // 2. Notice the double-dot cascade operator (..) here
    var query = selectOnly(accounts)..addColumns([balanceSum]);

    query.where(accounts.profileId.equals(profileId));

    if (isActive != null) {
      query.where(accounts.isActive.equals(isActive));
    }

    if (excludeType != null) {
      query.where(accounts.type.equals(excludeType).not());
    }

    return query.get().then(
      (result) => result.firstOrNull?.read(balanceSum) ?? 0,
    );
  }

  Future<List<Account>> getAccountsByType(int profileId, String type) {
    return (select(
      accounts,
    )..where((a) => a.profileId.equals(profileId) & a.type.equals(type))).get();
  }

  Future<void> deactivateAccount(int accountId) {
    return (update(accounts)..where((a) => a.id.equals(accountId))).write(
      const AccountsCompanion(isActive: Value(false)),
    );
  }

  Future<void> activateAccount(int accountId) {
    return (update(accounts)..where((a) => a.id.equals(accountId))).write(
      const AccountsCompanion(isActive: Value(true)),
    );
  }

  // Individual field update methods
  Future<void> updateAccountName(int accountId, String name) {
    return (update(accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(name: Value(name)),
    );
  }

  Future<void> updateAccountType(int accountId, String type) {
    return (update(accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(type: Value(type)),
    );
  }

  Future<void> updateAccountCurrency(int accountId, String currency) {
    return (update(accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(currency: Value(currency)),
    );
  }

  Future<void> updateAccountDescription(int accountId, String? description) {
    return (update(accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(description: Value(description)),
    );
  }

  // Get accounts grouped by currency for conversion
  Future<Map<String, List<Account>>> getAccountsByCurrency(
    int profileId,
  ) async {
    final allAccounts = await getAllAccounts(
      profileId: profileId,
      isActive: true,
    );
    final grouped = <String, List<Account>>{};

    for (final account in allAccounts) {
      final currency = account.currency;
      if (!grouped.containsKey(currency)) {
        grouped[currency] = [];
      }
      grouped[currency]!.add(account);
    }

    return grouped;
  }

  // Get total balance converted to target currency
  Future<double> getTotalBalanceInCurrency(
    int profileId,
    String targetCurrency, {
    bool? isActive,
  }) async {
    try {
      // Get accounts grouped by currency
      final accountsByCurrency = await getAccountsByCurrency(profileId);

      // Calculate total for each currency
      final totalsByCurrency = <String, double>{};
      for (final entry in accountsByCurrency.entries) {
        final currency = entry.key;
        final accounts = entry.value;

        final total = accounts.fold<int>(
          0,
          (sum, account) => sum + account.balanceMinor,
        );
        totalsByCurrency[currency] = total / 100.0; // Convert from minor units
      }

      // Convert all totals to target currency
      if (totalsByCurrency.isEmpty) {
        return 0.0;
      }

      // If all accounts are already in target currency, return sum
      if (totalsByCurrency.length == 1 &&
          totalsByCurrency.keys.first == targetCurrency) {
        return totalsByCurrency.values.first;
      }

      // Convert each currency total to target currency
      double convertedTotal = 0.0;
      for (final entry in totalsByCurrency.entries) {
        final fromCurrency = entry.key;
        final amount = entry.value;

        if (fromCurrency == targetCurrency) {
          convertedTotal += amount;
        } else {
          final convertedAmount = await HybridCurrencyService.convertCurrency(
            amount: amount,
            fromCurrency: fromCurrency,
            toCurrency: targetCurrency,
          );
          convertedTotal += convertedAmount;
        }
      }

      return convertedTotal;
    } catch (e) {
      // Don't fall back to simple sum as it gives incorrect multi-currency totals
      debugPrint('Error in currency conversion: $e');
      return 0.0;
    }
  }
}
