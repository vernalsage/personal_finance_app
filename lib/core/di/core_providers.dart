import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database_simple.dart';
import '../../data/database/daos/accounts_dao.dart';
import '../../data/database/daos/transactions_dao.dart';
import '../../data/database/daos/merchants_dao.dart';
import '../../data/database/daos/categories_dao.dart';
import '../../data/database/daos/profiles_dao.dart';
import '../../data/database/daos/budgets_dao.dart';
import '../../data/database/daos/goals_dao.dart';
import '../../data/database/daos/recurring_rules_dao.dart';
import '../../data/database/daos/tags_dao.dart';
import '../../data/database/daos/notification_fingerprints_dao.dart';

/// Global provider for the Drift AppDatabase
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for Accounts DAO
final accountsDaoProvider = Provider<AccountsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountsDao(db);
});

/// Provider for Transactions DAO
final transactionsDaoProvider = Provider<TransactionsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionsDao(db);
});

/// Provider for Merchants DAO
final merchantsDaoProvider = Provider<MerchantsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return MerchantsDao(db);
});

/// Provider for Categories DAO
final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoriesDao(db);
});

/// Provider for Profiles DAO
final profilesDaoProvider = Provider<ProfilesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ProfilesDao(db);
});

/// Provider for Budgets DAO
final budgetsDaoProvider = Provider<BudgetsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetsDao(db);
});

/// Provider for Goals DAO
final goalsDaoProvider = Provider<GoalsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return GoalsDao(db);
});

/// Provider for Recurring Rules DAO
final recurringRulesDaoProvider = Provider<RecurringRulesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return RecurringRulesDao(db);
});

/// Provider for Tags DAO
final tagsDaoProvider = Provider<TagsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TagsDao(db);
});

/// Provider for Notification Fingerprints DAO
final notificationFingerprintsDaoProvider = Provider<NotificationFingerprintsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationFingerprintsDao(db);
});
