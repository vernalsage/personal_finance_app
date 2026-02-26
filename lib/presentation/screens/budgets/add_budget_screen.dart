import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_providers.dart';
import '../../providers/category_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/formatted_number_input.dart';
import '../../../domain/entities/budget.dart';
import '../../../main.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? _categoryId;
  int _amountMinor = 0;
  late int _month;
  late int _year;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and enter an amount')),
      );
      return;
    }

    try {
      final budget = Budget(
        id: 0,
        profileId: 1,
        categoryId: _categoryId!,
        amountMinor: _amountMinor,
        month: _month,
        year: _year,
        createdAt: DateTime.now(),
      );

      await ref.read(budgetsProvider.notifier).createBudget(budget);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Add Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Selection
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

              // Amount
              const Text('Monthly Limit', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FormattedNumberInput(
                controller: _amountController,
                onChanged: (val) {
                  final amount = double.tryParse(val) ?? 0.0;
                  _amountMinor = (amount * 100).toInt();
                },
                hintText: 'Enter amount',
              ),
              const SizedBox(height: 20),

              // Month/Year (Simplified for MVP)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Month', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _month,
                          items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.toString()),
                          )).toList(),
                          onChanged: (val) => setState(() => _month = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Year', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _year,
                          items: [2024, 2025, 2026].map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          )).toList(),
                          onChanged: (val) => setState(() => _year = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
