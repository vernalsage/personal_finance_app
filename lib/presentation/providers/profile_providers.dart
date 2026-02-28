import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/core/result.dart';
import '../../core/di/repository_providers.dart';
import '../../application/services/hybrid_currency_service.dart';
import '../../domain/repositories/budget_repository.dart';
import 'analytics_providers.dart';
import 'budget_providers.dart';
import '../../core/di/usecase_providers.dart';

/// Notifier for the active user profile
class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  FutureOr<Profile?> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    // Profile ID 1 is the default for this app
    final result = await repository.getProfileById(1);
    return result.when(
      success: (profile) => profile,
      failure: (_) => null,
    );
  }

  /// Update the base currency for the profile
  Future<void> updateCurrency(String currency) async {
    final current = state.value;
    if (current == null) return;
    if (current.currency == currency) return;

    final oldCurrency = current.currency;
    
    // We don't set state to loading directly with previous data lost
    // Instead, we can keep the current data and just perform the work
    // Or use copyWithPrevious if we want to show a loading indicator in UI
    final previousState = state;
    state = const AsyncValue<Profile?>.loading();
    
    try {
      // 1. Get conversion rate
      double rate;
      try {
        rate = await HybridCurrencyService.convertCurrency(
          amount: 1.0,
          fromCurrency: oldCurrency,
          toCurrency: currency,
        );
      } catch (e) {
        debugPrint('🚨 Currency conversion failed: $e. Using 1:1 fallback.');
        rate = 1.0;
      }

      // 2. Convert existing budgets
      final convertResult = await ref.read(budgetRepositoryProvider).convertBudgets(current.id, rate);
      if (convertResult.isFailure) {
        debugPrint('🚨 Budget conversion failed: ${convertResult.failureData}');
      }

      // 3. Update profile
      final updated = Profile(
        id: current.id,
        name: current.name,
        currency: currency,
        email: current.email,
      );

      final result = await ref.read(profileRepositoryProvider).updateProfile(updated);
      
      await result.when(
        success: (profile) async {
          state = AsyncValue.data(profile);
          
          // 4. Invalidate related providers
          ref.invalidate(getFinancialOverviewUseCaseProvider);
          ref.invalidate(financialOverviewProvider);
          ref.invalidate(totalBudgetSummaryProvider);
          ref.invalidate(budgetsProvider);
          ref.invalidate(cashRunwayProvider);
          ref.invalidate(stabilityScoreProvider);
        },
        failure: (e) {
          // If profile update fails, we revert to previous state and show error elsewhere if possible
          // For now, setting error state so UI knows something went wrong
          state = AsyncValue.error(e, StackTrace.current);
        },
      );
    } catch (e, st) {
      debugPrint('🚨 Error in updateCurrency: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the active profile
final activeProfileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(() {
  return ProfileNotifier();
});
