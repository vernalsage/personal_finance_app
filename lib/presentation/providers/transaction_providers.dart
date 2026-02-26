import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../core/di/repository_providers.dart';
import '../../core/di/usecase_providers.dart';
import 'account_providers.dart';
import 'budget_providers.dart';
import 'goal_providers.dart';

/// State for transactions management
class TransactionsState {
  const TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing transactions state
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  TransactionsNotifier(this._createTransactionUseCase, this._getTransactionsUseCase, this._ref)
    : super(const TransactionsState());

  final CreateTransactionUseCase _createTransactionUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;
  final Ref _ref;
  UpdateTransactionUseCase? _updateTransactionUseCase;
  DeleteTransactionUseCase? _deleteTransactionUseCase;
  GetTransactionsRequiringReviewUseCase? _getTransactionsRequiringReviewUseCase;

  void setUseCases({
    UpdateTransactionUseCase? updateTransactionUseCase,
    DeleteTransactionUseCase? deleteTransactionUseCase,
    GetTransactionsRequiringReviewUseCase? getTransactionsRequiringReviewUseCase,
  }) {
    _updateTransactionUseCase = updateTransactionUseCase;
    _deleteTransactionUseCase = deleteTransactionUseCase;
    _getTransactionsRequiringReviewUseCase = getTransactionsRequiringReviewUseCase;
  }

  /// Fetch transactions for a profile
  Future<void> loadTransactions(
    int profileId, {
    int? accountId,
    int? limit,
    int? offset,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getTransactionsUseCase(
      profileId: profileId,
      accountId: accountId,
      limit: limit,
      offset: offset,
    );

    if (result.isSuccess) {
      state = state.copyWith(transactions: result.successData!, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failureData?.toString() ?? 'Failed to load transactions',
      );
    }
  }

  /// Fetch transactions requiring review
  Future<void> loadTransactionsRequiringReview(
    int profileId, {
    int? limit,
    int? offset,
  }) async {
    if (_getTransactionsRequiringReviewUseCase == null) {
      state = state.copyWith(error: 'GetTransactionsRequiringReviewUseCase not initialized');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getTransactionsRequiringReviewUseCase!(
      profileId,
      limit: limit,
      offset: offset,
    );

    if (result.isSuccess) {
      state = state.copyWith(transactions: result.successData!, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failureData?.toString() ?? 'Failed to load review items',
      );
    }
  }

  /// Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createTransactionUseCase(transaction);

    if (result.isSuccess) {
      // Invalidate related providers to reflect changes
      _ref.invalidate(accountsProvider);
      _ref.invalidate(budgetsProvider);
      _ref.invalidate(goalsProvider);
      
      // Refresh the transactions list
      await loadTransactions(transaction.profileId);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failureData?.toString() ?? 'Unknown error',
      );
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    if (_updateTransactionUseCase == null) {
      state = state.copyWith(error: 'UpdateTransactionUseCase not initialized');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateTransactionUseCase!(transaction);

    if (result.isSuccess) {
      // Invalidate related providers
      _ref.invalidate(accountsProvider);
      _ref.invalidate(budgetsProvider);
      _ref.invalidate(goalsProvider);
      
      // Refresh the transactions list
      await loadTransactions(transaction.profileId);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failureData?.toString() ?? 'Unknown error',
      );
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(int transactionId, int profileId) async {
    if (_deleteTransactionUseCase == null) {
      state = state.copyWith(error: 'DeleteTransactionUseCase not initialized');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteTransactionUseCase!(transactionId);

    if (result.isSuccess) {
      // Invalidate related providers
      _ref.invalidate(accountsProvider);
      _ref.invalidate(budgetsProvider);
      _ref.invalidate(goalsProvider);
      
      // Refresh the transactions list
      await loadTransactions(profileId);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failureData?.toString() ?? 'Unknown error',
      );
    }
  }

  /// Refresh transactions list
  Future<void> refreshTransactions(int profileId) async {
    await loadTransactions(profileId);
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for transactions state
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
      final createTransactionUseCase = ref.read(createTransactionUseCaseProvider);
      
      // Since GetTransactionsUseCase might not have a standalone provider yet in usecase_providers,
      // we'll instantiate it here using the repository. 
      // Actually, let's check if it exists in usecase_providers.dart
      final getTransactionsUseCase = GetTransactionsUseCase(
        ref.read(transactionRepositoryProvider),
      );
      
      final updateTransactionUseCase = ref.read(updateTransactionUseCaseProvider);
      final deleteTransactionUseCase = ref.read(deleteTransactionUseCaseProvider);
      final getTransactionsRequiringReviewUseCase = ref.read(getTransactionsRequiringReviewUseCaseProvider);

      final notifier = TransactionsNotifier(
        createTransactionUseCase,
        getTransactionsUseCase,
        ref,
      );
      notifier.setUseCases(
        updateTransactionUseCase: updateTransactionUseCase,
        deleteTransactionUseCase: deleteTransactionUseCase,
        getTransactionsRequiringReviewUseCase: getTransactionsRequiringReviewUseCase,
      );

      return notifier;
    });
