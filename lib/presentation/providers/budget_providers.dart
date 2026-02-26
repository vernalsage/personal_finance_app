import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/usecase_providers.dart';
import '../../domain/entities/budget.dart';
import '../../domain/core/result.dart';

/// Provider for managing the list of budgets with their usage
final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<BudgetWithUsage>>(
  BudgetsNotifier.new,
);

class BudgetsNotifier extends AsyncNotifier<List<BudgetWithUsage>> {
  @override
  Future<List<BudgetWithUsage>> build() async {
    return _fetchBudgets();
  }

  Future<List<BudgetWithUsage>> _fetchBudgets({int? month, int? year}) async {
    final getBudgets = ref.read(getBudgetsUseCaseProvider);
    final getUsage = ref.read(getBudgetUsageUseCaseProvider);
    
    // Use current month if not specified
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    final result = await getBudgets(
      1, // Default profile for MVP
      month: targetMonth,
      year: targetYear,
    );

    if (result.isFailure) {
      throw result.failureData!;
    }

    final budgets = result.successData!;
    final budgetsWithUsage = <BudgetWithUsage>[];

    for (final budget in budgets) {
      final usageResult = await getUsage(budget.id);
      if (usageResult.isSuccess) {
        budgetsWithUsage.add(BudgetWithUsage(
          budget: budget,
          usage: usageResult.successData!,
        ));
      }
    }

    return budgetsWithUsage;
  }

  Future<void> refreshBudgets({int? month, int? year}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBudgets(month: month, year: year));
  }

  Future<void> createBudget(Budget budget) async {
    final createUseCase = ref.read(createBudgetUseCaseProvider);
    final result = await createUseCase(budget);
    
    if (result.isSuccess) {
      ref.invalidateSelf();
    } else {
      throw result.failureData!;
    }
  }

  Future<void> deleteBudget(int budgetId) async {
    final deleteUseCase = ref.read(deleteBudgetUseCaseProvider);
    final result = await deleteUseCase(budgetId);
    
    if (result.isSuccess) {
      ref.invalidateSelf();
    } else {
      throw result.failureData!;
    }
  }
}
