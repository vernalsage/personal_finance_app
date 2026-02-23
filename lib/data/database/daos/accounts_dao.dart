import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/accounts_table.dart';

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
      update(accounts).writeReturning(entry).then((accounts) => accounts.first);

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
}
