import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../../application/services/hybrid_currency_service.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transaction_with_details.dart';
import '../../../domain/entities/account.dart';
import '../../../core/style/app_colors.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';
import '../transaction/add_transaction_screen.dart';
import '../transfer/transfer_screen.dart';
import '../transactions/transactions_screen.dart';
import '../../providers/analytics_providers.dart';
import '../recurring/recurring_rules_screen.dart';
import '../../providers/profile_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<double>? _totalBalanceFuture;
  bool _balanceVisible = true;
  List<Account>? _lastAccounts;
  String? _lastTargetCurrency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      await Future.wait<dynamic>([
        ref.read(accountsProvider.notifier).loadAccounts(1),
        ref.read(transactionsProvider.notifier).loadTransactions(1, limit: 10),
        ref.read(cashRunwayProvider.notifier).calculateCashRunway(1),
        ref.read(stabilityScoreProvider.notifier).calculateStabilityScore(1),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  Future<double> _calculateTotalBalance(dynamic accounts, String targetCurrency) async {
    double total = 0.0;
    for (final account in accounts) {
      final converted = await HybridCurrencyService.convertCurrency(
        amount: account.balanceMinor / 100.0,
        fromCurrency: account.currency,
        toCurrency: targetCurrency,
      );
      total += converted;
    }
    return total;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Deolu';
    if (hour < 17) return 'Good afternoon, Deolu';
    return 'Good evening, Deolu';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);
    final profile = profileAsync.value;
    final targetCurrency = profile?.currency ?? 'USD';

    final accountsState = ref.watch(accountsProvider);
    final transactionsState = ref.watch(transactionsProvider);

    // Watch for currency changes specifically to reload data
    ref.listen(activeProfileProvider, (previous, next) {
      if (previous?.value?.currency != next.value?.currency) {
        _loadData();
      }
    });

    // Recalculate if accounts list actually changed OR currency changed
    if (_lastAccounts != accountsState.accounts || _lastTargetCurrency != targetCurrency) {
      _lastAccounts = accountsState.accounts;
      _lastTargetCurrency = targetCurrency;
      _totalBalanceFuture = _calculateTotalBalance(accountsState.accounts, targetCurrency);
    }

    final reviewTransactions =
        transactionsState.transactions.where((t) => t.transaction.requiresReview).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ────────────────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 16),

                // ─── Balance Card ──────────────────────────────────────────
                _buildBalanceCard(targetCurrency),
                const SizedBox(height: 12),

                // ─── Metric Chips Row ──────────────────────────────────────
                _buildMetricRow(accountsState),
                const SizedBox(height: 12),

                // ─── Needs Review Banner ───────────────────────────────────
                if (reviewTransactions.isNotEmpty) ...[
                  _buildReviewBanner(reviewTransactions.length),
                  const SizedBox(height: 12),
                ],

                // ─── Recent Transactions ───────────────────────────────────
                _buildRecentTransactionsSection(transactionsState, accountsState),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(accountsState),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary(isDark),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        // Recurring
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecurringRulesScreen()),
          ),
          icon: Icon(Icons.sync_outlined, color: AppColors.textSecondary(isDark), size: 22),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.card(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppColors.border(isDark)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Bell
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_outlined,
              color: AppColors.textSecondary(isDark), size: 22),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.card(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppColors.border(isDark)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(String targetCurrency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF19AEA7), Color(0xFF0D8A84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                child: Icon(
                  _balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<double>(
            future: _totalBalanceFuture,
            builder: (context, snapshot) {
              String balance = 'Loading...';
              if (snapshot.hasData) {
                balance = CurrencyUtils.formatMinorToDisplay(
                  (snapshot.data! * 100).round(),
                  targetCurrency,
                );
              } else if (snapshot.hasError) {
                balance = 'Error loading balance';
              }
              final symbol = CurrencyUtils.getCurrencySymbol(targetCurrency);
              return Text(
                _balanceVisible ? balance : '$symbol ••••••',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                '+2.5% from last month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(dynamic accountsState) {
    final runwayState = ref.watch(cashRunwayProvider);
    final stabilityState = ref.watch(stabilityScoreProvider);

    final runwayValue = runwayState.isLoading 
        ? '...' 
        : runwayState.cashRunway != null 
            ? '${(runwayState.cashRunway!.runwayDays / 30).toStringAsFixed(1)} Mo'
            : 'N/A';
            
    final stabilityValue = stabilityState.isLoading
        ? '...'
        : stabilityState.stabilityScore != null
            ? '${stabilityState.stabilityScore!.score}/100'
            : 'N/A';

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.calendar_today_outlined,
            label: 'Cash Runway',
            value: runwayValue,
            isLoading: runwayState.isLoading,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.shield_outlined,
            label: 'Stability Score',
            value: stabilityValue,
            isLoading: stabilityState.isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewBanner(int count) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TransactionsScreen(initialFilter: 'Pending')),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEEDS REVIEW',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.warning,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '$count Items Pending',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(Theme.of(context).brightness == Brightness.dark),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionsScreen(initialFilter: 'All')),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
      dynamic transactionsState, dynamic accountsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions',
                style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionsScreen(initialFilter: 'All')),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactionsState.isLoading)
          const Center(
              child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary)))
        else if (transactionsState.error != null)
          _buildEmptyState(
              icon: Icons.error_outline,
              message: 'Failed to load pending transactions: ${transactionsState.error}',
              color: AppColors.error)
        else if (transactionsState.transactions.isEmpty)
          _buildEmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No transactions yet',
              color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark))
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(Theme.of(context).brightness == Brightness.dark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(Theme.of(context).brightness == Brightness.dark)),
            ),
            child: Column(
              children: transactionsState.transactions
                  .take(5)
                  .toList()
                  .asMap()
                  .entries
                  .map<Widget>((entry) {
                final i = entry.key;
                final twd = entry.value as TransactionWithDetails;
                final t = twd.transaction;
                final isLast = i == (transactionsState.transactions.length.clamp(0, 5) - 1);
                return Column(
                  children: [
                    _DashboardTransactionRow(
                      transactionWithDetails: twd,
                      accountsState: accountsState,
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 60, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card(Theme.of(context).brightness == Brightness.dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(Theme.of(context).brightness == Brightness.dark)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildFAB(dynamic accountsState) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (accountsState.accounts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please add an account first.'),
            backgroundColor: AppColors.warning,
          ));
          return;
        }
        if (value == 'add_transaction') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        } else if (value == 'transfer_funds') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransferScreen()),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'add_transaction',
          child: Row(children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Add Transaction'),
          ]),
        ),
        PopupMenuItem(
          value: 'transfer_funds',
          child: Row(children: [
            Icon(Icons.swap_horiz, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Transfer Funds'),
          ]),
        ),
      ],
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x4019AEA7),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }

  String _getAccountName(int accountId, AccountsState accountsState) {
    return accountsState.accounts
            .where((a) => a.id == accountId)
            .firstOrNull
            ?.name ??
        'Unknown';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLoading;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(Theme.of(context).brightness == Brightness.dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(Theme.of(context).brightness == Brightness.dark)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark))),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTransactionRow extends StatelessWidget {
  final TransactionWithDetails transactionWithDetails;
  final AccountsState accountsState;

  const _DashboardTransactionRow({
    required this.transactionWithDetails,
    required this.accountsState,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = transactionWithDetails.transaction;
    final category = transactionWithDetails.category;
    final merchant = transactionWithDetails.merchant;
    
    final isCredit = transaction.amountMinor >= 0;
    final amountColor = isCredit ? AppColors.success : AppColors.error;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use the same icon/color logic as TransactionsScreen
    final iconData = _getIconData(category?.icon, transaction.type);
    final iconColor = _getColor(category?.color, transaction.type, isDark);
    
    // Get currency from the account
    final account = transactionWithDetails.account;
    final currency = account?.currency ?? 'NGN';
    final amount = CurrencyUtils.formatMinorToDisplay(
        transaction.amountMinor.abs(), currency);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(transaction: transaction),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant?.name ?? transaction.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(child: _Chip(text: category?.name ?? 'Other')),
                      const SizedBox(width: 6),
                      if (account != null)
                        Flexible(child: _Chip(text: account.name, isAccount: true)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}$amount',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(transaction.timestamp),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary(isDark)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName, String type) {
    if (type == 'transfer_out' || type == 'transfer_in') {
      return Icons.swap_horiz_outlined;
    }
    
    switch (iconName?.toLowerCase()) {
      case 'shopping_cart': return Icons.shopping_cart_outlined;
      case 'restaurant': return Icons.restaurant_outlined;
      case 'directions_car': return Icons.directions_car_outlined;
      case 'home': return Icons.home_outlined;
      case 'payments': return Icons.payments_outlined;
      case 'receipt': return Icons.receipt_outlined;
      case 'bolt': return Icons.bolt_outlined;
      case 'coffee': return Icons.coffee_outlined;
      case 'phone_iphone': return Icons.phone_iphone_outlined;
      default: return Icons.receipt_outlined;
    }
  }

  Color _getColor(String? colorHex, String type, bool isDark) {
    if (type == 'transfer_out' || type == 'transfer_in') {
      return AppColors.primary;
    }
    
    if (colorHex == null || colorHex.isEmpty) return AppColors.textSecondary(isDark);
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.textSecondary(isDark);
    }
  }

  Color _getCategoryColor(String? desc) {
    switch (desc?.toLowerCase()) {
      case 'techcorp ltd':
      case 'salary':
        return const Color(0xFF16A34A);
      case 'chicken republic':
      case 'kitchen & grill':
        return const Color(0xFFEA580C);
      case 'bolt':
        return const Color(0xFF2563EB);
      case 'ikedc':
        return const Color(0xFFDC2626);
      case 'jumia':
      case 'amazon':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF6B7A8D);
    }
  }

  IconData _getCategoryIcon(String? desc) {
    switch (desc?.toLowerCase()) {
      case 'techcorp ltd':
      case 'salary':
      case 'inlaks computers ltd':
        return Icons.payments_outlined;
      case 'chicken republic':
      case 'kitchen & grill':
      case 'starbucks coffee':
        return Icons.restaurant_outlined;
      case 'bolt':
      case 'uber trip':
        return Icons.directions_car_outlined;
      case 'ikedc':
      case 'utility bill':
        return Icons.bolt_outlined;
      case 'jumia':
      case 'amazon prime web svcs':
        return Icons.shopping_bag_outlined;
      case 'apple store':
        return Icons.phone_iphone_outlined;
      case 'monthly salary':
        return Icons.attach_money;
      default:
        return Icons.receipt_outlined;
    }
  }

  String _getCategoryName(String? desc) {
    switch (desc?.toLowerCase()) {
      case 'techcorp ltd':
      case 'salary':
      case 'inlaks computers ltd':
      case 'monthly salary':
        return 'Salary';
      case 'chicken republic':
      case 'kitchen & grill':
      case 'starbucks coffee':
        return 'Dining';
      case 'bolt':
      case 'uber trip':
        return 'Transport';
      case 'ikedc':
      case 'utility bill':
        return 'Bills';
      case 'jumia':
      case 'amazon prime web svcs':
        return 'Services';
      default:
        return 'Other';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today ${DateFormat.jm().format(dt)}';
    } else if (dt.year == now.year && dt.day == now.subtract(const Duration(days: 1)).day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(dt);
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool isAccount;

  const _Chip({required this.text, this.isAccount = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isAccount ? AppColors.primaryBg : AppColors.background(isDark),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isAccount ? AppColors.primary : AppColors.textSecondary(isDark),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
