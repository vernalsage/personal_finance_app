import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/database/app_database.dart' hide Transaction;
import '../../domain/usecases/transaction_usecases.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../data/repositories/merchant_repository_impl.dart';
import '../../data/database/daos/merchants_dao.dart';
import '../../data/database/daos/transactions_dao.dart';

/// Provider for database
final databaseRepositoryProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for merchants DAO
final merchantsDaoProvider = Provider<MerchantsDao>((ref) {
  final db = ref.read(databaseRepositoryProvider);
  return MerchantsDao(db);
});

/// Provider for transactions DAO
final transactionsDaoProvider = Provider<TransactionsDao>((ref) {
  final db = ref.read(databaseRepositoryProvider);
  return TransactionsDao(db);
});

/// Provider for transaction repository
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.read(transactionsDaoProvider));
});

/// Provider for merchant repository
final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepositoryImpl(ref.read(merchantsDaoProvider));
});

/// Provider for create transaction use case
final createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>((
  ref,
) {
  return CreateTransactionUseCase(
    ref.read(transactionRepositoryProvider),
    ref.read(merchantRepositoryProvider),
  );
});

/// Provider for update transaction use case
final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((
  ref,
) {
  return UpdateTransactionUseCase(ref.read(transactionRepositoryProvider));
});

/// Provider for delete transaction use case
final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((
  ref,
) {
  return DeleteTransactionUseCase(ref.read(transactionRepositoryProvider));
});

/// Provider for get transactions requiring review use case
final getTransactionsRequiringReviewUseCaseProvider =
    Provider<GetTransactionsRequiringReviewUseCase>((ref) {
      return GetTransactionsRequiringReviewUseCase(
        ref.read(transactionRepositoryProvider),
      );
    });

/// State for transactions list
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

/// Provider for transactions state
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  TransactionsNotifier(this._getTransactionsRequiringReviewUseCase)
    : super(const TransactionsState());

  final GetTransactionsRequiringReviewUseCase
  _getTransactionsRequiringReviewUseCase;

  Future<void> loadTransactionsRequiringReview(int profileId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getTransactionsRequiringReviewUseCase(profileId);

    if (result.isSuccess) {
      state = state.copyWith(transactions: result.data!, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error?.toString() ?? 'Unknown error',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
      return TransactionsNotifier(
        ref.read(getTransactionsRequiringReviewUseCaseProvider),
      );
    });
