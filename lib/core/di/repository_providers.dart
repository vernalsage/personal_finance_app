import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/itransaction_repository.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/recurring_rule_repository.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/inotification_fingerprint_repository.dart';
import '../../data/repositories/notification_fingerprint_repository_impl.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/merchant_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../data/repositories/recurring_rule_repository_impl.dart';
import '../../data/repositories/tag_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';

/// Provider for Profile Repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profilesDaoProvider));
});

/// Provider for Account Repository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(ref.watch(accountsDaoProvider));
});

/// Provider for Transaction Repository
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(transactionsDaoProvider));
});

/// Provider for Merchant Repository
final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepositoryImpl(ref.watch(merchantsDaoProvider));
});

/// Provider for Category Repository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoriesDaoProvider));
});

/// Provider for Budget Repository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(
    ref.watch(budgetsDaoProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});

/// Provider for Goal Repository
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(ref.watch(goalsDaoProvider));
});

/// Provider for Recurring Rule Repository
final recurringRuleRepositoryProvider = Provider<RecurringRuleRepository>((ref) {
  return RecurringRuleRepositoryImpl(ref.watch(recurringRulesDaoProvider));
});

/// Provider for Tag Repository
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepositoryImpl(ref.watch(tagsDaoProvider));
});

/// Provider for Notification Fingerprint Repository
final notificationFingerprintRepositoryProvider = Provider<INotificationFingerprintRepository>((ref) {
  return NotificationFingerprintRepositoryImpl(ref.watch(notificationFingerprintsDaoProvider));
});
