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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final financialOverviewState = ref.watch(financialOverviewProvider);
    final cashRunwayState = ref.watch(cashRunwayProvider);
    final transactionsState = ref.watch(transactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {},
          ),
          const CircleAvatar(
            backgroundColor: Color(0xFF0D5C58), // Teal color from mockup
            radius: 16,
            child: Text(
              'D',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              '${_getGreeting()}, Deolu',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s your financial snapshot for today.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Metrics Cards
            _buildTotalBalanceCard(financialOverviewState, theme),
            const SizedBox(height: 16),

            _buildCashRunwayCard(cashRunwayState, theme),
            const SizedBox(height: 16),

            _buildStabilityScoreCard(theme), // Static MVP placeholder
            const SizedBox(height: 16),

            _buildNeedsReviewCard(transactionsState, theme),
            const SizedBox(height: 32),

            // Recent Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: Color(0xFF0D5C58),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentTransactionsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(dynamic state, ThemeData theme) {
    if (state.isLoading) return _buildLoadingCard(theme);

    final overview = state.overview;
    final balance = overview != null
        ? MonetaryUtils.formatCurrency(overview.totalBalance)
        : '₦0.00';

    return _buildCustomMetricCard(
      theme: theme,
      title: 'TOTAL BALANCE',
      value: balance,
      subtitle: 'Across active accounts',
      iconData: Icons.account_balance_wallet_outlined,
      iconColor: Colors.white,
      iconBgColor: const Color(0xFF0D5C58),
    );
  }

  Widget _buildCashRunwayCard(dynamic state, ThemeData theme) {
    if (state.isLoading) return _buildLoadingCard(theme);

    final runway = state.cashRunway;
    final days = runway != null ? '${runway.runwayDays} days' : '-- days';
    final liquid = runway != null
        ? 'Liquid: ${MonetaryUtils.formatCurrency(runway.liquidBalance ?? 0)}'
        : 'Awaiting data';

    return _buildCustomMetricCard(
      theme: theme,
      title: 'CASH RUNWAY',
      value: days,
      subtitle: liquid,
      iconData: Icons.trending_up,
      iconColor: const Color(0xFF0D5C58),
      iconBgColor: const Color(0xFFE8F3F1),
    );
  }

  Widget _buildStabilityScoreCard(ThemeData theme) {
    // Placeholder for future Stability Score MVP feature
    return _buildCustomMetricCard(
      theme: theme,
      title: 'STABILITY SCORE',
      value: '72/100',
      subtitle: 'Good standing',
      iconData: Icons.security_outlined,
      iconColor: const Color(0xFF2E7D32),
      iconBgColor: const Color(0xFFE8F5E9),
    );
  }

  Widget _buildNeedsReviewCard(dynamic state, ThemeData theme) {
    if (state.isLoading) return _buildLoadingCard(theme);

    final transactions = state.transactions ?? [];
    final count = transactions.length.toString();

    return _buildCustomMetricCard(
      theme: theme,
      title: 'NEEDS REVIEW',
      value: count,
      subtitle: 'Low confidence transactions',
      iconData: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFED6C02),
      iconBgColor: const Color(0xFFFFF4E5),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCustomMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subtitle,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList(ThemeData theme) {
    // Static placeholder mapping the "TechCorp Ltd" visual from the sample
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: const Text('💰'),
        ),
        title: const Text(
          'TechCorp Ltd',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Salary · 24 Feb'),
        trailing: Text(
          '↘ ₦950,000',
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF2E7D32), // Green credit
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
