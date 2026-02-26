import 'package:drift/drift.dart';
import '../database/app_database_simple.dart';
import '../../domain/entities/budget.dart' as domain;

/// Extension methods to map between Drift Budget and Domain Budget
extension BudgetMapper on Budget {
  /// Convert Drift Budget to Domain Budget
  domain.Budget toEntity() {
    return domain.Budget(
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
}

/// Extension methods to map from Domain Budget to Drift objects
extension DomainBudgetMapper on domain.Budget {
  /// Convert Domain Budget to Drift BudgetsCompanion for inserts
  BudgetsCompanion toCompanion() {
    return BudgetsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      profileId: Value(profileId),
      categoryId: Value(categoryId),
      amountMinor: Value(amountMinor),
      month: Value(month),
      year: Value(year),
      createdAt: Value(createdAt),
      updatedAt: updatedAt != null ? Value(updatedAt!) : const Value.absent(),
    );
  }

  /// Convert Domain Budget to Drift BudgetsCompanion for updates
  BudgetsCompanion toUpdateCompanion() {
    return BudgetsCompanion(
      amountMinor: Value(amountMinor),
      month: Value(month),
      year: Value(year),
      updatedAt: Value(DateTime.now()),
    );
  }
}
