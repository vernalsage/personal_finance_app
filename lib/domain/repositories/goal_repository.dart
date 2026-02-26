import '../entities/goal.dart';
import '../core/result.dart';

/// Repository interface for goal operations
abstract class GoalRepository {
  /// Create a new goal
  Future<Result<Goal, Exception>> createGoal(Goal goal);

  /// Update an existing goal
  Future<Result<Goal, Exception>> updateGoal(Goal goal);

  /// Delete a goal
  Future<Result<void, Exception>> deleteGoal(int goalId);

  /// Get goal by ID
  Future<Result<Goal?, Exception>> getGoalById(int goalId);

  /// Get goals for a profile
  Future<Result<List<Goal>, Exception>> getGoals(
    int profileId, {
    bool? isActive,
    bool? isCompleted,
  });

  /// Update goal current amount (recalculate from linked transactions)
  Future<Result<Goal, Exception>> recalculateGoalAmount(int goalId);

  /// Get goals nearing completion
  Future<Result<List<Goal>, Exception>> getGoalsNearingCompletion(int profileId);

  /// Get overdue goals
  Future<Result<List<Goal>, Exception>> getOverdueGoals(int profileId);

  /// Link a transaction to a goal
  Future<Result<void, Exception>> linkTransactionToGoal(
    int transactionId,
    int goalId,
  );

  /// Unlink a transaction from a goal
  Future<Result<void, Exception>> unlinkTransactionFromGoal(
    int transactionId,
    int goalId,
  );
}
