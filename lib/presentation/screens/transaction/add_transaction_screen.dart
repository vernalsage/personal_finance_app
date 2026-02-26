import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/account_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/utils/currency_utils.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'debit';
  int? _selectedAccountId;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
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
                // Account Selection
                Text('Account', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'Select Account',
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
                      _selectedAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an account';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Transaction Type
                Text(
                  'Transaction Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'debit',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Debit'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'credit',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Credit'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? 'debit';
                    });
                  },
                ),
                const SizedBox(height: 24),

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

                // Merchant Field
                Text(
                  'Merchant/Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    labelText: 'Merchant or Description',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter merchant or description';
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
                    onPressed: _isLoading ? null : _submitTransaction,
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
                        : const Text('Add Transaction'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitTransaction() async {
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

      // Create transaction entity
      final transaction = Transaction(
        id: 0, // Will be set by database
        profileId: 1, // Using default profile for MVP
        accountId: _selectedAccountId!,
        categoryId: 1, // Using default category for MVP
        merchantId: 1, // Auto-generate merchant for MVP
        amountMinor: amountMinor,
        type: _selectedType,
        description: _merchantController.text.trim(),
        timestamp: DateTime.now(),
        confidenceScore: 100, // Manual entry gets 100% confidence
        requiresReview: false,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      // Submit via use case
      final createTransactionUseCase = ref.read(
        createTransactionUseCaseProvider,
      );
      final result = await createTransactionUseCase(transaction);

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction added successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear form and go back
          _formKey.currentState?.reset();
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.failureData?.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
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
