import '../repositories/transaction_repository.dart';
import '../repositories/account_repository.dart';

/// Use case for getting financial overview
class GetFinancialOverviewUseCase {
  GetFinancialOverviewUseCase(
    this._transactionRepository,
    this._accountRepository,
  );

  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  Future<Result<FinancialOverview>> call(
    int profileId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get transaction stats
    final transactionStatsResult = await _transactionRepository
        .getTransactionStats(profileId, startDate: startDate, endDate: endDate);

    if (transactionStatsResult.isFailure) {
      return Result.failure(transactionStatsResult.error!);
    }

    // Get total balance
    final totalBalanceResult = await _accountRepository.getTotalBalance(
      profileId,
    );

    if (totalBalanceResult.isFailure) {
      return Result.failure(totalBalanceResult.error!);
    }

    final stats = transactionStatsResult.data!;
    final totalBalance = totalBalanceResult.data!;

    return Result.success(
      FinancialOverview(
        totalIncome: stats.totalIncome,
        totalExpenses: stats.totalExpenses,
        netIncome: stats.netIncome,
        totalBalance: totalBalance,
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

  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  Future<Result<CashRunway>> call(int profileId) async {
    // Get total balance across non-credit accounts
    final totalBalanceResult = await _accountRepository.getTotalBalance(
      profileId,
      isActive: true,
    );

    if (totalBalanceResult.isFailure) {
      return Result.failure(totalBalanceResult.error!);
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
      return Result.failure(transactionStatsResult.error!);
    }

    final totalBalance = totalBalanceResult.data!;
    final stats = transactionStatsResult.data!;

    // Calculate average monthly expenses
    final averageMonthlyExpenses = stats.totalExpenses / 3;

    // Calculate runway in days
    int runwayDays = 0;
    if (averageMonthlyExpenses > 0) {
      runwayDays = (totalBalance / (averageMonthlyExpenses / 30)).round();
    }

    return Result.success(
      CashRunway(
        totalBalance: totalBalance,
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
