import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/services/hybrid_currency_service.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';
import '../transaction/add_transaction_screen.dart';
import '../transfer/transfer_screen.dart';
import '../transactions/transactions_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _dataLoaded = false;
  Object? _previousAccounts;
  Future<double>? _totalBalanceFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_dataLoaded) return;

    const profileId = 1; // TODO: Get from user session

    try {
      await Future.wait([
        ref.read(accountsProvider.notifier).loadAccounts(profileId),
        ref
            .read(transactionsProvider.notifier)
            .loadTransactionsRequiringReview(profileId),
      ]);
      if (mounted) {
        setState(() {
          _dataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  Future<double> _calculateTotalBalance(dynamic accounts) async {
    double totalNGN = 0.0;
    for (final account in accounts) {
      final balanceInNGN = await HybridCurrencyService.convertCurrency(
        amount: account.balanceMinor / 100.0,
        fromCurrency: account.currency,
        toCurrency: 'NGN',
      );
      totalNGN += balanceInNGN;
    }
    return totalNGN;
  }

  // --- UI Helper Methods to reduce nesting ---

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildReviewCard(Transaction transaction, dynamic accountsState) {
    final isCredit = transaction.amountMinor >= 0;
    final amountColor = isCredit
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final iconColor = _getCategoryColor(transaction.description);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left: Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(transaction.description),
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(
                        _getCategoryName(transaction.description),
                        Colors.grey[100]!,
                        const Color(0xFF1976D2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildBadge(
                          _getAccountName(transaction.accountId, accountsState),
                          Colors.blue[50]!,
                          const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right: Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyUtils.formatMinorToDisplay(
                        transaction.amountMinor,
                        'NGN',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: amountColor,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(transaction.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);
    final transactionsState = ref.watch(transactionsProvider);

    if (_previousAccounts != accountsState.accounts) {
      _previousAccounts = accountsState.accounts;
      _totalBalanceFuture = _calculateTotalBalance(accountsState.accounts);
    }

    final reviewTransactions = transactionsState.transactions
        .where((t) => t.requiresReview)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Balance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<double>(
                        future: _totalBalanceFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              CurrencyUtils.formatMinorToDisplay(
                                (snapshot.data! * 100).round(),
                                'NGN',
                              ),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            );
                          } else if (snapshot.hasError) {
                            return Text(
                              'Error loading balance',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.red),
                            );
                          } else {
                            return const Text('Loading...');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Transactions Requiring Review Section
              if (reviewTransactions.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Transactions Requiring Review',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange[500],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${reviewTransactions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ...reviewTransactions
                    .take(5)
                    .map((t) => _buildReviewCard(t, accountsState)),

                if (reviewTransactions.length > 5) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TransactionsScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // 3. Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 4. Recent Transactions List
              if (transactionsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (transactionsState.error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${transactionsState.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                )
              else if (transactionsState.transactions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No transactions yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactionsState.transactions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    return _TransactionTile(
                      transaction: transactionsState.transactions[index],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: PopupMenuButton<String>(
        itemBuilder: (BuildContext context) {
          return const [
            PopupMenuItem(
              value: 'add_transaction',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline),
                  SizedBox(width: 8),
                  Text('Add Transaction'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'transfer_funds',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz),
                  SizedBox(width: 8),
                  Text('Transfer Funds'),
                ],
              ),
            ),
          ];
        },
        onSelected: (String value) {
          if (accountsState.accounts.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please add an Account first.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          if (value == 'add_transaction') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(),
              ),
            );
          } else if (value == 'transfer_funds') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TransferScreen()),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Logic Helpers ---

  Color _getCategoryColor(String? description) {
    switch (description?.toLowerCase()) {
      case 'techcorp ltd':
      case 'salary':
        return const Color(0xFF4CAF50);
      case 'chicken republic':
        return const Color(0xFFFF6B35);
      case 'bolt':
        return const Color(0xFF4285F4);
      case 'ikedc':
        return const Color(0xFFF44336);
      case 'jumia':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey[500]!;
    }
  }

  IconData _getCategoryIcon(String? description) {
    switch (description?.toLowerCase()) {
      case 'techcorp ltd':
      case 'salary':
        return Icons.payments;
      case 'chicken republic':
        return Icons.restaurant;
      case 'bolt':
        return Icons.directions_car;
      case 'ikedc':
        return Icons.receipt;
      case 'jumia':
        return Icons.shopping_cart;
      default:
        return Icons.help_outline;
    }
  }

  String _getCategoryName(String? description) {
    switch (description?.toLowerCase()) {
      case 'techcorp ltd':
        return 'Salary';
      case 'chicken republic':
        return 'Food & Dining';
      case 'bolt':
        return 'Transportation';
      case 'ikedc':
        return 'Bills & Utilities';
      case 'jumia':
        return 'Shopping';
      default:
        return 'Uncategorized';
    }
  }

  String _getAccountName(int accountId, dynamic accountsState) {
    final account = accountsState.accounts
        .where((acc) => acc.id == accountId)
        .firstOrNull;
    return account?.name ?? 'Unknown Account';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day} ${_getMonthAbbreviation(dateTime.month)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amountMinor >= 0;
    final amountColor = isCredit
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withOpacity(0.1),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: amountColor,
        ),
      ),
      title: Text(
        transaction.description,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        _formatDate(transaction.timestamp),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Flexible(
        child: Text(
          '${isCredit ? '+' : '-'}₦${(transaction.amountMinor.abs() / 100).toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
