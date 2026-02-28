import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/usecase_providers.dart';
import '../../domain/entities/budget.dart';
import '../../domain/core/result.dart';
import 'profile_providers.dart';

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
    final profileAsync = ref.read(activeProfileProvider);
    final profile = profileAsync.value;
    if (profile == null) return [];

    final getBudgets = ref.read(getBudgetsUseCaseProvider);
    final getUsage = ref.read(getBudgetUsageUseCaseProvider);
    
    // Use current month if not specified
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    final result = await getBudgets(
      profile.id,
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
    final profileAsync = ref.read(activeProfileProvider);
    final profile = profileAsync.value;
    if (profile == null) throw Exception('No active profile');

    final createUseCase = ref.read(createBudgetUseCaseProvider);
    final result = await createUseCase(budget.copyWith(profileId: profile.id));
    
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

/// Provider for the total budget summary for the current month
final totalBudgetSummaryProvider = FutureProvider<BudgetUsage>((ref) async {
  final profileAsync = ref.watch(activeProfileProvider);
  final profile = profileAsync.value;
  if (profile == null) throw Exception('No active profile');

  final useCase = ref.watch(getTotalBudgetSummaryUseCaseProvider);
  final result = await useCase(profile.id, DateTime.now().month, DateTime.now().year);
  
  return result.when(
    success: (usage) => usage,
    failure: (e) => throw e,
  );
});

/// Provider for budget alerts (e.g., when a transaction triggers over-budget)
final budgetAlertProvider = StateProvider<BudgetUsage?>((ref) => null);
