import '../../data/models/recurring_rule_model.dart';

/// Recurring rule entity for recurring transactions
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.profileId,
    required this.name,
    required this.amountMinor,
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.isActive,
    this.description,
    this.categoryId,
    this.merchantId,
    this.accountId,
    this.endDate,
    this.lastExecutedDate,
    this.nextExecutionDate,
  });

  final int id;
  final int profileId;
  final String name;
  final int amountMinor;
  final RecurringType type;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final bool isActive;
  final String? description;
  final int? categoryId;
  final int? merchantId;
  final int? accountId;
  final DateTime? endDate;
  final DateTime? lastExecutedDate;
  final DateTime? nextExecutionDate;

  /// Create from model
  factory RecurringRule.fromModel(RecurringRuleModel model) {
    return RecurringRule(
      id: model.id,
      profileId: model.profileId,
      name: model.name,
      amountMinor: model.amountMinor,
      type: model.type,
      frequency: model.frequency,
      startDate: model.startDate,
      isActive: model.isActive,
      description: model.description,
      categoryId: model.categoryId,
      merchantId: model.merchantId,
      accountId: model.accountId,
      endDate: model.endDate,
      lastExecutedDate: model.lastExecutedDate,
      nextExecutionDate: model.nextExecutionDate,
    );
  }

  /// Convert to model
  RecurringRuleModel toModel() {
    return RecurringRuleModel(
      id: id,
      profileId: profileId,
      name: name,
      amountMinor: amountMinor,
      type: type,
      frequency: frequency,
      startDate: startDate,
      isActive: isActive,
      description: description,
      categoryId: categoryId,
      merchantId: merchantId,
      accountId: accountId,
      endDate: endDate,
      lastExecutedDate: lastExecutedDate,
      nextExecutionDate: nextExecutionDate,
    );
  }

  /// Check if rule is active
  bool get isInactive => !isActive;

  /// Check if rule is due for execution
  bool get isDueForExecution {
    if (!isActive) return false;
    if (nextExecutionDate == null) return false;
    return DateTime.now().isAfter(nextExecutionDate!);
  }

  /// Check if rule has ended
  bool get hasEnded {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Check if rule is overdue for execution
  bool get isOverdue {
    if (!isDueForExecution) return false;
    if (nextExecutionDate == null) return false;
    final daysOverdue = DateTime.now().difference(nextExecutionDate!).inDays;
    return daysOverdue > 0;
  }
}
