import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recurring_rule_providers.dart';
import '../../providers/category_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/formatted_number_input.dart';
import '../../../domain/entities/recurring_rule.dart';
import '../../../main.dart';
import '../../providers/account_providers.dart';

class AddRecurringRuleScreen extends ConsumerStatefulWidget {
  const AddRecurringRuleScreen({super.key});

  @override
  ConsumerState<AddRecurringRuleScreen> createState() => _AddRecurringRuleScreenState();
}

class _AddRecurringRuleScreenState extends ConsumerState<AddRecurringRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  int? _accountId;
  int? _categoryId;
  int _amountMinor = 0;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  RecurringType _type = RecurringType.expense;
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _accountId == null || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final rule = RecurringRule(
        id: 0,
        profileId: 1,
        accountId: _accountId,
        categoryId: _categoryId,
        name: _nameController.text.trim(),
        amountMinor: _amountMinor,
        type: _type,
        frequency: _frequency,
        startDate: _startDate,
        nextExecutionDate: _startDate,
        isActive: true,
      );

      await ref.read(recurringRulesProvider.notifier).createRule(rule);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Add Recurring Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g., Netflix, Rent, Internet'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<RecurringType>(
                          value: _type,
                          items: RecurringType.values.map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toString().split('.').last.toUpperCase()),
                          )).toList(),
                          onChanged: (val) => setState(() => _type = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<RecurringFrequency>(
                          value: _frequency,
                          items: RecurringFrequency.values.map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.toString().split('.').last.toUpperCase()),
                          )).toList(),
                          onChanged: (val) => setState(() => _frequency = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              accountsAsync.isLoading
                ? const LoadingWidget()
                : accountsAsync.error != null
                  ? Text('Error loading accounts: ${accountsAsync.error}')
                  : DropdownButtonFormField<int>(
                      decoration: const InputDecoration(hintText: 'Select Account'),
                      value: _accountId,
                      items: accountsAsync.accounts.map<DropdownMenuItem<int>>((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      )).toList(),
                      onChanged: (val) => setState(() => _accountId = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
              const SizedBox(height: 20),

              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(hintText: 'Select Category'),
                  value: _categoryId,
                  items: categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (val) => setState(() => _categoryId = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                loading: () => const LoadingWidget(),
                error: (err, _) => Text('Error loading categories: $err'),
              ),
              const SizedBox(height: 20),

              const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FormattedNumberInput(
                controller: _amountController,
                onChanged: (val) {
                  final amount = double.tryParse(val) ?? 0.0;
                  _amountMinor = (amount * 100).toInt();
                },
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _save,
                child: const Text('Create Rule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
