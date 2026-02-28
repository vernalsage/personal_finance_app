import '../../data/models/budget_model.dart';

/// Budget entity for monthly budget tracking
class Budget {
  const Budget({
    required this.id,
    required this.profileId,
    required this.categoryId,
    required this.amountMinor,
    required this.month,
    required this.year,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int profileId;
  final int categoryId;
  final int amountMinor;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Create from model
  factory Budget.fromModel(BudgetModel model) {
    return Budget(
      id: model.id,
      profileId: model.profileId,
      categoryId: model.categoryId,
      amountMinor: model.amountMinor,
      month: model.month,
      year: model.year,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  /// Convert to model
  BudgetModel toModel() {
    return BudgetModel(
      id: id,
      profileId: profileId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      month: month,
      year: year,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Check if budget is for current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  /// Check if budget is for past month
  bool get isPastMonth {
    final now = DateTime.now();
    return year < now.year || (year == now.year && month < now.month);
  }

  /// Check if budget is for future month
  bool get isFutureMonth {
    final now = DateTime.now();
    return year > now.year || (year == now.year && month > now.month);
  }

  /// Get formatted period
  String get formattedPeriod {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  }

  /// Copy with changes
  Budget copyWith({
    int? id,
    int? profileId,
    int? categoryId,
    int? amountMinor,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Budget with its current usage status
class BudgetWithUsage {
  const BudgetWithUsage({
    required this.budget,
    required this.usage,
  });

  final Budget budget;
  final BudgetUsage usage;
}

/// Budget usage statistics
class BudgetUsage {
  const BudgetUsage({
    required this.budgetAmountMinor,
    required this.spentAmountMinor,
    required this.remainingAmountMinor,
    required this.usagePercentage,
    required this.isOverBudget,
    required this.isNearLimit,
  });

  final int budgetAmountMinor;
  final int spentAmountMinor;
  final int remainingAmountMinor;
  final double usagePercentage;
  final bool isOverBudget;
  final bool isNearLimit;
}
