import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/recurring_rules_table.dart';

part 'recurring_rules_dao.g.dart';

@DriftAccessor(tables: [RecurringRules])
class RecurringRulesDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRulesDaoMixin {
  RecurringRulesDao(super.db);

  Future<RecurringRule> createRecurringRule(RecurringRulesCompanion entry) =>
      into(recurringRules).insertReturning(entry);
  Future<RecurringRule> getRecurringRule(int id) =>
      (select(recurringRules)..where((r) => r.id.equals(id))).getSingle();
  Future<List<RecurringRule>> getAllRecurringRules({
    int? profileId,
    bool? isActive,
  }) {
    final query = select(recurringRules);
    if (profileId != null) query.where((r) => r.profileId.equals(profileId));
    if (isActive != null) query.where((r) => r.isActive.equals(isActive));
    return query.get();
  }

  Future<RecurringRule> updateRecurringRule(RecurringRulesCompanion entry) =>
      update(
        recurringRules,
      ).writeReturning(entry).then((recurringRules) => recurringRules.first);
  Future<int> deleteRecurringRule(int id) =>
      (delete(recurringRules)..where((r) => r.id.equals(id))).go();

  Future<List<RecurringRule>> getRulesDueForExecution(DateTime currentDate) {
    return (select(recurringRules)..where(
          (r) =>
              r.isActive.equals(true) &
              r.nextExecutionDate.isSmallerOrEqualValue(currentDate),
        ))
        .get();
  }

  Future<void> updateLastExecutedDate(int ruleId, DateTime executedDate) {
    return (update(recurringRules)..where((r) => r.id.equals(ruleId))).write(
      RecurringRulesCompanion(
        lastExecutedDate: Value(executedDate),
        nextExecutionDate: Value(
          _calculateNextExecutionDate(ruleId, executedDate),
        ),
      ),
    );
  }

  DateTime _calculateNextExecutionDate(int ruleId, DateTime lastExecuted) {
    // TODO: Implement proper date calculation based on frequency
    // For now, just add 1 day as placeholder
    return lastExecuted.add(const Duration(days: 1));
  }
}
