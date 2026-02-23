import '../entities/budget.dart';
import '../repositories/transaction_repository.dart';

/// Repository interface for budget operations
abstract class BudgetRepository {
  /// Create a new budget
  Future<Result<Budget>> createBudget(Budget budget);

  /// Update an existing budget
  Future<Result<Budget>> updateBudget(Budget budget);

  /// Delete a budget
  Future<Result<void>> deleteBudget(int budgetId);

  /// Get budget by ID
  Future<Result<Budget?>> getBudgetById(int budgetId);

  /// Get budgets for a profile
  Future<Result<List<Budget>>> getBudgets(
    int profileId, {
    int? month,
    int? year,
    int? categoryId,
  });

  /// Get budget for specific month, year, and category
  Future<Result<Budget?>> getBudgetForPeriod(
    int profileId,
    int categoryId,
    int month,
    int year,
  );

  /// Get current month budgets for a profile
  Future<Result<List<Budget>>> getCurrentMonthBudgets(int profileId);

  /// Get budget usage statistics
  Future<Result<BudgetUsage>> getBudgetUsage(
    int budgetId,
  );
}

/// Budget usage information
class BudgetUsage {
  const BudgetUsage({
    required this.budgetAmountMinor,
    required this.spentAmountMinor,
    required this.remainingAmountMinor,
    required this.usagePercentage,
    required this.isOverBudget,
    required this.isNearLimit,
  });

  final int budgetAmountMinor;
  final int spentAmountMinor;
  final int remainingAmountMinor;
  final double usagePercentage;
  final bool isOverBudget;
  final bool isNearLimit;
}
