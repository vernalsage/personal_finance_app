import 'package:drift/drift.dart';
import '../database/app_database_simple.dart';
import '../../domain/entities/goal.dart' as domain;

/// Extension methods to map between Drift Goal and Domain Goal
extension GoalMapper on Goal {
  /// Convert Drift Goal to Domain Goal
  domain.Goal toEntity() {
    return domain.Goal(
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
}

/// Extension methods to map from Domain Goal to Drift objects
extension DomainGoalMapper on domain.Goal {
  /// Convert Domain Goal to Drift GoalsCompanion for inserts
  GoalsCompanion toCompanion() {
    return GoalsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      profileId: Value(profileId),
      name: Value(name),
      targetAmountMinor: Value(targetAmountMinor),
      currentAmountMinor: Value(currentAmountMinor),
      targetDate: Value(targetDate),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      description: description != null ? Value(description!) : const Value.absent(),
      updatedAt: updatedAt != null ? Value(updatedAt!) : const Value.absent(),
    );
  }

  /// Convert Domain Goal to Drift GoalsCompanion for updates
  GoalsCompanion toUpdateCompanion() {
    return GoalsCompanion(
      name: Value(name),
      targetAmountMinor: Value(targetAmountMinor),
      currentAmountMinor: Value(currentAmountMinor),
      targetDate: Value(targetDate),
      isActive: Value(isActive),
      description: description != null ? Value(description!) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
  }
}
