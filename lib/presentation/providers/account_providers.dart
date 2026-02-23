import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/iaccount_repository.dart';
import '../../domain/usecases/account_usecases.dart';
import '../../domain/entities/account.dart' as domain;
import '../../data/repositories/account_repository_impl.dart';
import '../../data/database/daos/accounts_dao.dart';
import '../../data/database/app_database_simple.dart';

/// Provider for accounts DAO
final accountsDaoProvider = Provider<AccountsDao>((ref) {
  final db = AppDatabase();
  return AccountsDao(db);
});

/// Provider for account repository
final accountRepositoryProvider = Provider<IAccountRepository>((ref) {
  return AccountRepositoryImpl(ref.read(accountsDaoProvider));
});

/// Provider for create account use case
final createAccountUseCaseProvider = Provider<CreateAccountUseCase>((ref) {
  return CreateAccountUseCase(
    AccountRepositoryImpl(ref.read(accountsDaoProvider)),
  );
});

/// Provider for update account use case
final updateAccountUseCaseProvider = Provider<UpdateAccountUseCase>((ref) {
  return UpdateAccountUseCase(
    AccountRepositoryImpl(ref.read(accountsDaoProvider)),
  );
});

/// Provider for delete account use case
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(
    AccountRepositoryImpl(ref.read(accountsDaoProvider)),
  );
});

/// Provider for get accounts use case
final getAccountsUseCaseProvider = Provider<GetAccountsUseCase>((ref) {
  return GetAccountsUseCase(
    AccountRepositoryImpl(ref.read(accountsDaoProvider)),
  );
});

/// Provider for update account balance use case
final updateAccountBalanceUseCaseProvider =
    Provider<UpdateAccountBalanceUseCase>((ref) {
      return UpdateAccountBalanceUseCase(
        AccountRepositoryImpl(ref.read(accountsDaoProvider)),
      );
    });

/// State for accounts list
class AccountsState {
  const AccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
  });

  final List<domain.Account> accounts;
  final bool isLoading;
  final String? error;

  AccountsState copyWith({
    List<domain.Account>? accounts,
    bool? isLoading,
    String? error,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider for accounts state
class AccountsNotifier extends StateNotifier<AccountsState> {
  AccountsNotifier(this._getAccountsUseCase) : super(const AccountsState());

  final GetAccountsUseCase _getAccountsUseCase;

  Future<void> loadAccounts(
    int profileId, {
    bool? isActive,
    String? type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAccountsUseCase(
      profileId,
      isActive: isActive,
      type: type,
    );

    if (result.isSuccess) {
      state = state.copyWith(accounts: result.successData!, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failureData.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, AccountsState>(
  (ref) {
    return AccountsNotifier(ref.read(getAccountsUseCaseProvider));
  },
);
