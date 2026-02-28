import 'package:flutter/material.dart';
import '../../../domain/models/budget_overview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/insight_providers.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/budget_providers.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/style/app_colors.dart';
import '../../../main.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(financialOverviewProvider.notifier).loadFinancialOverview(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final breakdownAsync = ref.watch(expenseBreakdownProvider((start: _startDate, end: _endDate)));
    final weeklySpendingAsync = ref.watch(weeklySpendingProvider);
    final overviewState = ref.watch(financialOverviewProvider);
    final overviewAsync = ref.watch(budgetOverviewProvider);
    final profileAsync = ref.watch(activeProfileProvider);
    final currency = profileAsync.value?.currency ?? 'NGN';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(overviewState, currency),
                  const SizedBox(height: 24),
                  
                  Text('Budget vs Actual', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  overviewAsync.when(
                    data: (overview) => _buildBudgetComparison(overview, currency),
                    loading: () => const SizedBox(height: 100, child: LoadingWidget()),
                    error: (e, __) => Text('Error loading budget summary: $e'),
                  ),
                  
                  const SizedBox(height: 24),
                  Text('Expense Breakdown', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildCategoryBreakdown(breakdownAsync, currency),
                  
                  const SizedBox(height: 24),
                  Text('Weekly Spending', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildWeeklyChart(weeklySpendingAsync),
                  
                  const SizedBox(height: 120), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FinancialOverviewState state, String currency) {
    final overview = state.overview;
    final expenses = overview != null 
        ? CurrencyUtils.formatMinorToDisplay(overview.totalExpenses, currency)
        : '...';
    final income = overview != null
        ? CurrencyUtils.formatMinorToDisplay(overview.totalIncome, currency)
        : '...';

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Expenses',
            value: expenses,
            color: AppColors.error,
            icon: Icons.trending_down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Total Income',
            value: income,
            color: AppColors.success,
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetComparison(BudgetOverview overview, String currency) {
    final percent = overview.totalPercentUsed;
    final isOver = overview.totalSpentMinor > overview.totalBudgetedMinor;
    final color = isOver ? AppColors.error : (percent > 0.8 ? AppColors.warning : AppColors.primary);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(Theme.of(context).brightness == Brightness.dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(Theme.of(context).brightness == Brightness.dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('Current Month', style: TextStyle(fontWeight: FontWeight.w500)),
               Text('${(percent * 100).toStringAsFixed(1)}%', 
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: AppColors.border(Theme.of(context).brightness == Brightness.dark),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyUtils.formatMinorToDisplay(overview.totalSpentMinor, currency)}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark)),
              ),
              Text(
                'Budget: ${CurrencyUtils.formatMinorToDisplay(overview.totalBudgetedMinor, currency)}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(AsyncValue<Map<String, int>> breakdownAsync, String currency) {
    return breakdownAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('No data for this period'));
        }
        
        final total = data.values.fold(0, (sum, val) => sum + val);
        final sections = _getPieSections(data, total);

        return Column(
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...data.entries.map((e) => _CategoryLegendItem(
                  label: e.key,
                  amount: e.value,
                  percent: (e.value / total * 100).toStringAsFixed(1),
                  color: _getCategoryColor(e.key),
                  currency: currency,
                )),
          ],
        );
      },
      loading: () => const SizedBox(height: 200, child: LoadingWidget()),
      error: (err, _) => ErrorDisplayWidget(error: err.toString()),
    );
  }

  List<PieChartSectionData> _getPieSections(Map<String, int> data, int total) {
    return data.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildWeeklyChart(AsyncValue<List<int>> weeklyAsync) {
    return weeklyAsync.when(
      data: (data) => AspectRatio(
        aspectRatio: 1.7,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value / 100.0,
                    color: AppColors.primary,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      loading: () => const SizedBox(height: 150, child: LoadingWidget()),
      error: (err, _) => ErrorDisplayWidget(error: err.toString()),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      AppColors.primary,
      AppColors.primaryBg,
      AppColors.warning,
      AppColors.error,
      AppColors.success,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
    ];
    return colors[category.hashCode % colors.length];
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(Theme.of(context).brightness == Brightness.dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(Theme.of(context).brightness == Brightness.dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary(Theme.of(context).brightness == Brightness.dark),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegendItem extends StatelessWidget {
  final String label;
  final int amount;
  final String percent;
  final Color color;
  final String currency;

  const _CategoryLegendItem({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = CurrencyUtils.formatMinorToDisplay(amount, currency);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text('$percent%', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          Text(formattedAmount, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
