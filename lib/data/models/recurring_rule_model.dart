/// Recurring rule model for recurring transactions
class RecurringRuleModel {
  const RecurringRuleModel({
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
  final int amountMinor; // Always stored in minor units
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

  RecurringRuleModel copyWith({
    int? id,
    int? profileId,
    String? name,
    int? amountMinor,
    RecurringType? type,
    RecurringFrequency? frequency,
    DateTime? startDate,
    bool? isActive,
    String? description,
    int? categoryId,
    int? merchantId,
    int? accountId,
    DateTime? endDate,
    DateTime? lastExecutedDate,
    DateTime? nextExecutionDate,
  }) {
    return RecurringRuleModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      amountMinor: amountMinor ?? this.amountMinor,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      merchantId: merchantId ?? this.merchantId,
      accountId: accountId ?? this.accountId,
      endDate: endDate ?? this.endDate,
      lastExecutedDate: lastExecutedDate ?? this.lastExecutedDate,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurringRuleModel &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        other.amountMinor == amountMinor &&
        other.type == type &&
        other.frequency == frequency &&
        other.startDate == startDate &&
        other.isActive == isActive &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.merchantId == merchantId &&
        other.accountId == accountId &&
        other.endDate == endDate &&
        other.lastExecutedDate == lastExecutedDate &&
        other.nextExecutionDate == nextExecutionDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      name,
      amountMinor,
      type,
      frequency,
      startDate,
      isActive,
      description,
      categoryId,
      merchantId,
      accountId,
      endDate,
      lastExecutedDate,
      nextExecutionDate,
    );
  }
}

enum RecurringType {
  income,
  expense,
}

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

extension RecurringTypeExtension on RecurringType {
  String get name {
    switch (this) {
      case RecurringType.income:
        return 'income';
      case RecurringType.expense:
        return 'expense';
    }
  }
}

extension RecurringFrequencyExtension on RecurringFrequency {
  String get name {
    switch (this) {
      case RecurringFrequency.daily:
        return 'daily';
      case RecurringFrequency.weekly:
        return 'weekly';
      case RecurringFrequency.monthly:
        return 'monthly';
      case RecurringFrequency.yearly:
        return 'yearly';
    }
  }
}
