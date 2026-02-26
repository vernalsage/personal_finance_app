import '../repositories/itransaction_repository.dart';
import '../repositories/account_repository.dart';

/// Use case for getting financial overview
class GetFinancialOverviewUseCase {
  GetFinancialOverviewUseCase(
    this._transactionRepository,
    this._accountRepository,
  );

  final ITransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  Future<Result<FinancialOverview, Exception>> call(
    int profileId, {
    DateTime? startDate,
    DateTime? endDate,
    String? targetCurrency = 'NGN', // Default to NGN for now
  }) async {
    // Get transaction stats
    final transactionStatsResult = await _transactionRepository
        .getTransactionStats(profileId, startDate: startDate, endDate: endDate);

    if (transactionStatsResult.isFailure) {
      return Failure(Exception(transactionStatsResult.failureData!));
    }

    // Get total balance converted to target currency
    final totalBalanceResult = await _accountRepository
        .getTotalBalanceInCurrency(profileId, targetCurrency ?? 'NGN');

    if (totalBalanceResult.isFailure) {
      return Failure(Exception(totalBalanceResult.failureData.toString()));
    }

    final stats = transactionStatsResult.successData!;
    final totalBalance = totalBalanceResult.successData!;

    return Success(
      FinancialOverview(
        totalIncome: stats.totalIncome,
        totalExpenses: stats.totalExpenses,
        netIncome: stats.netIncome,
        totalBalance: (totalBalance * 100)
            .round(), // Convert back to minor units for consistency
        transactionCount: stats.transactionCount,
        averageTransactionAmount: stats.averageTransactionAmount,
      ),
    );
  }
}

/// Use case for calculating cash runway
class CalculateCashRunwayUseCase {
  CalculateCashRunwayUseCase(
    this._transactionRepository,
    this._accountRepository,
  );

  final ITransactionRepository _transactionRepository;
  final IAccountRepository _accountRepository;

  Future<Result<CashRunway, Exception>> call(
    int profileId, {
    String? targetCurrency = 'NGN',
  }) async {
    // Get total balance across non-credit accounts converted to target currency
    final totalBalanceResult = await _accountRepository
        .getTotalBalanceInCurrency(
          profileId,
          targetCurrency ?? 'NGN',
          isActive: true,
        );

    if (totalBalanceResult.isFailure) {
      return Failure(Exception(totalBalanceResult.failureData.toString()));
    }

    // Get average monthly expenses from last 3 months
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    final transactionStatsResult = await _transactionRepository
        .getTransactionStats(
          profileId,
          startDate: threeMonthsAgo,
          endDate: now,
        );

    if (transactionStatsResult.isFailure) {
      return Failure(Exception(transactionStatsResult.failureData!));
    }

    final totalBalance = totalBalanceResult.successData!;
    final stats = transactionStatsResult.successData!;

    // Calculate average monthly expenses
    final averageMonthlyExpenses = stats.totalExpenses / 3;

    // Calculate runway in days
    int runwayDays = 0;
    if (averageMonthlyExpenses > 0) {
      runwayDays = (totalBalance / (averageMonthlyExpenses / 30)).round();
    }

    return Success(
      CashRunway(
        totalBalance: (totalBalance * 100)
            .round(), // Convert back to minor units for consistency
        averageMonthlyExpenses: averageMonthlyExpenses.round(),
        runwayDays: runwayDays,
      ),
    );
  }
}

/// Financial overview data
class FinancialOverview {
  const FinancialOverview({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.totalBalance,
    required this.transactionCount,
    required this.averageTransactionAmount,
  });

  final int totalIncome;
  final int totalExpenses;
  final int netIncome;
  final int totalBalance;
  final int transactionCount;
  final double averageTransactionAmount;
}

/// Cash runway information
class CashRunway {
  const CashRunway({
    required this.totalBalance,
    required this.averageMonthlyExpenses,
    required this.runwayDays,
  });

  final int totalBalance;
  final int averageMonthlyExpenses;
  final int runwayDays;
}
