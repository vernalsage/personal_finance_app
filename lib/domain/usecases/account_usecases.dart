import '../entities/account.dart';
import '../repositories/account_repository.dart';
import '../core/result.dart';

/// Use case for creating an account
class CreateAccountUseCase {
  CreateAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<Account, Exception>> call(Account account) async {
    // Validate account
    if (account.name.isEmpty) {
      return Failure(Exception('Account name is required'));
    }

    if (account.currency.isEmpty) {
      return Failure(Exception('Account currency is required'));
    }

    if (account.balanceMinor < 0) {
      return Failure(Exception('Account balance cannot be negative'));
    }

    return await _repository.createAccount(account);
  }
}

/// Use case for updating an account
class UpdateAccountUseCase {
  UpdateAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<Account, Exception>> call(Account account) async {
    // Validate account
    if (account.name.isEmpty) {
      return Failure(Exception('Account name is required'));
    }

    if (account.currency.isEmpty) {
      return Failure(Exception('Account currency is required'));
    }

    return await _repository.updateAccount(account);
  }
}

/// Use case for deleting an account
class DeleteAccountUseCase {
  DeleteAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<void, Exception>> call(int accountId) async {
    return await _repository.deleteAccount(accountId);
  }
}

/// Use case for getting accounts for a profile
class GetAccountsUseCase {
  GetAccountsUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<List<Account>, Exception>> call(
    int profileId, {
    bool? isActive,
    String? type,
  }) async {
    if (isActive == true) {
      return await _repository.getActiveAccountsByProfile(profileId);
    } else {
      return await _repository.getAccountsByProfile(profileId);
    }
  }
}

/// Use case for updating account balance
class UpdateAccountBalanceUseCase {
  UpdateAccountBalanceUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<Account, Exception>> call(
    int accountId,
    int newBalanceMinor,
  ) async {
    final result = await _repository.updateAccountBalance(
      accountId,
      newBalanceMinor,
    );
    if (result.isSuccess) {
      // Get the updated account to return
      final accountResult = await _repository.getAccountById(accountId);
      if (accountResult.isSuccess && accountResult.successData != null) {
        return Success(accountResult.successData!);
      } else {
        return Failure(
          accountResult.failureData ??
              Exception('Failed to get updated account'),
        );
      }
    } else {
      return Failure(result.failureData!);
    }
  }
}
