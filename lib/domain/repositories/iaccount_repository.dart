import '../entities/account.dart';
import '../core/result.dart';

/// Abstract repository interface for Account operations
abstract class IAccountRepository {
  /// Create a new account
  Future<Result<Account, Exception>> createAccount(Account account);

  /// Get an account by ID
  Future<Result<Account?, Exception>> getAccountById(int id);

  /// Get all accounts for a profile
  Future<Result<List<Account>, Exception>> getAccountsByProfile(int profileId);

  /// Get active accounts for a profile
  Future<Result<List<Account>, Exception>> getActiveAccountsByProfile(int profileId);

  /// Update an existing account
  Future<Result<Account, Exception>> updateAccount(Account account);

  /// Delete an account by ID
  Future<Result<void, Exception>> deleteAccount(int id);

  /// Get account balance
  Future<Result<int, Exception>> getAccountBalance(int accountId);

  /// Update account balance
  Future<Result<void, Exception>> updateAccountBalance(int accountId, int newBalanceMinor);
}
