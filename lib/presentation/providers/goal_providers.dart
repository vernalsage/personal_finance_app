import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/usecase_providers.dart';
import '../../domain/entities/goal.dart';
import '../../domain/core/result.dart';

/// Provider for managing the list of goals
final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<Goal>>(
  GoalsNotifier.new,
);

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    return _fetchGoals();
  }

  Future<List<Goal>> _fetchGoals({bool? isActive}) async {
    final getGoals = ref.read(getGoalsUseCaseProvider);
    
    final result = await getGoals(
      1, // Default profile for MVP
      isActive: isActive,
    );

    if (result.isFailure) {
      throw result.failureData!;
    }

    return result.successData!;
  }

  Future<void> refreshGoals({bool? isActive}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGoals(isActive: isActive));
  }

  Future<void> createGoal(Goal goal) async {
    final createUseCase = ref.read(createGoalUseCaseProvider);
    final result = await createUseCase(goal);
    
    if (result.isSuccess) {
      ref.invalidateSelf();
    } else {
      throw result.failureData!;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    final updateUseCase = ref.read(updateGoalUseCaseProvider);
    final result = await updateUseCase(goal);
    
    if (result.isSuccess) {
      ref.invalidateSelf();
    } else {
      throw result.failureData!;
    }
  }

  Future<void> deleteGoal(int goalId) async {
    final deleteUseCase = ref.read(deleteGoalUseCaseProvider);
    final result = await deleteUseCase(goalId);
    
    if (result.isSuccess) {
      ref.invalidateSelf();
    } else {
      throw result.failureData!;
    }
  }
}
