import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../../domain/usecases/budget_usecases.dart';
import '../../domain/usecases/execute_transfer_usecase.dart';
import '../../domain/usecases/goal_usecases.dart';
import '../../domain/usecases/recurring_rule_usecases.dart';
import '../../domain/usecases/insight_usecases.dart';
import '../../domain/usecases/account_usecases.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../domain/usecases/analytics_usecases.dart';

/// Provider for GetBudgetsUseCase
final getBudgetsUseCaseProvider = Provider<GetBudgetsUseCase>((ref) {
  return GetBudgetsUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider for GetBudgetUsageUseCase
final getBudgetUsageUseCaseProvider = Provider<GetBudgetUsageUseCase>((ref) {
  return GetBudgetUsageUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider for CreateBudgetUseCase
final createBudgetUseCaseProvider = Provider<CreateBudgetUseCase>((ref) {
  return CreateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider for UpdateBudgetUseCase
final updateBudgetUseCaseProvider = Provider<UpdateBudgetUseCase>((ref) {
  return UpdateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider for DeleteBudgetUseCase
final deleteBudgetUseCaseProvider = Provider<DeleteBudgetUseCase>((ref) {
  return DeleteBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider for GetTotalBudgetSummaryUseCase
final getTotalBudgetSummaryUseCaseProvider = Provider<GetTotalBudgetSummaryUseCase>((ref) {
  return GetTotalBudgetSummaryUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider for ExecuteTransferUseCase
final executeTransferUseCaseProvider = Provider<ExecuteTransferUseCase>((ref) {
  return ExecuteTransferUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
});

/// Provider for GetGoalsUseCase
final getGoalsUseCaseProvider = Provider<GetGoalsUseCase>((ref) {
  return GetGoalsUseCase(ref.watch(goalRepositoryProvider));
});

/// Provider for CreateGoalUseCase
final createGoalUseCaseProvider = Provider<CreateGoalUseCase>((ref) {
  return CreateGoalUseCase(ref.watch(goalRepositoryProvider));
});

/// Provider for UpdateGoalUseCase
final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>((ref) {
  return UpdateGoalUseCase(ref.watch(goalRepositoryProvider));
});

/// Provider for DeleteGoalUseCase
final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>((ref) {
  return DeleteGoalUseCase(ref.watch(goalRepositoryProvider));
});

/// Provider for GetGoalsNearingCompletionUseCase
final getGoalsNearingCompletionUseCaseProvider = Provider<GetGoalsNearingCompletionUseCase>((ref) {
  return GetGoalsNearingCompletionUseCase(ref.watch(goalRepositoryProvider));
});

/// Provider for GetRecurringRulesUseCase
final getRecurringRulesUseCaseProvider = Provider<GetRecurringRulesUseCase>((ref) {
  return GetRecurringRulesUseCase(ref.watch(recurringRuleRepositoryProvider));
});

/// Provider for CreateRecurringRuleUseCase
final createRecurringRuleUseCaseProvider = Provider<CreateRecurringRuleUseCase>((ref) {
  return CreateRecurringRuleUseCase(ref.watch(recurringRuleRepositoryProvider));
});

/// Provider for DeleteRecurringRuleUseCase
final deleteRecurringRuleUseCaseProvider = Provider<DeleteRecurringRuleUseCase>((ref) {
  return DeleteRecurringRuleUseCase(ref.watch(recurringRuleRepositoryProvider));
});

/// Provider for ProcessDueRulesUseCase
final processDueRulesUseCaseProvider = Provider<ProcessDueRulesUseCase>((ref) {
  return ProcessDueRulesUseCase(
    ref.watch(recurringRuleRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  );
});

/// Provider for GetExpenseBreakdownUseCase
final getExpenseBreakdownUseCaseProvider = Provider<GetExpenseBreakdownUseCase>((ref) {
  return GetExpenseBreakdownUseCase(ref.watch(transactionRepositoryProvider));
});

/// Provider for GetWeeklySpendingUseCase
final getWeeklySpendingUseCaseProvider = Provider<GetWeeklySpendingUseCase>((ref) {
  return GetWeeklySpendingUseCase(ref.watch(transactionRepositoryProvider));
});

/// Provider for get financial overview use case
final getFinancialOverviewUseCaseProvider = Provider<GetFinancialOverviewUseCase>((ref) {
  return GetFinancialOverviewUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});

/// Provider for calculate cash runway use case
final calculateCashRunwayUseCaseProvider = Provider<CalculateCashRunwayUseCase>((ref) {
  return CalculateCashRunwayUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});

/// Provider for get stability score use case
final getStabilityScoreUseCaseProvider = Provider<GetStabilityScoreUseCase>((ref) {
  return GetStabilityScoreUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});

// --- Account Use Cases ---

/// Provider for CreateAccountUseCase
final createAccountUseCaseProvider = Provider<CreateAccountUseCase>((ref) {
  return CreateAccountUseCase(ref.watch(accountRepositoryProvider));
});

/// Provider for UpdateAccountUseCase
final updateAccountUseCaseProvider = Provider<UpdateAccountUseCase>((ref) {
  return UpdateAccountUseCase(ref.watch(accountRepositoryProvider));
});

/// Provider for DeleteAccountUseCase
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(accountRepositoryProvider));
});

/// Provider for GetAccountsUseCase
final getAccountsUseCaseProvider = Provider<GetAccountsUseCase>((ref) {
  return GetAccountsUseCase(ref.watch(accountRepositoryProvider));
});

/// Provider for UpdateAccountBalanceUseCase
final updateAccountBalanceUseCaseProvider = Provider<UpdateAccountBalanceUseCase>((ref) {
  return UpdateAccountBalanceUseCase(ref.watch(accountRepositoryProvider));
});

// --- Transaction Use Cases ---

/// Provider for CreateTransactionUseCase
final createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>((ref) {
  return CreateTransactionUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(merchantRepositoryProvider),
  );
});

/// Provider for UpdateTransactionUseCase
final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((ref) {
  return UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

/// Provider for DeleteTransactionUseCase
final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((ref) {
  return DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

/// Provider for GetTransactionsRequiringReviewUseCase
final getTransactionsRequiringReviewUseCaseProvider = Provider<GetTransactionsRequiringReviewUseCase>((ref) {
  return GetTransactionsRequiringReviewUseCase(ref.watch(transactionRepositoryProvider));
});
