import '../../data/models/goal_model.dart';

/// Goal entity for financial goal tracking
class Goal {
  const Goal({
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
  final int targetAmountMinor;
  final int currentAmountMinor;
  final DateTime targetDate;
  final bool isActive;
  final DateTime createdAt;
  final String? description;
  final DateTime? updatedAt;

  /// Create from model
  factory Goal.fromModel(GoalModel model) {
    return Goal(
      id: model.id,
      profileId: model.profileId,
      name: model.name,
      targetAmountMinor: model.targetAmountMinor,
      currentAmountMinor: model.currentAmountMinor,
      targetDate: model.targetDate,
      isActive: model.isActive,
      createdAt: model.createdAt,
      description: model.description,
      updatedAt: model.updatedAt,
    );
  }

  /// Convert to model
  GoalModel toModel() {
    return GoalModel(
      id: id,
      profileId: profileId,
      name: name,
      targetAmountMinor: targetAmountMinor,
      currentAmountMinor: currentAmountMinor,
      targetDate: targetDate,
      isActive: isActive,
      createdAt: createdAt,
      description: description,
      updatedAt: updatedAt,
    );
  }

  /// Check if goal is active
  bool get isInactive => !isActive;

  /// Check if goal is completed
  bool get isCompleted => currentAmountMinor >= targetAmountMinor;

  /// Get completion percentage (0-100)
  double get completionPercentage {
    if (targetAmountMinor == 0) return 0.0;
    return (currentAmountMinor / targetAmountMinor * 100).clamp(0.0, 100.0);
  }

  /// Get remaining amount
  int get remainingAmount => (targetAmountMinor - currentAmountMinor).clamp(0, targetAmountMinor);

  /// Check if goal is overdue
  bool get isOverdue {
    return !isCompleted && DateTime.now().isAfter(targetDate);
  }

  /// Get days remaining until target date
  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  /// Check if goal is due soon (within 7 days)
  bool get isDueSoon {
    return !isCompleted && daysRemaining <= 7 && daysRemaining >= 0;
  }
}
