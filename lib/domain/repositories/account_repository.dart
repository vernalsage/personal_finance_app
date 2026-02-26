import '../entities/account.dart';
import '../../data/models/account_model.dart';
import '../core/result.dart';

/// Repository interface for account operations
abstract class AccountRepository {
  /// Create a new account
  Future<Result<Account, Exception>> createAccount(Account account);

  /// Get an account by ID
  Future<Result<Account?, Exception>> getAccountById(int id);

  /// Get all accounts for a profile
  Future<Result<List<Account>, Exception>> getAccountsByProfile(int profileId);

  /// Get active accounts for a profile
  Future<Result<List<Account>, Exception>> getActiveAccountsByProfile(
    int profileId,
  );

  /// Update an existing account
  Future<Result<Account, Exception>> updateAccount(Account account);

  /// Delete an account by ID
  Future<Result<void, Exception>> deleteAccount(int id);

  /// Get account balance
  Future<Result<int, Exception>> getAccountBalance(int accountId);

  /// Update account balance
  Future<Result<void, Exception>> updateAccountBalance(
    int accountId,
    int newBalanceMinor,
  );

  /// Get total balance converted to target currency
  Future<Result<double, Exception>> getTotalBalanceInCurrency(
    int profileId,
    String targetCurrency, {
    bool? isActive,
  });
}
