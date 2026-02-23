import '../entities/goal.dart';
import '../repositories/transaction_repository.dart';

/// Repository interface for goal operations
abstract class GoalRepository {
  /// Create a new goal
  Future<Result<Goal>> createGoal(Goal goal);

  /// Update an existing goal
  Future<Result<Goal>> updateGoal(Goal goal);

  /// Delete a goal
  Future<Result<void>> deleteGoal(int goalId);

  /// Get goal by ID
  Future<Result<Goal?>> getGoalById(int goalId);

  /// Get goals for a profile
  Future<Result<List<Goal>>> getGoals(
    int profileId, {
    bool? isActive,
    bool? isCompleted,
  });

  /// Update goal current amount (recalculate from linked transactions)
  Future<Result<Goal>> recalculateGoalAmount(int goalId);

  /// Get goals nearing completion
  Future<Result<List<Goal>>> getGoalsNearingCompletion(int profileId);

  /// Get overdue goals
  Future<Result<List<Goal>>> getOverdueGoals(int profileId);

  /// Link a transaction to a goal
  Future<Result<void>> linkTransactionToGoal(
    int transactionId,
    int goalId,
  );

  /// Unlink a transaction from a goal
  Future<Result<void>> unlinkTransactionFromGoal(
    int transactionId,
    int goalId,
  );
}
