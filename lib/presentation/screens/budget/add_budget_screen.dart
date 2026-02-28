import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/category_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/formatted_number_input.dart';
import '../../../domain/entities/budget.dart';
import '../../../core/style/app_colors.dart';
import '../../../main.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final int? categoryId;
  final int? existingAmountMinor;
  final int? month;
  final int? year;

  const AddBudgetScreen({
    super.key,
    this.categoryId,
    this.existingAmountMinor,
    this.month,
    this.year,
  });

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  int? _categoryId;
  int _amountMinor = 0;
  late int _month;
  late int _year;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = widget.month ?? now.month;
    _year = widget.year ?? now.year;
    _categoryId = widget.categoryId;
    _amountMinor = widget.existingAmountMinor ?? 0;
    
    _amountController = TextEditingController(
      text: widget.existingAmountMinor != null 
          ? (widget.existingAmountMinor! / 100.0).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and enter an amount')),
      );
      return;
    }

    try {
      final profile = ref.read(activeProfileProvider).value;
      if (profile == null) throw Exception('No active profile found');

      final budget = Budget(
        id: 0,
        profileId: profile.id,
        categoryId: _categoryId!,
        amountMinor: _amountMinor,
        month: _month,
        year: _year,
        createdAt: DateTime.now(),
      );

      await ref.read(budgetOverviewProvider.notifier).createBudget(budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.categoryId != null;

    return Scaffold(
      backgroundColor: AppColors.background(Theme.of(context).brightness == Brightness.dark),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Budget' : 'Add Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEditing) ...[
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
              ],

              // Amount
              Text(
                isEditing ? 'Update Monthly Limit' : 'Monthly Limit', 
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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

              // Month/Year
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
                            child: Text(_monthNames[m - 1]),
                          )).toList(),
                          onChanged: isEditing ? null : (val) => setState(() => _month = val!),
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
                          onChanged: isEditing ? null : (val) => setState(() => _year = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Note: Budgets are set per month. Existing limits for the same period will be updated.',
                style: TextStyle(
                  fontSize: 12, 
                  color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark), 
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Update Budget' : 'Save Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
