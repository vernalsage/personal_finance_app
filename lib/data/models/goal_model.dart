/// Goal model for financial goal tracking
class GoalModel {
  const GoalModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.targetAmountMinor,
    required this.currentAmountMinor,
    required this.targetDate,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.updatedAt,
  });

  final int id;
  final int profileId;
  final String name;
  final int targetAmountMinor; // Always stored in minor units
  final int currentAmountMinor; // Cached value, recalculated from transactions
  final DateTime targetDate;
  final bool isActive;
  final DateTime createdAt;
  final String? description;
  final DateTime? updatedAt;

  GoalModel copyWith({
    int? id,
    int? profileId,
    String? name,
    int? targetAmountMinor,
    int? currentAmountMinor,
    DateTime? targetDate,
    bool? isActive,
    DateTime? createdAt,
    String? description,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      targetAmountMinor: targetAmountMinor ?? this.targetAmountMinor,
      currentAmountMinor: currentAmountMinor ?? this.currentAmountMinor,
      targetDate: targetDate ?? this.targetDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalModel &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        other.targetAmountMinor == targetAmountMinor &&
        other.currentAmountMinor == currentAmountMinor &&
        other.targetDate == targetDate &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.description == description &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      name,
      targetAmountMinor,
      currentAmountMinor,
      targetDate,
      isActive,
      createdAt,
      description,
      updatedAt,
    );
  }
}
