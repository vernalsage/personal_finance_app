import '../entities/budget.dart';
import '../repositories/budget_repository.dart';
import '../core/result.dart';

/// Use case to get budgets for a specific period
class GetBudgetsUseCase {
  final BudgetRepository _repository;

  GetBudgetsUseCase(this._repository);

  Future<Result<List<Budget>, Exception>> call(
    int profileId, {
    int? month,
    int? year,
    int? categoryId,
  }) {
    return _repository.getBudgets(
      profileId,
      month: month,
      year: year,
      categoryId: categoryId,
    );
  }
}

/// Use case to get budget usage (spent vs limit) for a budget
class GetBudgetUsageUseCase {
  final BudgetRepository _repository;

  GetBudgetUsageUseCase(this._repository);

  Future<Result<BudgetUsage, Exception>> call(int budgetId) {
    return _repository.getBudgetUsage(budgetId);
  }
}

/// Use case to create a new budget
class CreateBudgetUseCase {
  final BudgetRepository _repository;

  CreateBudgetUseCase(this._repository);

  Future<Result<Budget, Exception>> call(Budget budget) {
    return _repository.createBudget(budget);
  }
}

/// Use case to update an existing budget
class UpdateBudgetUseCase {
  final BudgetRepository _repository;

  UpdateBudgetUseCase(this._repository);

  Future<Result<Budget, Exception>> call(Budget budget) {
    return _repository.updateBudget(budget);
  }
}

/// Use case to delete a budget
class DeleteBudgetUseCase {
  final BudgetRepository _repository;

  DeleteBudgetUseCase(this._repository);

  Future<Result<void, Exception>> call(int budgetId) {
    return _repository.deleteBudget(budgetId);
  }
}

/// Use case to get the total budget summary for a month
class GetTotalBudgetSummaryUseCase {
  final BudgetRepository _repository;

  GetTotalBudgetSummaryUseCase(this._repository);

  Future<Result<BudgetUsage, Exception>> call(
    int profileId,
    int month,
    int year,
  ) {
    return _repository.getTotalBudgetSummary(profileId, month, year);
  }
}
