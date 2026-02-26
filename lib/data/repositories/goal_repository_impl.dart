import '../database/daos/goals_dao.dart';
import '../mappers/goal_mapper.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/goal.dart' as domain;

/// Implementation of GoalRepository using Drift DAO
class GoalRepositoryImpl implements GoalRepository {
  final GoalsDao _goalsDao;

  GoalRepositoryImpl(this._goalsDao);

  @override
  Future<Result<domain.Goal, Exception>> createGoal(
    domain.Goal goal,
  ) async {
    try {
      final companion = goal.toCompanion();
      final createdGoal = await _goalsDao.createGoal(companion);
      return Success(createdGoal.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to create goal: $e'));
    }
  }

  @override
  Future<Result<domain.Goal, Exception>> updateGoal(
    domain.Goal goal,
  ) async {
    try {
      final companion = goal.toUpdateCompanion();
      final updatedGoal = await _goalsDao.updateGoal(companion);
      return Success(updatedGoal.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update goal: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> deleteGoal(int goalId) async {
    try {
      await _goalsDao.deleteGoal(goalId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to delete goal: $e'));
    }
  }

  @override
  Future<Result<domain.Goal?, Exception>> getGoalById(int goalId) async {
    try {
      final goal = await _goalsDao.getGoal(goalId);
      return Success(goal?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get goal by ID: $e'));
    }
  }

  @override
  Future<Result<List<domain.Goal>, Exception>> getGoals(
    int profileId, {
    bool? isActive,
    bool? isCompleted,
  }) async {
    try {
      final goals = await _goalsDao.getAllGoals(
        profileId: profileId,
        isActive: isActive,
      );
      
      var domainGoals = goals.map((g) => g.toEntity()).toList();
      
      if (isCompleted != null) {
        domainGoals = domainGoals.where((g) => g.isCompleted == isCompleted).toList();
      }
      
      return Success(domainGoals);
    } catch (e) {
      return Failure(Exception('Failed to get goals: $e'));
    }
  }

  @override
  Future<Result<domain.Goal, Exception>> recalculateGoalAmount(int goalId) async {
    try {
      await _goalsDao.recalculateGoalAmount(goalId);
      final goalResult = await getGoalById(goalId);
      if (goalResult.isFailure || goalResult.successData == null) {
        return Failure(Exception('Goal not found'));
      }
      return Success(goalResult.successData!);
    } catch (e) {
      return Failure(Exception('Failed to recalculate goal amount: $e'));
    }
  }

  @override
  Future<Result<List<domain.Goal>, Exception>> getGoalsNearingCompletion(
    int profileId,
  ) async {
    try {
      final goalsResult = await getGoals(profileId, isActive: true, isCompleted: false);
      if (goalsResult.isFailure) return Failure(goalsResult.failureData!);
      
      final goals = goalsResult.successData!;
      final nearingCompletion = goals.where((g) => g.completionPercentage >= 80).toList();
      
      return Success(nearingCompletion);
    } catch (e) {
      return Failure(Exception('Failed to get goals nearing completion: $e'));
    }
  }

  @override
  Future<Result<List<domain.Goal>, Exception>> getOverdueGoals(int profileId) async {
    try {
      final goalsResult = await getGoals(profileId, isActive: true, isCompleted: false);
      if (goalsResult.isFailure) return Failure(goalsResult.failureData!);
      
      final goals = goalsResult.successData!;
      final overdue = goals.where((g) => g.isOverdue).toList();
      
      return Success(overdue);
    } catch (e) {
      return Failure(Exception('Failed to get overdue goals: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> linkTransactionToGoal(
    int transactionId,
    int goalId,
  ) async {
    try {
      await _goalsDao.linkTransactionToGoal(transactionId, goalId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to link transaction to goal: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> unlinkTransactionFromGoal(
    int transactionId,
    int goalId,
  ) async {
    try {
      await _goalsDao.unlinkTransactionFromGoal(transactionId, goalId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to unlink transaction from goal: $e'));
    }
  }
}
