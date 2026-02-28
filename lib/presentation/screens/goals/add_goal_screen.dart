import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/goal_providers.dart';
import '../../widgets/formatted_number_input.dart';
import '../../../domain/entities/goal.dart';
import '../../../core/style/app_colors.dart';
import '../../../main.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  int _targetAmountMinor = 0;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _targetAmountMinor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and target amount')),
      );
      return;
    }

    try {
      final goal = Goal(
        id: 0,
        profileId: 1,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        targetAmountMinor: _targetAmountMinor,
        currentAmountMinor: 0,
        targetDate: _targetDate,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await ref.read(goalsProvider.notifier).createGoal(goal);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(Theme.of(context).brightness == Brightness.dark),
      appBar: AppBar(
        title: const Text('Set a Goal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Goal Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g., New Car, Emergency Fund'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              const Text('Description (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(hintText: 'Why are you saving for this?'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              const Text('Target Amount', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FormattedNumberInput(
                controller: _amountController,
                onChanged: (val) {
                  final amount = double.tryParse(val) ?? 0.0;
                  _targetAmountMinor = (amount * 100).toInt();
                },
                hintText: 'How much do you need?',
              ),
              const SizedBox(height: 20),

              const Text('Target Date', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(Theme.of(context).brightness == Brightness.dark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(Theme.of(context).brightness == Brightness.dark)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _save,
                child: const Text('Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
