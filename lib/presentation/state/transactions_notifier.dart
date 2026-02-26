import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../core/di/repository_providers.dart';

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
  TransactionsNotifier(this._createTransactionUseCase)
    : super(const TransactionsState());

  final CreateTransactionUseCase _createTransactionUseCase;
  UpdateTransactionUseCase? _updateTransactionUseCase;
  DeleteTransactionUseCase? _deleteTransactionUseCase;

  void setUseCases({
    UpdateTransactionUseCase? updateTransactionUseCase,
    DeleteTransactionUseCase? deleteTransactionUseCase,
  }) {
    _updateTransactionUseCase = updateTransactionUseCase;
    _deleteTransactionUseCase = deleteTransactionUseCase;
  }

  /// Fetch transactions for a profile
  Future<void> loadTransactions(
    int profileId, {
    int? limit,
    int? offset,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // For now, we'll use a simple approach since GetTransactionsUseCase doesn't exist
    // In a real implementation, you'd want to create this use case
    final transactions = <Transaction>[]; // Placeholder

    state = state.copyWith(transactions: transactions, isLoading: false);
  }

  /// Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createTransactionUseCase(transaction);

    if (result.isSuccess) {
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
  Future<void> deleteTransaction(int transactionId) async {
    if (_deleteTransactionUseCase == null) {
      state = state.copyWith(error: 'DeleteTransactionUseCase not initialized');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteTransactionUseCase!(transactionId);

    if (result.isSuccess) {
      // Remove from local state optimistically
      final updatedTransactions = state.transactions
          .where((t) => t.id != transactionId)
          .toList();

      state = state.copyWith(
        transactions: updatedTransactions,
        isLoading: false,
      );
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
      final createTransactionUseCase = CreateTransactionUseCase(
        ref.read(transactionRepositoryProvider),
        ref.read(merchantRepositoryProvider),
      );
      final updateTransactionUseCase = UpdateTransactionUseCase(
        ref.read(transactionRepositoryProvider),
      );
      final deleteTransactionUseCase = DeleteTransactionUseCase(
        ref.read(transactionRepositoryProvider),
      );

      final notifier = TransactionsNotifier(createTransactionUseCase);
      notifier.setUseCases(
        updateTransactionUseCase: updateTransactionUseCase,
        deleteTransactionUseCase: deleteTransactionUseCase,
      );

      return notifier;
    });
