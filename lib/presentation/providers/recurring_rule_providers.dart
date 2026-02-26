import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/usecase_providers.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/core/result.dart';

/// Provider for managing the list of recurring rules
final recurringRulesProvider = AsyncNotifierProvider<RecurringRulesNotifier, List<RecurringRule>>(
  RecurringRulesNotifier.new,
);

class RecurringRulesNotifier extends AsyncNotifier<List<RecurringRule>> {
  @override
  Future<List<RecurringRule>> build() async {
    return _fetchRules();
  }

  Future<List<RecurringRule>> _fetchRules({bool? isActive}) async {
    final getRules = ref.read(getRecurringRulesUseCaseProvider);
    
    final result = await getRules(
      1, // Default profile for MVP
      isActive: isActive,
    );

    if (result.isFailure) {
      throw result.failureData!;
    }

    return result.successData!;
  }

  Future<void> refreshRules({bool? isActive}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchRules(isActive: isActive));
  }

  Future<int> processDueRules() async {
    final processUseCase = ref.read(processDueRulesUseCaseProvider);
    final result = await processUseCase(1); // Default profile
    
    if (result.isSuccess) {
      ref.invalidateSelf();
      return result.successData!;
    } else {
      throw result.failureData!;
    }
  }

  Future<void> createRule(RecurringRule rule) async {
    final createUseCase = ref.read(createRecurringRuleUseCaseProvider);
    final result = await createUseCase(rule);
    
    if (result.isSuccess) {
      ref.invalidateSelf();
    } else {
      throw result.failureData!;
    }
  }

  Future<void> deleteRule(int ruleId) async {
    final deleteUseCase = ref.read(deleteRecurringRuleUseCaseProvider);
    final result = await deleteUseCase(ruleId);
    
    if (result.isSuccess) {
      ref.invalidateSelf();
    } else {
      throw result.failureData!;
    }
  }
}
