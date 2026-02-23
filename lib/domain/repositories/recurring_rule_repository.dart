import '../entities/recurring_rule.dart';
import '../repositories/transaction_repository.dart';
import '../../data/models/recurring_rule_model.dart';

/// Repository interface for recurring rule operations
abstract class RecurringRuleRepository {
  /// Create a new recurring rule
  Future<Result<RecurringRule>> createRecurringRule(RecurringRule rule);

  /// Update an existing recurring rule
  Future<Result<RecurringRule>> updateRecurringRule(RecurringRule rule);

  /// Delete a recurring rule
  Future<Result<void>> deleteRecurringRule(int ruleId);

  /// Get recurring rule by ID
  Future<Result<RecurringRule?>> getRecurringRuleById(int ruleId);

  /// Get recurring rules for a profile
  Future<Result<List<RecurringRule>>> getRecurringRules(
    int profileId, {
    bool? isActive,
    RecurringType? type,
    RecurringFrequency? frequency,
  });

  /// Get recurring rules due for execution
  Future<Result<List<RecurringRule>>> getDueRecurringRules(int profileId);

  /// Update next execution date for a rule
  Future<Result<RecurringRule>> updateNextExecutionDate(
    int ruleId,
    DateTime nextExecutionDate,
  );

  /// Update last executed date for a rule
  Future<Result<RecurringRule>> updateLastExecutedDate(
    int ruleId,
    DateTime lastExecutedDate,
  );

  /// Calculate next execution date based on frequency
  DateTime calculateNextExecutionDate(
    DateTime lastExecutionDate,
    RecurringFrequency frequency,
  );
}
