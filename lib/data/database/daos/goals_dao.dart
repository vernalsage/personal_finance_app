import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/goals_table.dart';
import '../tables/transaction_goals_table.dart';
import '../tables/transactions_table.dart';

part 'goals_dao.g.dart';

@DriftAccessor(tables: [Goals, TransactionGoals, Transactions])
class GoalsDao extends DatabaseAccessor<AppDatabase> with _$GoalsDaoMixin {
  GoalsDao(super.db);

  Future<Goal> createGoal(GoalsCompanion entry) =>
      into(goals).insertReturning(entry);
  Future<Goal> getGoal(int id) =>
      (select(goals)..where((g) => g.id.equals(id))).getSingle();
  Future<List<Goal>> getAllGoals({int? profileId, bool? isActive}) {
    final query = select(goals);
    if (profileId != null) query.where((g) => g.profileId.equals(profileId));
    if (isActive != null) query.where((g) => g.isActive.equals(isActive));
    return query.get();
  }

  Future<Goal> updateGoal(GoalsCompanion entry) =>
      update(goals).writeReturning(entry).then((goals) => goals.first);
  Future<int> deleteGoal(int id) =>
      (delete(goals)..where((g) => g.id.equals(id))).go();

  Future<void> updateCurrentAmount(int goalId, int newAmountMinor) {
    return (update(goals)..where((g) => g.id.equals(goalId))).write(
      GoalsCompanion(currentAmountMinor: Value(newAmountMinor)),
    );
  }

  Future<void> linkTransactionToGoal(int transactionId, int goalId) async {
    await into(transactionGoals).insert(
      TransactionGoalsCompanion.insert(
        transactionId: transactionId,
        goalId: goalId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> unlinkTransactionFromGoal(int transactionId, int goalId) async {
    await (delete(transactionGoals)
          ..where((t) => t.transactionId.equals(transactionId) & t.goalId.equals(goalId)))
        .go();
  }

  Future<int> recalculateGoalAmount(int goalId) async {
    final query = select(transactions).join([
      innerJoin(
        transactionGoals,
        transactionGoals.transactionId.equalsExp(transactions.id),
      ),
    ])
      ..where(transactionGoals.goalId.equals(goalId));

    final linkedTransactions = await query.get();
    
    // Sum all linked transaction amounts
    int sum = 0;
    for (final row in linkedTransactions) {
      final t = row.readTable(transactions);
      sum += t.amountMinor;
    }

    // Update the goal's cached amount
    await updateCurrentAmount(goalId, sum);
    
    return sum;
  }
}
