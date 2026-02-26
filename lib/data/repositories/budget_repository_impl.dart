import '../database/daos/budgets_dao.dart';
import '../mappers/budget_mapper.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/budget.dart' as domain;

/// Implementation of BudgetRepository using Drift DAO
class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetsDao _budgetsDao;
  final ITransactionRepository _transactionRepository;

  BudgetRepositoryImpl(this._budgetsDao, this._transactionRepository);

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
      
      // Calculate start and end of the budget month
      final startDate = DateTime(budget.year, budget.month, 1);
      final endDate = DateTime(budget.year, budget.month + 1, 0, 23, 59, 59);
      
      // Get total debit transactions for this category in this month
      final spentResult = await _transactionRepository.getTotalAmountByType(
        budget.profileId,
        'debit',
        categoryId: budget.categoryId,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (spentResult.isFailure) {
        return Failure(spentResult.failureData!);
      }
      
      final spentAmount = spentResult.successData!.abs();
      final remaining = budget.amountMinor - spentAmount;
      final usagePercent = budget.amountMinor > 0 
          ? (spentAmount / budget.amountMinor * 100) 
          : 0.0;

      return Success(domain.BudgetUsage(
        budgetAmountMinor: budget.amountMinor,
        spentAmountMinor: spentAmount,
        remainingAmountMinor: remaining,
        usagePercentage: usagePercent,
        isOverBudget: spentAmount > budget.amountMinor,
        isNearLimit: usagePercent >= 90 && spentAmount <= budget.amountMinor,
      ));
    } catch (e) {
      return Failure(Exception('Failed to get budget usage: $e'));
    }
  }
}
