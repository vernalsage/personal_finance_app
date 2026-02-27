import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../../application/services/hybrid_currency_service.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/account.dart';
import '../../../main.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';
import '../transaction/add_transaction_screen.dart';
import '../transfer/transfer_screen.dart';
import '../transactions/transactions_screen.dart';
import '../recurring/recurring_rules_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<double>? _totalBalanceFuture;
  bool _balanceVisible = true;
  List<Account>? _lastAccounts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        ref.read(accountsProvider.notifier).loadAccounts(1),
        ref.read(transactionsProvider.notifier).loadTransactions(1, limit: 10),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  Future<double> _calculateTotalBalance(dynamic accounts) async {
    double total = 0.0;
    for (final account in accounts) {
      final converted = await HybridCurrencyService.convertCurrency(
        amount: account.balanceMinor / 100.0,
        fromCurrency: account.currency,
        toCurrency: 'NGN',
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
    final accountsState = ref.watch(accountsProvider);
    final transactionsState = ref.watch(transactionsProvider);

    // Recalculate if accounts list actually changed
    if (_lastAccounts != accountsState.accounts) {
      _lastAccounts = accountsState.accounts;
      _totalBalanceFuture = _calculateTotalBalance(accountsState.accounts);
    }

    final reviewTransactions =
        transactionsState.transactions.where((t) => t.requiresReview).toList();

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
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
                _buildBalanceCard(),
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
    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kPrimaryBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: kPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: kTextSecondary,
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
          icon: const Icon(Icons.sync_outlined, color: kTextSecondary, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: kCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: kBorder),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Bell
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined,
              color: kTextSecondary, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: kCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: kBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
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
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                child: Icon(
                  _balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.8),
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
                  'NGN',
                );
              } else if (snapshot.hasError) {
                balance = 'Error loading balance';
              }
              return Text(
                _balanceVisible ? balance : '₦ ••••••',
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
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.calendar_today_outlined,
            label: 'Cash Runway',
            value: '6 Months',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.shield_outlined,
            label: 'Stability Score',
            value: '85/100',
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
          color: kWarning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kWarning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: kWarning,
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
                      color: kWarning,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '$count Items Pending',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
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
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: kPrimary)))
        else if (transactionsState.error != null)
          _buildEmptyState(
              icon: Icons.error_outline,
              message: 'Failed to load pending transactions: ${transactionsState.error}',
              color: kError)
        else if (transactionsState.transactions.isEmpty)
          _buildEmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No transactions yet',
              color: kTextSecondary)
        else
          Container(
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: transactionsState.transactions
                  .take(5)
                  .toList()
                  .asMap()
                  .entries
                  .map<Widget>((entry) {
                final i = entry.key;
                final t = entry.value as Transaction;
                final isLast = i == (transactionsState.transactions.length.clamp(0, 5) - 1);
                return Column(
                  children: [
                    _DashboardTransactionRow(
                      transaction: t,
                      accountName: _getAccountName(t.accountId, accountsState),
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
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color.withOpacity(0.5)),
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
            backgroundColor: kWarning,
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
            Icon(Icons.add_circle_outline, color: kPrimary),
            SizedBox(width: 10),
            Text('Add Transaction'),
          ]),
        ),
        PopupMenuItem(
          value: 'transfer_funds',
          child: Row(children: [
            Icon(Icons.swap_horiz, color: kPrimary),
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
            colors: [kPrimary, kPrimaryDark],
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

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: kTextSecondary)),
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
  final Transaction transaction;
  final String accountName;
  final AccountsState accountsState;

  const _DashboardTransactionRow({
    required this.transaction,
    required this.accountName,
    required this.accountsState,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amountMinor >= 0;
    final amountColor = isCredit ? kSuccess : kError;
    final iconColor = _getCategoryColor(transaction.description);
    
    // Get currency from the account
    final account = accountsState.accounts.firstWhereOrNull((a) => a.id == transaction.accountId);
    final currency = account?.currency ?? 'NGN';
    final amount = CurrencyUtils.formatMinorToDisplay(
        transaction.amountMinor.abs(), currency);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getCategoryIcon(transaction.description),
                color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(child: _Chip(text: _getCategoryName(transaction.description))),
                    const SizedBox(width: 6),
                    Flexible(child: _Chip(text: accountName, isAccount: true)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}$amount',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(transaction.timestamp),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: kTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isAccount ? kPrimaryBg : kBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isAccount ? kPrimary : kTextSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
