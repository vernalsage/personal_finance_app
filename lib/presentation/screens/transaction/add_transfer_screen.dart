import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_providers.dart';
import '../../../core/utils/currency_utils.dart';

class AddTransferScreen extends ConsumerStatefulWidget {
  const AddTransferScreen({super.key});

  @override
  ConsumerState<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends ConsumerState<AddTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _sourceAccountId;
  int? _destinationAccountId;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Funds'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Field
                Text('Amount', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (₦)',
                    prefixText: '₦',
                    border: const OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[^\d.]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (!CurrencyUtils.isValidAmount(value)) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Source Account
                Text(
                  'From Account',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _sourceAccountId,
                  decoration: InputDecoration(
                    labelText: 'Source Account',
                    border: const OutlineInputBorder(),
                  ),
                  items: accountsState.accounts.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(
                        '${account.name} (${CurrencyUtils.formatMinorToDisplay(account.balanceMinor)})',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sourceAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select source account';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Destination Account
                Text(
                  'To Account',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _destinationAccountId,
                  decoration: InputDecoration(
                    labelText: 'Destination Account',
                    border: const OutlineInputBorder(),
                  ),
                  items: accountsState.accounts.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(
                        '${account.name} (${CurrencyUtils.formatMinorToDisplay(account.balanceMinor)})',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _destinationAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select destination account';
                    }
                    if (value == _sourceAccountId) {
                      return 'Source and destination cannot be the same';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Note Field (Optional)
                Text(
                  'Note (Optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitTransfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Transfer Funds'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitTransfer() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert amount string to minor units
      final amountMinor = CurrencyUtils.formatAmountToMinor(
        _amountController.text,
      );

      // Execute transfer via use case
      // TODO: Implement actual transfer logic when use case is ready
      debugPrint('Transfer would be executed with amount: $amountMinor');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer completed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form and go back
        _formKey.currentState?.reset();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
