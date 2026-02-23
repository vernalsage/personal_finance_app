import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_providers.dart';
import '../providers/transaction_providers.dart';
import '../../../core/utils/monetary_utils.dart';

/// Dashboard page showing financial overview
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load data when page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Get active profile ID
      const profileId = 1; // Placeholder

      ref
          .read(financialOverviewProvider.notifier)
          .loadFinancialOverview(profileId);
      ref.read(cashRunwayProvider.notifier).calculateCashRunway(profileId);
      ref
          .read(transactionsProvider.notifier)
          .loadTransactionsRequiringReview(profileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final financialOverviewState = ref.watch(financialOverviewProvider);
    final cashRunwayState = ref.watch(cashRunwayProvider);
    final transactionsState = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Overview Section
            _buildFinancialOverview(context, financialOverviewState),
            const SizedBox(height: 24),

            // Cash Runway Section
            _buildCashRunway(context, cashRunwayState),
            const SizedBox(height: 24),

            // Transactions Requiring Review Section
            _buildTransactionsRequiringReview(context, transactionsState),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(
    BuildContext context,
    FinancialOverviewState state,
  ) {
    if (state.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: ${state.error}'),
        ),
      );
    }

    final overview = state.overview;
    if (overview == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No financial data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Total Balance',
                    MonetaryUtils.formatCurrency(overview.totalBalance),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Monthly Income',
                    MonetaryUtils.formatCurrency(overview.totalIncome),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Monthly Expenses',
                    MonetaryUtils.formatCurrency(overview.totalExpenses),
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Net Income',
                    MonetaryUtils.formatCurrency(overview.netIncome),
                    overview.netIncome >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashRunway(BuildContext context, CashRunwayState state) {
    if (state.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: ${state.error}'),
        ),
      );
    }

    final cashRunway = state.cashRunway;
    if (cashRunway == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No cash runway data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Runway',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              '${cashRunway.runwayDays} days',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: cashRunway.runwayDays > 30
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on average monthly expenses of ${MonetaryUtils.formatCurrency(cashRunway.averageMonthlyExpenses)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsRequiringReview(
    BuildContext context,
    TransactionsState state,
  ) {
    if (state.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: ${state.error}'),
        ),
      );
    }

    final transactions = state.transactions;
    if (transactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No transactions require review'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transactions Requiring Review (${transactions.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...transactions.map(
              (transaction) => ListTile(
                title: Text(transaction.description),
                subtitle: Text(
                  MonetaryUtils.formatCurrency(transaction.amountMinor),
                ),
                trailing: Text('Confidence: ${transaction.confidenceScore}%'),
                onTap: () {
                  // TODO: Navigate to transaction details
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
