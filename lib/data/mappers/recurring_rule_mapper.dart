import 'package:drift/drift.dart';
import '../database/app_database_simple.dart';
import '../../domain/entities/recurring_rule.dart' as domain;

/// Extension methods to map between Drift RecurringRule and Domain RecurringRule
extension RecurringRuleMapper on RecurringRule {
  /// Convert Drift RecurringRule to Domain RecurringRule
  domain.RecurringRule toEntity() {
    return domain.RecurringRule(
      id: id,
      profileId: profileId,
      name: name,
      amountMinor: amountMinor,
      type: domain.RecurringType.values.firstWhere((e) => e.name == type, orElse: () => domain.RecurringType.expense),
      frequency: domain.RecurringFrequency.values.firstWhere((e) => e.name == frequency, orElse: () => domain.RecurringFrequency.monthly),
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
}

/// Extension methods to map from Domain RecurringRule to Drift objects
extension DomainRecurringRuleMapper on domain.RecurringRule {
  /// Convert Domain RecurringRule to Drift RecurringRulesCompanion for inserts
  RecurringRulesCompanion toCompanion() {
    return RecurringRulesCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      profileId: Value(profileId),
      name: Value(name),
      amountMinor: Value(amountMinor),
      type: Value(type.name),
      frequency: Value(frequency.name),
      startDate: Value(startDate),
      isActive: Value(isActive),
      description: description != null ? Value(description!) : const Value.absent(),
      categoryId: categoryId != null ? Value(categoryId!) : const Value.absent(),
      merchantId: merchantId != null ? Value(merchantId!) : const Value.absent(),
      accountId: accountId != null ? Value(accountId!) : const Value.absent(),
      endDate: endDate != null ? Value(endDate!) : const Value.absent(),
      lastExecutedDate: lastExecutedDate != null ? Value(lastExecutedDate!) : const Value.absent(),
      nextExecutionDate: nextExecutionDate != null ? Value(nextExecutionDate!) : const Value.absent(),
    );
  }

  /// Convert Domain RecurringRule to Drift RecurringRulesCompanion for updates
  RecurringRulesCompanion toUpdateCompanion() {
    return RecurringRulesCompanion(
      name: Value(name),
      amountMinor: Value(amountMinor),
      type: Value(type.name),
      frequency: Value(frequency.name),
      startDate: Value(startDate),
      isActive: Value(isActive),
      description: description != null ? Value(description!) : const Value.absent(),
      categoryId: categoryId != null ? Value(categoryId!) : const Value.absent(),
      merchantId: merchantId != null ? Value(merchantId!) : const Value.absent(),
      accountId: accountId != null ? Value(accountId!) : const Value.absent(),
      endDate: endDate != null ? Value(endDate!) : const Value.absent(),
      lastExecutedDate: lastExecutedDate != null ? Value(lastExecutedDate!) : const Value.absent(),
      nextExecutionDate: nextExecutionDate != null ? Value(nextExecutionDate!) : const Value.absent(),
    );
  }
}
