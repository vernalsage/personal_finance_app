import '../database/daos/budgets_dao.dart';
import '../mappers/budget_mapper.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/budget.dart' as domain;
import '../../application/services/hybrid_currency_service.dart';

/// Implementation of BudgetRepository using Drift DAO
class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetsDao _budgetsDao;
  final ITransactionRepository _transactionRepository;
  final ProfileRepository _profileRepository;

  BudgetRepositoryImpl(
    this._budgetsDao, 
    this._transactionRepository,
    this._profileRepository,
  );

  @override
  Future<Result<domain.Budget, Exception>> createBudget(
    domain.Budget budget,
  ) async {
    try {
      final companion = budget.toCompanion();
      final createdBudget = await _budgetsDao.createBudget(companion);
      return Success(createdBudget.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to create budget: $e'));
    }
  }

  @override
  Future<Result<domain.Budget, Exception>> updateBudget(
    domain.Budget budget,
  ) async {
    try {
      final companion = budget.toUpdateCompanion();
      final updatedBudget = await _budgetsDao.updateBudget(companion);
      return Success(updatedBudget.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update budget: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> deleteBudget(int budgetId) async {
    try {
      await _budgetsDao.deleteBudget(budgetId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to delete budget: $e'));
    }
  }

  @override
  Future<Result<domain.Budget?, Exception>> getBudgetById(int budgetId) async {
    try {
      final budget = await _budgetsDao.getBudget(budgetId);
      return Success(budget?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get budget by ID: $e'));
    }
  }

  @override
  Future<Result<List<domain.Budget>, Exception>> getBudgets(
    int profileId, {
    int? month,
    int? year,
    int? categoryId,
  }) async {
    try {
      final budgets = await _budgetsDao.getAllBudgets(
        profileId: profileId,
        month: month,
        year: year,
        categoryId: categoryId,
      );
      return Success(budgets.map((b) => b.toEntity()).toList());
    } catch (e) {
      return Failure(Exception('Failed to get budgets: $e'));
    }
  }

  @override
  Future<Result<domain.Budget?, Exception>> getBudgetForPeriod(
    int profileId,
    int categoryId,
    int month,
    int year,
  ) async {
    try {
      final budget = await _budgetsDao.getBudgetForMonth(
        profileId,
        categoryId,
        month,
        year,
      );
      return Success(budget?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get budget for period: $e'));
    }
  }

  @override
  Future<Result<List<domain.Budget>, Exception>> getCurrentMonthBudgets(
    int profileId,
  ) async {
    final now = DateTime.now();
    return getBudgets(profileId, month: now.month, year: now.year);
  }

  @override
  Future<Result<domain.BudgetUsage, Exception>> getBudgetUsage(
    int budgetId,
  ) async {
    try {
      final budgetResult = await getBudgetById(budgetId);
      if (budgetResult.isFailure || budgetResult.successData == null) {
        return Failure(Exception('Budget not found'));
      }
      
      final budget = budgetResult.successData!;
      
      // Get profile for base currency
      final profileResult = await _profileRepository.getProfileById(budget.profileId);
      if (profileResult.isFailure) return Failure(profileResult.failureData!);
      final baseCurrency = profileResult.successData?.currency ?? 'NGN';
      
      // Calculate start and end of the budget month
      final startDate = DateTime(budget.year, budget.month, 1);
      final endDate = DateTime(budget.year, budget.month + 1, 0, 23, 59, 59);
      
      // Get all debit transactions for this category in this month with details
      final transactionsResult = await _transactionRepository.getTransactionsWithDetails(
        profileId: budget.profileId,
        type: 'debit',
        categoryId: budget.categoryId,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.failureData!);
      }

      double totalSpentBase = 0;
      for (final detail in transactionsResult.successData!) {
        final amount = detail.transaction.amountMinor.abs() / 100.0;
        final fromCurrency = detail.account?.currency ?? 'NGN';
        
        final converted = await HybridCurrencyService.convertCurrency(
          amount: amount,
          fromCurrency: fromCurrency,
          toCurrency: baseCurrency,
        );
        totalSpentBase += converted;
      }

      final spentAmountMinor = (totalSpentBase * 100).round();
      final remaining = budget.amountMinor - spentAmountMinor;
      final usagePercent = budget.amountMinor > 0 
          ? (spentAmountMinor / budget.amountMinor * 100) 
          : 0.0;

      return Success(domain.BudgetUsage(
        budgetAmountMinor: budget.amountMinor,
        spentAmountMinor: spentAmountMinor,
        remainingAmountMinor: remaining,
        usagePercentage: usagePercent,
        isOverBudget: spentAmountMinor > budget.amountMinor,
        isNearLimit: usagePercent >= 90 && spentAmountMinor <= budget.amountMinor,
      ));
    } catch (e) {
      return Failure(Exception('Failed to get budget usage: $e'));
    }
  }

  @override
  Future<Result<domain.BudgetUsage, Exception>> getTotalBudgetSummary(
    int profileId,
    int month,
    int year,
  ) async {
    try {
      // 1. Get profile for base currency
      final profileResult = await _profileRepository.getProfileById(profileId);
      if (profileResult.isFailure) return Failure(profileResult.failureData!);
      final baseCurrency = profileResult.successData?.currency ?? 'NGN';

      // 2. Get total budget limit (already in base currency by convention)
      final totalLimit = await _budgetsDao.getTotalBudgetLimit(profileId, month, year);
      
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // 3. Get all debit transactions with account details for the period
      final transactionsResult = await _transactionRepository.getTransactionsWithDetails(
        profileId: profileId,
        type: 'debit',
        startDate: startDate,
        endDate: endDate,
      );

      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.failureData!);
      }

      double totalSpentBase = 0;
      for (final detail in transactionsResult.successData!) {
        final amount = detail.transaction.amountMinor.abs() / 100.0;
        final fromCurrency = detail.account?.currency ?? 'NGN';
        
        final converted = await HybridCurrencyService.convertCurrency(
          amount: amount,
          fromCurrency: fromCurrency,
          toCurrency: baseCurrency,
        );
        totalSpentBase += converted;
      }

      final spentAmountMinor = (totalSpentBase * 100).round();
      final remaining = totalLimit - spentAmountMinor;
      final usagePercent = totalLimit > 0 
          ? (spentAmountMinor / totalLimit * 100) 
          : 0.0;

      return Success(domain.BudgetUsage(
        budgetAmountMinor: totalLimit,
        spentAmountMinor: spentAmountMinor,
        remainingAmountMinor: remaining,
        usagePercentage: usagePercent,
        isOverBudget: spentAmountMinor > totalLimit,
        isNearLimit: usagePercent >= 90 && spentAmountMinor <= totalLimit,
      ));
    } catch (e) {
      return Failure(Exception('Failed to get total budget summary: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> convertBudgets(
    int profileId,
    double conversionRate,
  ) async {
    try {
      await _budgetsDao.convertBudgetsCurrency(
        profileId: profileId,
        conversionRate: conversionRate,
      );
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to convert budgets: $e'));
    }
  }
}
