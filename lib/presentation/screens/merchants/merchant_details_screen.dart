import 'package:flutter/material.dart';
import '../../../domain/entities/transaction_with_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/merchant_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/merchant.dart';
import '../../../domain/repositories/itransaction_repository.dart';
import '../../../main.dart';

class MerchantDetailsScreen extends ConsumerWidget {
  final Merchant merchant;

  const MerchantDetailsScreen({super.key, required this.merchant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(merchantTransactionsProvider(merchant.id));

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(merchant.name),
      ),
      body: transactionsAsync.when(
        data: (transactions) => _buildContent(context, transactions),
        loading: () => const LoadingWidget(),
        error: (err, stack) => ErrorDisplayWidget(
          error: err.toString(),
          onRetry: () => ref.invalidate(merchantTransactionsProvider(merchant.id)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<TransactionWithDetails> transactions) {
    // Calculate stats
    int totalSpentMinor = 0;
    int transactionCount = transactions.length;
    
    for (final t in transactions) {
      if (t.transaction.amountMinor < 0) {
        totalSpentMinor += t.transaction.amountMinor.abs();
      }
    }

    final totalSpentFormatted = CurrencyUtils.formatMinorToDisplay(totalSpentMinor, 'NGN');
    final avgSpentFormatted = transactionCount > 0 
        ? CurrencyUtils.formatMinorToDisplay((totalSpentMinor / transactionCount).round(), 'NGN')
        : '₦0.00';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merchant Info Card
          _buildInfoCard(context, totalSpentFormatted, avgSpentFormatted, transactionCount),
          const SizedBox(height: 24),

          Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          if (transactions.isEmpty)
            _buildEmptyTransactions(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final t = transactions[index];
                return _TransactionRow(item: t);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String total, String avg, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: kPrimaryBg,
            child: const Icon(Icons.storefront, color: kPrimary, size: 30),
          ),
          const SizedBox(height: 12),
          Text(merchant.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Total Spent', value: total),
              _StatItem(label: 'Avg. Transaction', value: avg),
              _StatItem(label: 'Frequency', value: '$count items'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: kTextSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('No transactions found', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionWithDetails item;

  const _TransactionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    // For Safety, provide a fallback account name
    final accountName = item.account?.name ?? 'Unknown';
    final amount = CurrencyUtils.formatMinorToDisplay(item.transaction.amountMinor.abs(), 'NGN');
    final isCredit = item.transaction.amountMinor >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.transaction.description, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  '${_formatDate(item.transaction.timestamp)} • $accountName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}$amount',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isCredit ? kSuccess : kError,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
