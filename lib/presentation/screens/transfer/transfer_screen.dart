import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/account.dart';
import '../../../core/utils/currency_utils.dart';
import '../../providers/account_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amountController = TextEditingController();
  Account? _fromAccount;
  Account? _toAccount;
  bool _isProcessing = false;

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
      body: Padding(
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
                    DropdownButtonFormField<Account>(
                      initialValue: _fromAccount,
                      decoration: const InputDecoration(
                        labelText: 'Select account to transfer from',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem<Account>(
                          value: account,
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _fromAccount = value;
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
                    DropdownButtonFormField<Account>(
                      initialValue: _toAccount,
                      decoration: const InputDecoration(
                        labelText: 'Select account to transfer to',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts
                          .where((account) => account.id != _fromAccount?.id)
                          .map((account) {
                            return DropdownMenuItem<Account>(
                              value: account,
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(account.name),
                                        Text(
                                          'Balance: ₦${(account.balanceMinor / 100).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _toAccount = value;
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
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Transfer amount',
                        border: OutlineInputBorder(),
                        prefixText: _fromAccount != null
                            ? CurrencyUtils.getCurrencySymbol(
                                _fromAccount!.currency,
                              )
                            : '₦',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    if (_fromAccount != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Available: ${CurrencyUtils.formatMinorToDisplay(_fromAccount!.balanceMinor, _fromAccount!.currency)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transfer Button
            ElevatedButton(
              onPressed: _isProcessing || _canTransfer()
                  ? null
                  : _performTransfer,
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
    );
  }

  bool _canTransfer() {
    if (_fromAccount == null || _toAccount == null) return false;
    if (_amountController.text.trim().isEmpty) return false;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return false;

    final availableBalance = _fromAccount!.balanceMinor / 100.0;
    if (amount > availableBalance) return false;

    return true;
  }

  void _performTransfer() async {
    if (!_canTransfer()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final amountMinor = (amount * 100).round();

      // Update from account (subtract amount)
      final fromAccountUpdate = Account(
        id: _fromAccount!.id,
        profileId: _fromAccount!.profileId,
        name: _fromAccount!.name,
        currency: _fromAccount!.currency,
        balanceMinor: _fromAccount!.balanceMinor - amountMinor,
        type: _fromAccount!.type,
        isActive: _fromAccount!.isActive,
      );

      // Update to account (add amount)
      final toAccountUpdate = Account(
        id: _toAccount!.id,
        profileId: _toAccount!.profileId,
        name: _toAccount!.name,
        currency: _toAccount!.currency,
        balanceMinor: _toAccount!.balanceMinor + amountMinor,
        type: _toAccount!.type,
        isActive: _toAccount!.isActive,
      );

      // Perform both updates
      final fromResult = await ref.read(updateAccountUseCaseProvider)(
        fromAccountUpdate,
      );
      final toResult = await ref.read(updateAccountUseCaseProvider)(
        toAccountUpdate,
      );

      if (fromResult.isSuccess && toResult.isSuccess) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Transfer completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          navigator.pop();
        }

        // Refresh accounts list
        ref.read(accountsProvider.notifier).loadAccounts(1);
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Transfer failed. Please try again.'),
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
      setState(() {
        _isProcessing = false;
      });
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
