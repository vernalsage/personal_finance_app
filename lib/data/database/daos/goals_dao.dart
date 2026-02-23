import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/goals_table.dart';

part 'goals_dao.g.dart';

@DriftAccessor(tables: [Goals])
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
}
