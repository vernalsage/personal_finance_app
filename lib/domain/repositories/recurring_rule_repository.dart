import '../entities/recurring_rule.dart';
import '../../data/models/recurring_rule_model.dart';
import '../core/result.dart';

/// Repository interface for recurring rule operations
abstract class RecurringRuleRepository {
  /// Create a new recurring rule
  Future<Result<RecurringRule, Exception>> createRecurringRule(RecurringRule rule);

  /// Update an existing recurring rule
  Future<Result<RecurringRule, Exception>> updateRecurringRule(RecurringRule rule);

  /// Delete a recurring rule
  Future<Result<void, Exception>> deleteRecurringRule(int ruleId);

  /// Get recurring rule by ID
  Future<Result<RecurringRule?, Exception>> getRecurringRuleById(int ruleId);

  /// Get recurring rules for a profile
  Future<Result<List<RecurringRule>, Exception>> getRecurringRules(
    int profileId, {
    bool? isActive,
    RecurringType? type,
    RecurringFrequency? frequency,
  });

  /// Get recurring rules due for execution
  Future<Result<List<RecurringRule>, Exception>> getDueRecurringRules(int profileId);

  /// Update next execution date for a rule
  Future<Result<RecurringRule, Exception>> updateNextExecutionDate(
    int ruleId,
    DateTime nextExecutionDate,
  );

  /// Update last executed date for a rule
  Future<Result<RecurringRule, Exception>> updateLastExecutedDate(
    int ruleId,
    DateTime lastExecutedDate,
  );

  /// Calculate next execution date based on frequency
  DateTime calculateNextExecutionDate(
    DateTime lastExecutionDate,
    RecurringFrequency frequency,
  );
}
