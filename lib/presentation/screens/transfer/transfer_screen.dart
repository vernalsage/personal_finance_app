import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../domain/entities/account.dart';
import '../../../core/utils/currency_utils.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart' as providers;
import '../../../core/di/usecase_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amountController = TextEditingController();
  int? _fromAccountId;
  int? _toAccountId;
  bool _isProcessing = false;
  double? _conversionRate;
  final bool _isConverting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);
    final accounts = accountsState.accounts.where((a) => a.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Funds'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // From Account Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _fromAccountId,
                      isExpanded: true,
                      itemHeight: 80.0, // Increased to prevent overflow
                      decoration: const InputDecoration(
                        labelText: 'Select account to transfer from',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem<int>(
                          value: account.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getAccountTypeColor(
                                  account.type,
                                ),
                                radius: 12,
                                child: Icon(
                                  _getAccountTypeIcon(account.type),
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(account.name),
                                  Text(
                                    'Balance: ${CurrencyUtils.formatMinorToDisplay(account.balanceMinor, account.currency)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _fromAccountId = value;
                          if (_toAccountId == _fromAccountId) {
                            _toAccountId = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // To Account Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _toAccountId,
                      isExpanded: true,
                      itemHeight: 80.0, // Increased to prevent overflow
                      decoration: const InputDecoration(
                        labelText: 'Select account to transfer to',
                        border: OutlineInputBorder(),
                      ),
                      // We don't filter in the items list to prevent "!_debugDoingThisLayout" 
                      // or "exactly one item" issues during build. Instead we disable the item.
                      items: accounts.map((account) {
                        final isSameAsFrom = account.id == _fromAccountId;
                        return DropdownMenuItem<int>(
                          value: account.id,
                          enabled: !isSameAsFrom,
                          child: Opacity(
                            opacity: isSameAsFrom ? 0.4 : 1.0,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getAccountTypeColor(
                                    account.type,
                                  ),
                                  radius: 12,
                                  child: Icon(
                                    _getAccountTypeIcon(account.type),
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded( // Ensure text takes available space
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        account.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Balance: ${CurrencyUtils.formatMinorToDisplay(account.balanceMinor, account.currency)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _toAccountId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    (){
                      final fromAccount = accounts.firstWhereOrNull((a) => a.id == _fromAccountId);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Transfer amount',
                              border: const OutlineInputBorder(),
                              prefixText: fromAccount != null
                                  ? CurrencyUtils.getCurrencySymbol(fromAccount.currency)
                                  : '₦',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => setState(() {}),
                          ),
                          if (fromAccount != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Available: ${CurrencyUtils.formatMinorToDisplay(fromAccount.balanceMinor, fromAccount.currency)}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      );
                    }(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Currency Conversion Info (if applicable)
            (){
              final fromAccount = accounts.firstWhereOrNull((a) => a.id == _fromAccountId);
              final toAccount = accounts.firstWhereOrNull((a) => a.id == _toAccountId);
              
              if (fromAccount != null && toAccount != null && fromAccount.currency != toAccount.currency) {
                return Card(
                  color: Colors.blue.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Currency Conversion',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are transferring from ${fromAccount.currency} to ${toAccount.currency}. The system will use the current exchange rate for this transaction.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        if (_isConverting) ...[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(minHeight: 2),
                        ] else if (_conversionRate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Exchange Rate: 1 ${fromAccount.currency} = ${_conversionRate!.toStringAsFixed(4)} ${toAccount.currency}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }(),
            
            const SizedBox(height: 24),

            // Transfer Button
            ElevatedButton(
              onPressed: _isProcessing || !_canTransfer(accounts)
                  ? null
                  : () => _performTransfer(accounts),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Transfer Funds'),
            ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canTransfer(List<Account> accounts) {
    if (_fromAccountId == null || _toAccountId == null) return false;
    if (_amountController.text.trim().isEmpty) return false;

    final fromAccount = accounts.firstWhereOrNull((a) => a.id == _fromAccountId);
    if (fromAccount == null) return false;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return false;

    final availableBalance = fromAccount.balanceMinor / 100.0;
    if (amount > availableBalance) return false;

    return true;
  }

  void _performTransfer(List<Account> accounts) async {
    if (!_canTransfer(accounts)) return;

    final fromAccount = accounts.firstWhereOrNull((a) => a.id == _fromAccountId);
    final toAccount = accounts.firstWhereOrNull((a) => a.id == _toAccountId);

    if (fromAccount == null || toAccount == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final amountMinor = (amount * 100).round();
      
      // Use the atomic ExecuteTransferUseCase
      final result = await ref.read(executeTransferUseCaseProvider)(
        sourceAccountId: _fromAccountId!,
        destinationAccountId: _toAccountId!,
        amountMinor: amountMinor,
        description: 'Transfer from ${fromAccount.name} to ${toAccount.name}',
        note: 'Manual transfer',
      );

      if (result.isSuccess) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Transfer completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          navigator.pop();
        }

        // Refresh accounts and transactions list
        ref.read(accountsProvider.notifier).loadAccounts(1);
        ref.read(providers.transactionsProvider.notifier).loadTransactions(1);
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Transfer failed: ${result.failureData}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error during transfer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Color _getAccountTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'checking':
        return Colors.blue;
      case 'savings':
        return Colors.green;
      case 'credit':
        return Colors.purple;
      case 'investment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
