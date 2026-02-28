import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../domain/models/budget_overview.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget.dart';
import '../../application/services/hybrid_currency_service.dart';
import '../../core/di/repository_providers.dart';
import '../../core/di/usecase_providers.dart';
import 'transaction_providers.dart';
import 'profile_providers.dart';

/// Notifier for managing budgeting state
class BudgetNotifier extends StateNotifier<AsyncValue<BudgetOverview>> {
  BudgetNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final profileAsync = _ref.read(activeProfileProvider);
      final profile = profileAsync.value;
      if (profile == null) {
        state = const AsyncValue.data(BudgetOverview(
          categoryStatuses: [],
          totalBudgetedMinor: 0,
          totalSpentMinor: 0,
          month: 1,
          year: 2026,
        ));
        return;
      }

      final now = DateTime.now();
      final month = now.month;
      final year = now.year;

      final budgetRepo = _ref.read(budgetRepositoryProvider);
      
      // 1. Get all budgets for the month
      final budgetsResult = await budgetRepo.getBudgets(
        profile.id,
        month: month,
        year: year,
      );

      // 2. Get all transactions for the month
      final transactionsState = _ref.read(transactionsProvider);
      final currentMonthTransactions = transactionsState.transactions.where((t) =>
          t.transaction.timestamp.month == month &&
          t.transaction.timestamp.year == year &&
          t.transaction.type == 'debit' &&
          t.transaction.categoryId != null);

      // 3. Get all categories for the profile to ensure names/icons are available
      final categoryRepo = _ref.read(categoryRepositoryProvider);
      final categoriesResult = await categoryRepo.getCategories(profile.id);
      final categoriesMap = {
        if (categoriesResult.isSuccess)
          for (final c in categoriesResult.successData!) c.id: c
      };

      final List<CategoryBudgetStatus> statuses = [];
      int totalBudgeted = 0;
      int totalSpentNormalized = 0;

      if (budgetsResult.isSuccess) {
        final budgets = budgetsResult.successData!;
        
        // Group transactions by category
        final groupedTxs = groupBy(currentMonthTransactions, (t) => t.transaction.categoryId!);

        for (final budget in budgets) {
          final txs = groupedTxs[budget.categoryId] ?? [];
          final category = categoriesMap[budget.categoryId];
          
          int categorySpentNormalized = 0;
          for (final txDetails in txs) {
            final tx = txDetails.transaction;
            final account = txDetails.account;
            
            if (account != null && account.currency != profile.currency) {
              // Normalize to base currency
              final normalized = await HybridCurrencyService.convertCurrency(
                amount: tx.amountMinor.abs().toDouble() / 100.0,
                fromCurrency: account.currency,
                toCurrency: profile.currency,
              );
              categorySpentNormalized += (normalized * 100).round();
            } else {
              categorySpentNormalized += tx.amountMinor.abs();
            }
          }

          statuses.add(CategoryBudgetStatus(
            categoryId: budget.categoryId,
            categoryName: category?.name ?? 'Category ${budget.categoryId}',
            categoryColor: category?.color ?? '#9E9E9E',
            categoryIcon: category?.icon ?? 'receipt',
            budgetAmountMinor: budget.amountMinor,
            spentAmountMinor: categorySpentNormalized,
            month: month,
            year: year,
          ));

          totalBudgeted += budget.amountMinor;
          totalSpentNormalized += categorySpentNormalized;
        }
      }

      state = AsyncValue.data(BudgetOverview(
        categoryStatuses: statuses,
        totalBudgetedMinor: totalBudgeted,
        totalSpentMinor: totalSpentNormalized,
        month: month,
        year: year,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createBudget(Budget budget) async {
    final repository = _ref.read(budgetRepositoryProvider);
    final result = await repository.createBudget(budget);
    if (result.isSuccess) {
      await refresh();
    } else {
      throw result.failureData!;
    }
  }

  Future<void> updateBudget(Budget budget) async {
    final repository = _ref.read(budgetRepositoryProvider);
    final result = await repository.updateBudget(budget);
    if (result.isSuccess) {
      await refresh();
    } else {
      throw result.failureData!;
    }
  }

  Future<void> deleteBudget(int budgetId) async {
    final repository = _ref.read(budgetRepositoryProvider);
    final result = await repository.deleteBudget(budgetId);
    if (result.isSuccess) {
      await refresh();
    } else {
      throw result.failureData!;
    }
  }
}

final budgetOverviewProvider = 
    StateNotifierProvider<BudgetNotifier, AsyncValue<BudgetOverview>>((ref) {
  // Watch active profile to trigger refresh on user change
  ref.watch(activeProfileProvider);
  return BudgetNotifier(ref);
});
