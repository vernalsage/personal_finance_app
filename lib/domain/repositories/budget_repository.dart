import '../entities/budget.dart';
import '../core/result.dart';

/// Repository interface for budget operations
abstract class BudgetRepository {
  /// Create a new budget
  Future<Result<Budget, Exception>> createBudget(Budget budget);

  /// Update an existing budget
  Future<Result<Budget, Exception>> updateBudget(Budget budget);

  /// Delete a budget
  Future<Result<void, Exception>> deleteBudget(int budgetId);

  /// Get budget by ID
  Future<Result<Budget?, Exception>> getBudgetById(int budgetId);

  /// Get budgets for a profile
  Future<Result<List<Budget>, Exception>> getBudgets(
    int profileId, {
    int? month,
    int? year,
    int? categoryId,
  });

  /// Get budget for specific month, year, and category
  Future<Result<Budget?, Exception>> getBudgetForPeriod(
    int profileId,
    int categoryId,
    int month,
    int year,
  );

  /// Get current month budgets for a profile
  Future<Result<List<Budget>, Exception>> getCurrentMonthBudgets(int profileId);

  /// Get budget usage statistics
  Future<Result<BudgetUsage, Exception>> getBudgetUsage(
    int budgetId,
  );

  /// Get total budget summary (spent vs limit) for a given month and year
  Future<Result<BudgetUsage, Exception>> getTotalBudgetSummary(
    int profileId,
    int month,
    int year,
  );

  /// Convert all budget limits for a profile to a new currency
  Future<Result<void, Exception>> convertBudgets(
    int profileId,
    double conversionRate,
  );
}

