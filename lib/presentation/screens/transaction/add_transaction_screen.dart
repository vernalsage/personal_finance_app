import 'package:flutter/material.dart';
import '../../../core/style/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart' as providers;
import '../../providers/category_providers.dart';
import '../../providers/merchant_providers.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/di/repository_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;

  late String _selectedType;
  int? _selectedAccountId;
  int? _selectedCategoryId;
  int? _selectedMerchantId;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    
    _amountController = TextEditingController(
      text: t != null ? (t.amountMinor.abs() / 100.0).toStringAsFixed(2) : '',
    );
    _merchantController = TextEditingController(text: t?.description ?? '');
    _noteController = TextEditingController(text: t?.note ?? '');
    _selectedDate = t?.timestamp ?? DateTime.now();
    _dateController = TextEditingController(
      text: DateFormat('MMM dd, yyyy').format(_selectedDate),
    );
    
    _selectedType = t?.type ?? 'debit';
    _selectedAccountId = t?.accountId;
    _selectedCategoryId = t?.categoryId;
    _selectedMerchantId = t?.merchantId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);

    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isEditing && widget.transaction!.isTransfer)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.warning),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'This transaction is part of a transfer. To maintain balance integrity, the Account and Type cannot be changed.',
                            style: TextStyle(fontSize: 13, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Account Selection
                Text('Account', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Select Account',
                    border: OutlineInputBorder(),
                  ),
                  items: accountsState.accounts.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(
                        '${account.name} (${CurrencyUtils.formatMinorToDisplay(account.balanceMinor, account.currency)})',
                      ),
                    );
                  }).toList(),
                  onChanged: (isEditing && widget.transaction!.isTransfer) ? null : (value) {
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
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'debit',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Debit'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'credit',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, color: AppColors.success),
                          SizedBox(width: 8),
                          Text('Credit'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'transfer_out',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, color: AppColors.warning),
                          SizedBox(width: 8),
                          Text('Transfer (Out)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'transfer_in',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Transfer (In)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (isEditing && widget.transaction!.isTransfer) ? null : (value) {
                    setState(() {
                      _selectedType = value ?? 'debit';
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Category Selection
                Text('Category', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ref.watch(categoriesProvider).when(
                  data: (categories) => DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Select Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Please select a category' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => Text('Error loading categories: $err'),
                ),
                const SizedBox(height: 24),

                // Amount Field
                (){
                  final selectedAccount = accountsState.accounts.firstWhereOrNull((a) => a.id == _selectedAccountId);
                  final currency = selectedAccount?.currency ?? 'NGN';
                  final symbol = CurrencyUtils.getCurrencySymbol(currency);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount ($symbol)',
                          prefixText: symbol,
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
                    ],
                  );
                }(),
                const SizedBox(height: 24),

                // Date Field
                Text('Date', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Transaction Date',
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Merchant/Description Field
                Text(
                  'Merchant / Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
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
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
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
                        : Text(isEditing ? 'Update Transaction' : 'Add Transaction'),
                  ),
                ),
                ],
              ),
            ),
          ],
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
      final isEditing = widget.transaction != null;
      final profileId = widget.transaction?.profileId ?? 1;

      // 1. Get or create merchant based on description
      final description = _merchantController.text.trim();
      final merchantRepo = ref.read(merchantRepositoryProvider);
      final normalizedName = merchantRepo.normalizeMerchantName(description);
      
      final merchantResult = await merchantRepo.getOrCreateMerchant(
        profileId,
        description,
        normalizedName,
        categoryId: _selectedCategoryId,
      );

      if (merchantResult.isFailure) {
        throw merchantResult.failureData!;
      }
      
      final merchantId = merchantResult.successData!.id;

      // 2. Convert amount string to minor units
      final amountMinor = CurrencyUtils.formatAmountToMinor(
        _amountController.text,
      );

      // 3. Create/Update transaction entity
      final transaction = Transaction(
        id: widget.transaction?.id ?? 0,
        profileId: profileId,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId ?? 1,
        merchantId: merchantId,
        amountMinor: amountMinor,
        type: _selectedType,
        description: description,
        timestamp: _selectedDate,
        confidenceScore: 100,
        requiresReview: false,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      if (isEditing) {
        await ref.read(providers.transactionsProvider.notifier).updateTransaction(transaction);
      } else {
        await ref.read(providers.transactionsProvider.notifier).addTransaction(transaction);
      }
      
      final transactionsState = ref.read(providers.transactionsProvider);

      if (mounted) {
        if (transactionsState.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'Transaction updated successfully' : 'Transaction added successfully'),
              backgroundColor: AppColors.success,
            ),
          );

          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${transactionsState.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
