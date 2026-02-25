import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/account_usecases.dart';
import '../../core/di/repository_providers.dart';

/// State for accounts management
class AccountsState {
  const AccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Account> accounts;
  final bool isLoading;
  final String? error;

  AccountsState copyWith({
    List<Account>? accounts,
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

/// Notifier for managing accounts state
class AccountsNotifier extends StateNotifier<AccountsState> {
  AccountsNotifier(this._getAccountsUseCase) : super(const AccountsState());

  final GetAccountsUseCase _getAccountsUseCase;
  CreateAccountUseCase? _createAccountUseCase;
  UpdateAccountUseCase? _updateAccountUseCase;

  void setUseCases({
    CreateAccountUseCase? createAccountUseCase,
    UpdateAccountUseCase? updateAccountUseCase,
  }) {
    _createAccountUseCase = createAccountUseCase;
    _updateAccountUseCase = updateAccountUseCase;
  }

  /// Fetch accounts for a profile
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

  /// Add a new account
  Future<void> addAccount(Account account) async {
    if (_createAccountUseCase == null) {
      state = state.copyWith(error: 'CreateAccountUseCase not initialized');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _createAccountUseCase!(account);

    if (result.isSuccess) {
      // Refresh the accounts list
      await loadAccounts(account.profileId);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failureData.toString(),
      );
    }
  }

  /// Update an existing account
  Future<void> updateAccount(Account account) async {
    if (_updateAccountUseCase == null) {
      state = state.copyWith(error: 'UpdateAccountUseCase not initialized');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateAccountUseCase!(account);

    if (result.isSuccess) {
      // Refresh the accounts list
      await loadAccounts(account.profileId);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failureData.toString(),
      );
    }
  }

  /// Refresh accounts list
  Future<void> refreshAccounts(int profileId) async {
    await loadAccounts(profileId);
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for accounts state
final accountsProvider = StateNotifierProvider<AccountsNotifier, AccountsState>(
  (ref) {
    final getAccountsUseCase = GetAccountsUseCase(
      ref.read(accountRepositoryProvider),
    );
    final createAccountUseCase = CreateAccountUseCase(
      ref.read(accountRepositoryProvider),
    );
    final updateAccountUseCase = UpdateAccountUseCase(
      ref.read(accountRepositoryProvider),
    );

    final notifier = AccountsNotifier(getAccountsUseCase);
    notifier.setUseCases(
      createAccountUseCase: createAccountUseCase,
      updateAccountUseCase: updateAccountUseCase,
    );

    return notifier;
  },
);
