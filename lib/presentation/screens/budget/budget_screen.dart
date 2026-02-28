import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_providers.dart';
import '../../providers/profile_providers.dart';
import '../../../domain/models/budget_overview.dart';
import '../../../domain/services/budget_insights_engine.dart';
import '../../providers/category_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/style/app_colors.dart';
import '../../../main.dart';
import 'add_budget_screen.dart';
import '../../../domain/entities/budget.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final overviewAsync = ref.watch(budgetOverviewProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: const Text('Budget Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: 'Manage Budgets',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(budgetOverviewProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              overviewAsync.when(
                data: (overview) => _buildSummaryCard(context, ref, overview, profile?.currency ?? 'NGN'),
                loading: () => const LoadingWidget(),
                error: (e, __) => ErrorDisplayWidget(error: e.toString()),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Category Budgets'),
              const SizedBox(height: 12),
              overviewAsync.when(
                data: (overview) => Column(
                  children: overview.categoryStatuses
                      .map((status) => _BudgetListItem(status: status, currency: profile?.currency ?? 'NGN'))
                      .toList(),
                ),
                loading: () => const LoadingWidget(),
                error: (e, __) => ErrorDisplayWidget(error: e.toString()),
              ),
              const SizedBox(height: 24),
              overviewAsync.when(
                data: (overview) => _buildSpendingTips(context, overview),
                loading: () => const SizedBox.shrink(),
                error: (e, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        loading: () => const LoadingWidget(),
        error: (e, __) => ErrorDisplayWidget(error: e.toString()),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, BudgetOverview overview, String currency) {
    final spent = CurrencyUtils.formatMinorToDisplay(overview.totalSpentMinor, currency);
    final limit = CurrencyUtils.formatMinorToDisplay(overview.totalBudgetedMinor, currency);
    final percent = overview.totalPercentUsed;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
            '${(percent * 100).toStringAsFixed(1)}% of your budget spent',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }


  Widget _buildSpendingTips(BuildContext context, BudgetOverview overview) {
    final insight = BudgetInsightsEngine.getSummaryInsight(overview, DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                fontSize: 14, 
                color: AppColors.textPrimary(Theme.of(context).brightness == Brightness.dark),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetListItem extends ConsumerWidget {
  final CategoryBudgetStatus status;
  final String currency;

  const _BudgetListItem({required this.status, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spent = CurrencyUtils.formatMinorToDisplay(status.spentAmountMinor, currency);
    final limit = CurrencyUtils.formatMinorToDisplay(status.budgetAmountMinor, currency);
    final percent = status.percentUsed;
    
    final progressColor = status.isOverBudget 
        ? AppColors.error 
        : (percent > 0.8 ? AppColors.warning : AppColors.primary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddBudgetScreen(
                categoryId: status.categoryId,
                existingAmountMinor: status.budgetAmountMinor,
                month: status.month,
                year: status.year,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card(Theme.of(context).brightness == Brightness.dark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(Theme.of(context).brightness == Brightness.dark)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _getCategoryIcon(status.categoryIcon, status.categoryColor),
                      const SizedBox(width: 8),
                      Text(
                        status.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
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
                  backgroundColor: AppColors.border(Theme.of(context).brightness == Brightness.dark).withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String iconName, String colorHex) {
    Color color;
    try {
      final hex = colorHex.replaceAll('#', '');
      color = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      color = AppColors.primary;
    }

    IconData iconData;
    switch (iconName.toLowerCase()) {
      case 'shopping_cart': iconData = Icons.shopping_cart_outlined; break;
      case 'restaurant': iconData = Icons.restaurant_outlined; break;
      case 'directions_car': iconData = Icons.directions_car_outlined; break;
      case 'home': iconData = Icons.home_outlined; break;
      case 'payments': iconData = Icons.payments_outlined; break;
      case 'receipt': iconData = Icons.receipt_outlined; break;
      case 'bolt': iconData = Icons.bolt_outlined; break;
      case 'coffee': iconData = Icons.coffee_outlined; break;
      case 'phone_iphone': iconData = Icons.phone_iphone_outlined; break;
      default: iconData = Icons.receipt_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 16),
    );
  }
}
