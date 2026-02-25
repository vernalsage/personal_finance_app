import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';

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
  TransactionsNotifier() : super(const TransactionsState());

  /// Fetch transactions for a profile (placeholder implementation)
  Future<void> loadTransactions(
    int profileId, {
    int? limit,
    int? offset,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // Placeholder implementation - in real app, this would call a use case
    final transactions = <Transaction>[];
    
    state = state.copyWith(
      transactions: transactions,
      isLoading: false,
    );
  }

  /// Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    state = state.copyWith(isLoading: true, error: null);

    // Placeholder implementation - in real app, this would call a use case
    await loadTransactions(transaction.profileId);
    
    state = state.copyWith(
      isLoading: false,
    );
  }

  /// Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    state = state.copyWith(isLoading: true, error: null);

    // Placeholder implementation - in real app, this would call a use case
    await loadTransactions(transaction.profileId);
    
    state = state.copyWith(
      isLoading: false,
    );
  }

  /// Delete a transaction
  Future<void> deleteTransaction(int transactionId) async {
    state = state.copyWith(isLoading: true, error: null);

    // Remove from local state optimistically
    final updatedTransactions = state.transactions
        .where((t) => t.id != transactionId)
        .toList();
    
    state = state.copyWith(
      transactions: updatedTransactions,
      isLoading: false,
    );
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
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier();
});
