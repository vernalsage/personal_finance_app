import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_budget_screen.dart';
import '../../providers/budget_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../main.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
              );
            },
          ),
        ],
      ),
      body: budgetsAsync.when(
        data: (budgets) => budgets.isEmpty
            ? _buildEmptyState(context, ref)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final item = budgets[index];
                  return _BudgetCard(item: item);
                },
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => ErrorDisplayWidget(
          error: err.toString(),
          onRetry: () => ref.invalidate(budgetsProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: kTextSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No budgets found for this month',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
              );
            },
            child: const Text('Create a Budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final dynamic item; // BudgetWithUsage

  const _BudgetCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final budget = item.budget;
    final usage = item.usage;
    
    final spent = CurrencyUtils.formatMinorToDisplay(usage.spentAmountMinor, 'NGN');
    final limit = CurrencyUtils.formatMinorToDisplay(usage.budgetAmountMinor, 'NGN');
    final percent = usage.usagePercentage / 100.0;
    
    final progressColor = usage.isOverBudget 
        ? kError 
        : (usage.isNearLimit ? kWarning : kPrimary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category ID: ${budget.categoryId}', // TODO: Resolve category name
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$spent / $limit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                backgroundColor: kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(usage.usagePercentage).toStringAsFixed(1)}% used',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (usage.isOverBudget)
                  Text(
                    'Over budget',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kError),
                  )
                else
                  Text(
                    '${CurrencyUtils.formatMinorToDisplay(usage.remainingAmountMinor, 'NGN')} left',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
