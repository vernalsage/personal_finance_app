/// Budget model for monthly budget tracking
class BudgetModel {
  const BudgetModel({
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
  final int amountMinor; // Always stored in minor units
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BudgetModel copyWith({
    int? id,
    int? profileId,
    int? categoryId,
    int? amountMinor,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetModel &&
        other.id == id &&
        other.profileId == profileId &&
        other.categoryId == categoryId &&
        other.amountMinor == amountMinor &&
        other.month == month &&
        other.year == year &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      categoryId,
      amountMinor,
      month,
      year,
      createdAt,
      updatedAt,
    );
  }
}
