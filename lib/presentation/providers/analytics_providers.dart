import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/analytics_usecases.dart';

/// Provider for transaction repository (shared)
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  // TODO: Implement actual repository
  throw UnimplementedError('Transaction repository not implemented');
});

/// Provider for account repository (shared)
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  // TODO: Implement actual repository
  throw UnimplementedError('Account repository not implemented');
});

/// Provider for get financial overview use case
final getFinancialOverviewUseCaseProvider =
    Provider<GetFinancialOverviewUseCase>((ref) {
      return GetFinancialOverviewUseCase(
        ref.read(transactionRepositoryProvider),
        ref.read(accountRepositoryProvider),
      );
    });

/// Provider for calculate cash runway use case
final calculateCashRunwayUseCaseProvider = Provider<CalculateCashRunwayUseCase>(
  (ref) {
    return CalculateCashRunwayUseCase(
      ref.read(transactionRepositoryProvider),
      ref.read(accountRepositoryProvider),
    );
  },
);

/// State for financial overview
class FinancialOverviewState {
  const FinancialOverviewState({
    this.overview,
    this.isLoading = false,
    this.error,
  });

  final FinancialOverview? overview;
  final bool isLoading;
  final String? error;

  FinancialOverviewState copyWith({
    FinancialOverview? overview,
    bool? isLoading,
    String? error,
  }) {
    return FinancialOverviewState(
      overview: overview ?? this.overview,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider for financial overview state
class FinancialOverviewNotifier extends StateNotifier<FinancialOverviewState> {
  FinancialOverviewNotifier(this._getFinancialOverviewUseCase)
    : super(const FinancialOverviewState());

  final GetFinancialOverviewUseCase _getFinancialOverviewUseCase;

  Future<void> loadFinancialOverview(
    int profileId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getFinancialOverviewUseCase(
      profileId,
      startDate: startDate,
      endDate: endDate,
    );

    if (result.isSuccess) {
      state = state.copyWith(overview: result.data!, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final financialOverviewProvider =
    StateNotifierProvider<FinancialOverviewNotifier, FinancialOverviewState>((
      ref,
    ) {
      return FinancialOverviewNotifier(
        ref.read(getFinancialOverviewUseCaseProvider),
      );
    });

/// State for cash runway
class CashRunwayState {
  const CashRunwayState({this.cashRunway, this.isLoading = false, this.error});

  final CashRunway? cashRunway;
  final bool isLoading;
  final String? error;

  CashRunwayState copyWith({
    CashRunway? cashRunway,
    bool? isLoading,
    String? error,
  }) {
    return CashRunwayState(
      cashRunway: cashRunway ?? this.cashRunway,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider for cash runway state
class CashRunwayNotifier extends StateNotifier<CashRunwayState> {
  CashRunwayNotifier(this._calculateCashRunwayUseCase)
    : super(const CashRunwayState());

  final CalculateCashRunwayUseCase _calculateCashRunwayUseCase;

  Future<void> calculateCashRunway(int profileId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _calculateCashRunwayUseCase(profileId);

    if (result.isSuccess) {
      state = state.copyWith(cashRunway: result.data!, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final cashRunwayProvider =
    StateNotifierProvider<CashRunwayNotifier, CashRunwayState>((ref) {
      return CashRunwayNotifier(ref.read(calculateCashRunwayUseCaseProvider));
    });
