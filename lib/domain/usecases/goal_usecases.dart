import '../entities/goal.dart';
import '../repositories/goal_repository.dart';
import '../core/result.dart';

/// Use case to get all goals for a profile
class GetGoalsUseCase {
  final GoalRepository _repository;

  GetGoalsUseCase(this._repository);

  Future<Result<List<Goal>, Exception>> call(
    int profileId, {
    bool? isActive,
    bool? isCompleted,
  }) {
    return _repository.getGoals(
      profileId,
      isActive: isActive,
      isCompleted: isCompleted,
    );
  }
}

/// Use case to create a new goal
class CreateGoalUseCase {
  final GoalRepository _repository;

  CreateGoalUseCase(this._repository);

  Future<Result<Goal, Exception>> call(Goal goal) {
    return _repository.createGoal(goal);
  }
}

/// Use case to update an existing goal
class UpdateGoalUseCase {
  final GoalRepository _repository;

  UpdateGoalUseCase(this._repository);

  Future<Result<Goal, Exception>> call(Goal goal) {
    return _repository.updateGoal(goal);
  }
}

/// Use case to delete a goal
class DeleteGoalUseCase {
  final GoalRepository _repository;

  DeleteGoalUseCase(this._repository);

  Future<Result<void, Exception>> call(int goalId) {
    return _repository.deleteGoal(goalId);
  }
}

/// Use case to get goals nearing completion
class GetGoalsNearingCompletionUseCase {
  final GoalRepository _repository;

  GetGoalsNearingCompletionUseCase(this._repository);

  Future<Result<List<Goal>, Exception>> call(int profileId) {
    return _repository.getGoalsNearingCompletion(profileId);
  }
}
