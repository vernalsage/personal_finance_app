// This file is commented out because workmanager dependency was removed
// TODO: Re-implement background processing with a different solution if needed
/*
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/recurring_rules_dao.dart';

/// Top-level callback dispatcher function required by WorkManager
/// This function runs in the background and processes recurring rules
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('WorkManager: Executing background task: $task');

      // Initialize the database for background execution
      final database = AppDatabase();

      // Create DAO instances
      final recurringRulesDao = RecurringRulesDao(database);

      // Get current time
      final now = DateTime.now();

      // Query for all active rules where nextExecutionDate is less than or equal to now
      final activeRules = await recurringRulesDao.getRulesDueForExecution(now);

      debugPrint(
        'WorkManager: Found ${activeRules.length} recurring rules to process',
      );

      // Process each rule in a single database transaction for atomicity
      await database.transaction(() async {
        for (final rule in activeRules) {
          try {
            // Generate a new Transaction entity using the rule's details
            final transaction = await database.transactions.insertReturning(
              TransactionsCompanion.insert(
                profileId: rule.profileId,
                accountId: rule.accountId ?? 1, // Default to 1 if null
                categoryId: rule.categoryId ?? 1, // Default to 1 if null
                merchantId: rule.merchantId ?? 1, // Default to 1 if null
                amountMinor: rule.amountMinor,
                type: rule.type,
                description: rule.description ?? 'Recurring Transaction',
                timestamp: now,
                confidenceScore: const Value(
                  100,
                ), // Recurring transactions get 100% confidence
                requiresReview: const Value(
                  false,
                ), // Recurring transactions don't require review
              ),
            );

            // Update the rule's lastExecutedDate and nextExecutionDate
            await recurringRulesDao.updateLastExecutedDate(rule.id, now);

            debugPrint(
              'WorkManager: Processed recurring rule ${rule.id}, created transaction ${transaction.id}',
            );
          } catch (e) {
            debugPrint('WorkManager: Error processing rule ${rule.id}: $e');
            // Continue with other rules even if one fails
          }
        }
      });

      // Close the database connection
      await database.close();

      debugPrint('WorkManager: Background task completed successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('WorkManager: Background task failed: $e');
      return Future.value(false);
    }
  });
}
*/
