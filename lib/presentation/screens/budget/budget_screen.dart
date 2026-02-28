import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/category_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../main.dart';
import '../budgets/add_budget_screen.dart';
import '../../../domain/entities/budget.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final summaryAsync = ref.watch(totalBudgetSummaryProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Budget Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(totalBudgetSummaryProvider);
            ref.invalidate(budgetsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, ref, summaryAsync, profile?.currency ?? 'NGN'),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Category Budgets'),
              const SizedBox(height: 12),
              _buildCategoryBudgets(context, ref, profile?.currency ?? 'NGN'),
              const SizedBox(height: 24),
              _buildSpendingTips(context),
            ],
          ),
        ),
        loading: () => const LoadingWidget(),
        error: (e, __) => ErrorDisplayWidget(error: e.toString()),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, AsyncValue<BudgetUsage> summaryAsync, String currency) {
    return summaryAsync.when(
      data: (usage) {
        final spent = CurrencyUtils.formatMinorToDisplay(usage.spentAmountMinor, currency);
        final limit = CurrencyUtils.formatMinorToDisplay(usage.budgetAmountMinor, currency);
        final percent = usage.usagePercentage / 100.0;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, kPrimary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Monthly Budget',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '$spent / $limit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(usage.usagePercentage).toStringAsFixed(1)}% of your budget spent',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 160,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: kPrimary)),
      ),
      error: (e, __) => Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kError.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('Error loading summary: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCategoryBudgets(BuildContext context, WidgetRef ref, String currency) {
    final budgetsAsync = ref.watch(budgetsProvider);
    
    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No category budgets set for this month.', style: TextStyle(color: kTextSecondary)),
            ),
          );
        }
        return Column(
          children: budgets.map((item) => _BudgetListItem(item: item, currency: currency)).toList(),
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, __) => ErrorDisplayWidget(error: e.toString()),
    );
  }

  Widget _buildSpendingTips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: kPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'Spending Insight',
                style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep an eye on your variable expenses. You\'ve spent 60% of your Dining budget halfway through the month.',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _BudgetListItem extends ConsumerWidget {
  final BudgetWithUsage item;
  final String currency;

  const _BudgetListItem({required this.item, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = item.usage;
    final spent = CurrencyUtils.formatMinorToDisplay(usage.spentAmountMinor, currency);
    final limit = CurrencyUtils.formatMinorToDisplay(usage.budgetAmountMinor, currency);
    final percent = usage.usagePercentage / 100.0;
    
    final progressColor = usage.isOverBudget 
        ? kError 
        : (usage.isNearLimit ? kWarning : kPrimary);

    // Get category name
    final categoriesAsync = ref.watch(categoriesProvider);
    final categoryName = categoriesAsync.when(
      data: (cats) {
        final cat = cats.where((c) => c.id == item.budget.categoryId).firstOrNull;
        return cat?.name ?? 'Category ${item.budget.categoryId}';
      },
      loading: () => 'Loading...',
      error: (_, __) => 'Category ${item.budget.categoryId}',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$spent / $limit',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                backgroundColor: kBorder.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
