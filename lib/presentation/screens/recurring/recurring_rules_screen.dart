import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_recurring_rule_screen.dart';
import '../../providers/recurring_rule_providers.dart';
import '../../../domain/entities/recurring_rule.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../main.dart';

class RecurringRulesScreen extends ConsumerWidget {
  const RecurringRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Recurring Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Run Automation',
            onPressed: () async {
              try {
                final count = await ref.read(recurringRulesProvider.notifier).processDueRules();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created $count recurring transactions')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: kError),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddRecurringRuleScreen()),
              );
            },
          ),
        ],
      ),
      body: rulesAsync.when(
        data: (rules) => rules.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return _RuleCard(rule: rule);
                },
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => ErrorDisplayWidget(
          error: err.toString(),
          onRetry: () => ref.invalidate(recurringRulesProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_outlined, size: 64, color: kTextSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No recurring payments set up',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddRecurringRuleScreen()),
              );
            },
            child: const Text('Add a Payment'),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final dynamic rule; // domain.RecurringRule

  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    final amount = CurrencyUtils.formatMinorToDisplay(rule.amountMinor, 'NGN');
    final frequency = rule.frequency.toString().split('.').last;
    final type = rule.type.toString().split('.').last;
    
    final typeColor = rule.type == RecurringType.income ? kSuccess : kError;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Chip(text: frequency.toUpperCase()),
                const SizedBox(width: 8),
                _Chip(text: type.toUpperCase()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Payment', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      _formatDate(rule.nextExecutionDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (rule.lastExecutedDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Last Payment', style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        _formatDate(rule.lastExecutedDate!),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimaryBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
