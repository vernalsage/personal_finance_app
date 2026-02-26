import '../entities/recurring_rule.dart';
import '../entities/transaction.dart';
import '../repositories/recurring_rule_repository.dart';
import '../repositories/itransaction_repository.dart';
import '../core/result.dart';

/// Use case to get all recurring rules for a profile
class GetRecurringRulesUseCase {
  final RecurringRuleRepository _repository;

  GetRecurringRulesUseCase(this._repository);

  Future<Result<List<RecurringRule>, Exception>> call(
    int profileId, {
    bool? isActive,
  }) {
    return _repository.getRecurringRules(profileId, isActive: isActive);
  }
}

/// Use case to create a new recurring rule
class CreateRecurringRuleUseCase {
  final RecurringRuleRepository _repository;

  CreateRecurringRuleUseCase(this._repository);

  Future<Result<RecurringRule, Exception>> call(RecurringRule rule) {
    return _repository.createRecurringRule(rule);
  }
}

/// Use case to delete a recurring rule
class DeleteRecurringRuleUseCase {
  final RecurringRuleRepository _repository;

  DeleteRecurringRuleUseCase(this._repository);

  Future<Result<void, Exception>> call(int ruleId) {
    return _repository.deleteRecurringRule(ruleId);
  }
}

/// Use case to process all due recurring rules and create transactions
class ProcessDueRulesUseCase {
  final RecurringRuleRepository _ruleRepository;
  final ITransactionRepository _transactionRepository;

  ProcessDueRulesUseCase(this._ruleRepository, this._transactionRepository);

  Future<Result<int, Exception>> call(int profileId) async {
    try {
      final dueRulesResult = await _ruleRepository.getDueRecurringRules(profileId);
      if (dueRulesResult.isFailure) return Failure(dueRulesResult.failureData!);

      final dueRules = dueRulesResult.successData!;
      int createdCount = 0;

      for (final rule in dueRules) {
        // Create the transaction based on the rule
        final transactionResult = await _transactionRepository.createTransaction(
          Transaction(
            id: 0,
            profileId: rule.profileId,
            accountId: rule.accountId ?? 0,
            categoryId: rule.categoryId ?? 0,
            merchantId: rule.merchantId ?? 0,
            amountMinor: rule.amountMinor,
            description: 'Recurring: ${rule.name}',
            type: rule.type == RecurringType.income ? 'credit' : 'debit',
            timestamp: DateTime.now(),
            requiresReview: false,
            confidenceScore: 100,
          ),
        );

        if (transactionResult.isSuccess) {
          createdCount++;
          
          // Update rule execution dates
          final now = DateTime.now();
          await _ruleRepository.updateLastExecutedDate(rule.id, now);
          
          final nextDate = _ruleRepository.calculateNextExecutionDate(
            rule.nextExecutionDate ?? DateTime.now(), // Use the scheduled date for next calculation to avoid drift
            rule.frequency,
          );
          await _ruleRepository.updateNextExecutionDate(rule.id, nextDate);
        }
      }

      return Success(createdCount);
    } catch (e) {
      return Failure(Exception('Failed to process recurring rules: $e'));
    }
  }
}
