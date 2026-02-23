import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/budgets_table.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  Future<Budget> createBudget(BudgetsCompanion entry) =>
      into(budgets).insertReturning(entry);
  Future<Budget> getBudget(int id) =>
      (select(budgets)..where((b) => b.id.equals(id))).getSingle();
  Future<List<Budget>> getAllBudgets({int? profileId}) {
    final query = select(budgets);
    if (profileId != null) query.where((b) => b.profileId.equals(profileId));
    return query.get();
  }

  Future<Budget> updateBudget(BudgetsCompanion entry) =>
      update(budgets).writeReturning(entry).then((budgets) => budgets.first);
  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  Future<Budget?> getBudgetForMonth(
    int profileId,
    int categoryId,
    int month,
    int year,
  ) {
    return (select(budgets)..where(
          (b) =>
              b.profileId.equals(profileId) &
              b.categoryId.equals(categoryId) &
              b.month.equals(month) &
              b.year.equals(year),
        ))
        .getSingleOrNull();
  }
}
