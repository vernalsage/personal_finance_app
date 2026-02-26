import '../database/daos/accounts_dao.dart';
import '../mappers/account_mapper.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/account.dart' as domain;

/// Implementation of AccountRepository using Drift DAO
class AccountRepositoryImpl implements AccountRepository {
  final AccountsDao _accountsDao;

  AccountRepositoryImpl(this._accountsDao);

  @override
  Future<Result<domain.Account, Exception>> createAccount(
    domain.Account account,
  ) async {
    try {
      final companion = account.toCompanion();
      final createdAccount = await _accountsDao.createAccount(companion);
      return Success(createdAccount.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to create account: $e'));
    }
  }

  @override
  Future<Result<domain.Account?, Exception>> getAccountById(int id) async {
    try {
      final account = await _accountsDao.getAccount(id);
      return Success(account?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get account by ID: $e'));
    }
  }

  @override
  Future<Result<List<domain.Account>, Exception>> getAccountsByProfile(
    int profileId,
  ) async {
    try {
      final accounts = await _accountsDao.getAllAccounts(profileId: profileId);
      final domainAccounts = accounts
          .map((account) => account.toEntity())
          .toList();
      return Success(domainAccounts);
    } catch (e) {
      return Failure(Exception('Failed to get accounts by profile: $e'));
    }
  }

  @override
  Future<Result<List<domain.Account>, Exception>> getActiveAccountsByProfile(
    int profileId,
  ) async {
    try {
      final accounts = await _accountsDao.getAllAccounts(
        profileId: profileId,
        isActive: true,
      );
      return Success(accounts.map((account) => account.toEntity()).toList());
    } catch (e) {
      return Failure(Exception('Failed to get active accounts by profile: $e'));
    }
  }

  @override
  Future<Result<domain.Account, Exception>> updateAccount(
    domain.Account account,
  ) async {
    try {
      final companion = account.toUpdateCompanion();

      // Update balance if it's being changed
      if (companion.balanceMinor.present) {
        await _accountsDao.updateAccountBalance(
          account.id,
          companion.balanceMinor.value,
        );
      }

      // Update other fields separately using individual update methods
      if (companion.name.present) {
        await _accountsDao.updateAccountName(account.id, companion.name.value);
      }
      if (companion.type.present) {
        await _accountsDao.updateAccountType(account.id, companion.type.value);
      }
      if (companion.currency.present) {
        await _accountsDao.updateAccountCurrency(
          account.id,
          companion.currency.value,
        );
      }
      if (companion.description.present) {
        await _accountsDao.updateAccountDescription(
          account.id,
          companion.description.value,
        );
      }
      if (companion.isActive.present) {
        if (companion.isActive.value) {
          await _accountsDao.activateAccount(account.id);
        } else {
          await _accountsDao.deactivateAccount(account.id);
        }
      }

      // Get the final updated account
      final finalAccount = await _accountsDao.getAccount(account.id);
      return Success(finalAccount!.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update account: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> deleteAccount(int id) async {
    try {
      await _accountsDao.deleteAccount(id);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to delete account: $e'));
    }
  }

  @override
  Future<Result<int, Exception>> getAccountBalance(int accountId) async {
    try {
      final balance = await _accountsDao.getAccountBalance(accountId);
      return Success(balance);
    } catch (e) {
      return Failure(Exception('Failed to get account balance: $e'));
    }
  }

  /// Get total balance converted to target currency
  @override
  Future<Result<double, Exception>> getTotalBalanceInCurrency(
    int profileId,
    String targetCurrency, {
    bool? isActive,
  }) async {
    try {
      final balance = await _accountsDao.getTotalBalanceInCurrency(
        profileId,
        targetCurrency,
        isActive: isActive,
      );
      return Success(balance);
    } catch (e) {
      return Failure(
        Exception('Failed to get total balance in $targetCurrency: $e'),
      );
    }
  }

  @override
  Future<Result<void, Exception>> updateAccountBalance(
    int accountId,
    int newBalanceMinor,
  ) async {
    try {
      await _accountsDao.updateAccountBalance(accountId, newBalanceMinor);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to update account balance: $e'));
    }
  }
}
