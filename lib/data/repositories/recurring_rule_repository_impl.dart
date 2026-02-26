import '../database/daos/recurring_rules_dao.dart';
import '../models/recurring_rule_model.dart';
import '../mappers/recurring_rule_mapper.dart';
import '../../domain/repositories/recurring_rule_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/recurring_rule.dart' as domain;

/// Implementation of RecurringRuleRepository using Drift DAO
class RecurringRuleRepositoryImpl implements RecurringRuleRepository {
  final RecurringRulesDao _recurringRulesDao;

  RecurringRuleRepositoryImpl(this._recurringRulesDao);

  @override
  Future<Result<domain.RecurringRule, Exception>> createRecurringRule(
    domain.RecurringRule rule,
  ) async {
    try {
      final companion = rule.toCompanion();
      final createdRule = await _recurringRulesDao.createRecurringRule(companion);
      return Success(createdRule.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to create recurring rule: $e'));
    }
  }

  @override
  Future<Result<domain.RecurringRule, Exception>> updateRecurringRule(
    domain.RecurringRule rule,
  ) async {
    try {
      final companion = rule.toUpdateCompanion();
      final updatedRule = await _recurringRulesDao.updateRecurringRule(companion);
      return Success(updatedRule.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update recurring rule: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> deleteRecurringRule(int ruleId) async {
    try {
      await _recurringRulesDao.deleteRecurringRule(ruleId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to delete recurring rule: $e'));
    }
  }

  @override
  Future<Result<domain.RecurringRule?, Exception>> getRecurringRuleById(int ruleId) async {
    try {
      final rule = await _recurringRulesDao.getRecurringRule(ruleId);
      return Success(rule?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get recurring rule by ID: $e'));
    }
  }

  @override
  Future<Result<List<domain.RecurringRule>, Exception>> getRecurringRules(
    int profileId, {
    bool? isActive,
    domain.RecurringType? type,
    domain.RecurringFrequency? frequency,
  }) async {
    try {
      final rules = await _recurringRulesDao.getAllRecurringRules(
        profileId: profileId,
        isActive: isActive,
      );
      
      var domainRules = rules.map((r) => r.toEntity()).toList();
      
      if (type != null) {
        domainRules = domainRules.where((r) => r.type == type).toList();
      }
      if (frequency != null) {
        domainRules = domainRules.where((r) => r.frequency == frequency).toList();
      }
      
      return Success(domainRules);
    } catch (e) {
      return Failure(Exception('Failed to get recurring rules: $e'));
    }
  }

  @override
  Future<Result<List<domain.RecurringRule>, Exception>> getDueRecurringRules(
    int profileId,
  ) async {
    try {
      final rules = await _recurringRulesDao.getDueRecurringRules(profileId);
      return Success(rules.map((r) => r.toEntity()).toList());
    } catch (e) {
      return Failure(Exception('Failed to get due recurring rules: $e'));
    }
  }

  @override
  Future<Result<domain.RecurringRule, Exception>> updateNextExecutionDate(
    int ruleId,
    DateTime nextExecutionDate,
  ) async {
    try {
      await _recurringRulesDao.updateNextExecutionDate(ruleId, nextExecutionDate);
      final updatedRule = await _recurringRulesDao.getRecurringRule(ruleId);
      return Success(updatedRule!.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update next execution date: $e'));
    }
  }

  @override
  Future<Result<domain.RecurringRule, Exception>> updateLastExecutedDate(
    int ruleId,
    DateTime lastExecutedDate,
  ) async {
    try {
      await _recurringRulesDao.updateLastExecutedDate(ruleId, lastExecutedDate);
      final updatedRule = await _recurringRulesDao.getRecurringRule(ruleId);
      return Success(updatedRule!.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update last executed date: $e'));
    }
  }

  @override
  DateTime calculateNextExecutionDate(
    DateTime lastExecutionDate,
    domain.RecurringFrequency frequency,
  ) {
    switch (frequency) {
      case domain.RecurringFrequency.daily:
        return lastExecutionDate.add(const Duration(days: 1));
      case domain.RecurringFrequency.weekly:
        return lastExecutionDate.add(const Duration(days: 7));
      case domain.RecurringFrequency.monthly:
        return DateTime(
          lastExecutionDate.year,
          lastExecutionDate.month + 1,
          lastExecutionDate.day,
        );
      case domain.RecurringFrequency.yearly:
        return DateTime(
          lastExecutionDate.year + 1,
          lastExecutionDate.month,
          lastExecutionDate.day,
        );
      default:
        return lastExecutionDate;
    }
  }
}
