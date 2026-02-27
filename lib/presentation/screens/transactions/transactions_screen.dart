import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../main.dart';
import '../../providers/transaction_providers.dart' as providers;
import '../../providers/account_providers.dart';
import 'package:collection/collection.dart';


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

  List<Transaction> _getFiltered(List<Transaction> transactions) {
    var list = transactions;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((t) =>
              t.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    switch (_selectedFilter) {
      case 'Credits':
        list = list.where((t) => t.amountMinor > 0).toList();
        break;
      case 'Debits':
        list = list.where((t) => t.amountMinor < 0).toList();
        break;
      case 'Pending':
        list = list.where((t) => t.requiresReview).toList();
        break;
    }
    return list;
  }

  // Group transactions by date label
  Map<String, List<Transaction>> _getGrouped(List<Transaction> transactions) {
    final result = <String, List<Transaction>>{};
    for (final t in _getFiltered(transactions)) {
      final label = _dateLabel(t.timestamp);
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
                                    _TransactionCard(transaction: t),
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

  Widget _buildFilterPill(String label, List<Transaction> transactions) {
    final isActive = _selectedFilter == label;
    final pendingCount = label == 'Pending'
        ? transactions.where((t) => t.requiresReview).length
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
  final Transaction transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCredit = transaction.amountMinor >= 0;
    final amountColor = isCredit ? kSuccess : kError;
    final iconColor = _getCategoryColor(transaction.description);
    
    // Get currency from accounts provider
    final accountsState = ref.watch(accountsProvider);
    final account = accountsState.accounts.firstWhereOrNull((a) => a.id == transaction.accountId);
    final currency = account?.currency ?? 'NGN';
    final amount = CurrencyUtils.formatMinorToDisplay(
        transaction.amountMinor.abs(), currency);

    return InkWell(
      onTap: () {},
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
              child: Icon(_getCategoryIcon(transaction.description),
                  color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Details
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
                  Text(
                    _getCategoryName(transaction.description),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: kTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              '${isCredit ? '+' : '-'}$amount',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? desc) {
    switch (desc?.toLowerCase()) {
      case 'apple store':
        return const Color(0xFF6366F1);
      case 'monthly salary':
      case 'techcorp ltd':
        return const Color(0xFF16A34A);
      case 'starbucks coffee':
      case 'chicken republic':
        return const Color(0xFFEA580C);
      case 'uber trip':
      case 'bolt':
        return const Color(0xFF2563EB);
      case 'utility bill':
      case 'ikedc':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7A8D);
    }
  }

  IconData _getCategoryIcon(String? desc) {
    switch (desc?.toLowerCase()) {
      case 'apple store':
        return Icons.phone_iphone_outlined;
      case 'monthly salary':
      case 'techcorp ltd':
        return Icons.payments_outlined;
      case 'starbucks coffee':
      case 'chicken republic':
        return Icons.coffee_outlined;
      case 'uber trip':
      case 'bolt':
        return Icons.directions_car_outlined;
      case 'utility bill':
      case 'ikedc':
        return Icons.bolt_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  String _getCategoryName(String? desc) {
    switch (desc?.toLowerCase()) {
      case 'apple store':
        return 'Electronics';
      case 'monthly salary':
      case 'techcorp ltd':
        return 'Income';
      case 'starbucks coffee':
      case 'chicken republic':
        return 'Food & Drink';
      case 'uber trip':
      case 'bolt':
        return 'Transport';
      case 'utility bill':
      case 'ikedc':
        return 'Bills';
      default:
        return 'Other';
    }
  }
}
