import '../entities/account.dart';
import '../../data/models/account_model.dart';
import '../repositories/transaction_repository.dart';

/// Repository interface for account operations
abstract class AccountRepository {
  /// Create a new account
  Future<Result<Account>> createAccount(Account account);

  /// Update an existing account
  Future<Result<Account>> updateAccount(Account account);

  /// Delete an account
  Future<Result<void>> deleteAccount(int accountId);

  /// Get account by ID
  Future<Result<Account?>> getAccountById(int accountId);

  /// Get accounts for a profile
  Future<Result<List<Account>>> getAccounts(
    int profileId, {
    bool? isActive,
    AccountType? type,
  });

  /// Update account balance
  Future<Result<Account>> updateAccountBalance(
    int accountId,
    int newBalanceMinor,
  );

  /// Get account balance
  Future<Result<int>> getAccountBalance(int accountId);

  /// Get total balance across all accounts for a profile
  Future<Result<int>> getTotalBalance(
    int profileId, {
    bool? isActive,
    AccountType? type,
  });
}
