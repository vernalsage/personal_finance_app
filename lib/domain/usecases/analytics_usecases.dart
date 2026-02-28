import '../core/result.dart';
import '../repositories/itransaction_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting financial overview
class GetFinancialOverviewUseCase {
  GetFinancialOverviewUseCase(
    this._transactionRepository,
    this._accountRepository,
    this._profileRepository,
  );

  final ITransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final ProfileRepository _profileRepository;

  Future<Result<FinancialOverview, Exception>> call(
    int profileId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get profile for base currency
    final profileResult = await _profileRepository.getProfileById(profileId);
    final targetCurrency = profileResult.successData?.currency ?? 'USD';

    // Get transaction stats (already converted to targetCurrency in repository)
    final transactionStatsResult = await _transactionRepository
        .getTransactionStats(
          profileId, 
          startDate: startDate, 
          endDate: endDate,
          targetCurrency: targetCurrency,
        );

    if (transactionStatsResult.isFailure) {
      return Failure(Exception(transactionStatsResult.failureData!));
    }

    // Get total balance converted to target currency (returns major units)
    final totalBalanceResult = await _accountRepository
        .getTotalBalanceInCurrency(profileId, targetCurrency);

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
        totalBalance: (totalBalance * 100).round(), // Store as minor units in DTO
        transactionCount: stats.transactionCount,
        averageTransactionAmount: stats.averageTransactionAmount,
        currencyCode: targetCurrency,
      ),
    );
  }
}

/// Use case for calculating cash runway
class CalculateCashRunwayUseCase {
  CalculateCashRunwayUseCase(
    this._transactionRepository,
    this._accountRepository,
    this._profileRepository,
  );

  final ITransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final ProfileRepository _profileRepository;

  Future<Result<CashRunway, Exception>> call(int profileId) async {
    // Get profile for base currency
    final profileResult = await _profileRepository.getProfileById(profileId);
    final targetCurrency = profileResult.successData?.currency ?? 'NGN';

    // Get total balance across non-credit accounts converted to target currency
    final totalBalanceResult = await _accountRepository
        .getTotalBalanceInCurrency(
          profileId,
          targetCurrency,
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
          targetCurrency: targetCurrency,
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
    required this.currencyCode,
  });

  final int totalIncome;
  final int totalExpenses;
  final int netIncome;
  final int totalBalance;
  final int transactionCount;
  final double averageTransactionAmount;
  final String currencyCode;
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

/// Use case for calculating financial stability score
class GetStabilityScoreUseCase {
  GetStabilityScoreUseCase(
    this._transactionRepository,
    this._accountRepository,
    this._profileRepository,
  );

  final ITransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final ProfileRepository _profileRepository;

  Future<Result<StabilityScore, Exception>> call(int profileId) async {
    try {
      // 1. Get profile for base currency
      final profileResult = await _profileRepository.getProfileById(profileId);
      final targetCurrency = profileResult.successData?.currency ?? 'NGN';

      // 2. Get Savings Rate (last 3 months)
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      final statsResult = await _transactionRepository.getTransactionStats(
        profileId,
        startDate: threeMonthsAgo,
        endDate: now,
        targetCurrency: targetCurrency,
      );

      if (statsResult.isFailure) return Failure(Exception(statsResult.failureData!));
      final stats = statsResult.successData!;

      double savingsRate = 0;
      if (stats.totalIncome > 0) {
        savingsRate = (stats.totalIncome - stats.totalExpenses) / stats.totalIncome;
      }

      // 3. Get Cash Runway score (capped at 6 months for max score contribution)
      final totalBalanceResult = await _accountRepository.getTotalBalanceInCurrency(
        profileId,
        targetCurrency,
        isActive: true,
      );
      if (totalBalanceResult.isFailure) return Failure(Exception(totalBalanceResult.failureData.toString()));
      
      final totalBalance = totalBalanceResult.successData!;
      final avgMonthlyExpenses = stats.totalExpenses / 3;
      double runwayMonths = 0;
      if (avgMonthlyExpenses > 0) {
        runwayMonths = totalBalance / avgMonthlyExpenses;
      }

      // 4. Calculate Final Score (0-100)
      // 60% Savings Rate (Savings rate of 25% gives full 60 points)
      // 40% Cash Runway (6 months gives full 40 points)
      
      double savingsScore = (savingsRate / 0.25) * 60;
      double runwayScore = (runwayMonths / 6.0) * 40;
      
      int finalScore = (savingsScore.clamp(0, 60) + runwayScore.clamp(0, 40)).round();

      return Success(StabilityScore(
        score: finalScore,
        savingsRate: savingsRate,
        runwayMonths: runwayMonths,
      ));
    } catch (e) {
      return Failure(Exception('Failed to calculate stability score: $e'));
    }
  }
}

/// Financial stability score information
class StabilityScore {
  const StabilityScore({
    required this.score,
    required this.savingsRate,
    required this.runwayMonths,
  });

  final int score;
  final double savingsRate;
  final double runwayMonths;
}
