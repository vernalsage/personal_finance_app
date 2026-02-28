import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transaction_with_details.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../main.dart';
import '../../providers/transaction_providers.dart' as providers;
import '../transaction/add_transaction_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const TransactionsScreen({super.key, this.initialFilter});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  late String _selectedFilter;
  String _searchQuery = '';
  final List<String> _filters = ['All', 'Credits', 'Debits', 'Pending'];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providers.transactionsProvider.notifier).loadTransactions(1);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionWithDetails> _getFiltered(List<TransactionWithDetails> transactions) {
    var list = transactions;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((t) =>
              t.transaction.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (t.merchant?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (t.category?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }
    switch (_selectedFilter) {
      case 'Credits':
        list = list.where((t) => t.transaction.amountMinor > 0).toList();
        break;
      case 'Debits':
        list = list.where((t) => t.transaction.amountMinor < 0).toList();
        break;
      case 'Pending':
        list = list.where((t) => t.transaction.requiresReview).toList();
        break;
    }
    return list;
  }

  // Group transactions by date label
  Map<String, List<TransactionWithDetails>> _getGrouped(List<TransactionWithDetails> transactions) {
    final result = <String, List<TransactionWithDetails>>{};
    for (final t in _getFiltered(transactions)) {
      final label = _dateLabel(t.transaction.timestamp);
      result.putIfAbsent(label, () => []).add(t);
    }
    return result;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(dt.year, dt.month, dt.day);

    final isToday = transactionDate.isAtSameMomentAs(today);
    final isYesterday = transactionDate.isAtSameMomentAs(yesterday);
    
    final formatted = DateFormat('MMM d').format(dt).toUpperCase();
    if (isToday) return 'TODAY, $formatted';
    if (isYesterday) return 'YESTERDAY, $formatted';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(providers.transactionsProvider);
    final grouped = _getGrouped(transactionsState.transactions);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kSurface,
        title: const Text('Transactions'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                color: kTextSecondary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search + Filters ──────────────────────────────────────────────
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search merchants, categories...',
                    prefixIcon:
                        const Icon(Icons.search, color: kPrimary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18, color: kTextSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                      borderSide: const BorderSide(color: kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                      borderSide: const BorderSide(color: kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                      borderSide: const BorderSide(color: kPrimary, width: 2),
                    ),
                    filled: true,
                    fillColor: kBackground,
                  ),
                ),
                const SizedBox(height: 10),
                // Filter pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) => _buildFilterPill(f, transactionsState.transactions)).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ─── Transaction List ──────────────────────────────────────────────
          Expanded(
            child: transactionsState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  )
                : transactionsState.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: kError),
                            const SizedBox(height: 12),
                            Text('Error: ${transactionsState.error}',
                                style: Theme.of(context).textTheme.bodyMedium),
                            TextButton(
                              onPressed: () => ref
                                  .read(providers.transactionsProvider.notifier)
                                  .loadTransactions(1),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : grouped.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 56, color: kBorder),
                                const SizedBox(height: 12),
                                Text(
                                    _selectedFilter == 'All'
                                        ? 'No transactions found'
                                        : 'No $_selectedFilter transactions found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: kTextSecondary)),
                                if (_selectedFilter != 'All')
                                  TextButton(
                                    onPressed: () => setState(() => _selectedFilter = 'All'),
                                    child: const Text('Clear Filters'),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: grouped.length,
                    itemBuilder: (context, gi) {
                      final dateLabel = grouped.keys.elementAt(gi);
                      final txList = grouped[dateLabel]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Text(
                              dateLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: kTextSecondary),
                            ),
                          ),
                          // Transactions card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              children: txList.asMap().entries.map((entry) {
                                final i = entry.key;
                                final t = entry.value;
                                return Column(
                                  children: [
                                    _TransactionCard(transactionWithDetails: t),
                                    if (i < txList.length - 1)
                                      const Divider(
                                          height: 1, indent: 60, endIndent: 16),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, List<TransactionWithDetails> transactions) {
    final isActive = _selectedFilter == label;
    final pendingCount = label == 'Pending'
        ? transactions.where((t) => t.transaction.requiresReview).length
        : 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? kPrimary : kBackground,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: isActive ? kPrimary : kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : kTextSecondary,
              ),
            ),
            if (pendingCount > 0 && !isActive) ...[
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: kWarning,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            if (label != 'All' && label != 'Pending') ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: isActive ? Colors.white : kTextSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Card (row) ────────────────────────────────────────────────────

class _TransactionCard extends ConsumerWidget {
  final TransactionWithDetails transactionWithDetails;
  const _TransactionCard({required this.transactionWithDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = transactionWithDetails.transaction;
    final category = transactionWithDetails.category;
    final merchant = transactionWithDetails.merchant;
    
    final isCredit = transaction.amountMinor >= 0;
    final amountColor = isCredit ? kSuccess : kError;
    
    // Dynamic Icon/Color from Category
    final iconData = _getIconData(category?.icon, transaction.type);
    final iconColor = _getColor(category?.color, transaction.type);

    final currency = transactionWithDetails.account?.currency ?? 'NGN';
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Details
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
                      Text(
                        category?.name ?? 'Other',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: kTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (transaction.requiresReview) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: kWarning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REVIEW',
                            style: TextStyle(
                              color: kWarning,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount & Actions
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
                if (transaction.requiresReview)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: InkWell(
                      onTap: () => ref.read(providers.transactionsProvider.notifier).approveTransaction(transactionWithDetails),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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

  Color _getColor(String? colorHex, String type) {
    if (type == 'transfer_out' || type == 'transfer_in') {
      return kPrimary;
    }
    
    if (colorHex == null || colorHex.isEmpty) return kTextSecondary;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return kTextSecondary;
    }
  }
}
