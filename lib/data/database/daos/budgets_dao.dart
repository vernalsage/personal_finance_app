import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/budgets_table.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  Future<Budget> createBudget(BudgetsCompanion entry) =>
      into(budgets).insertReturning(
        entry,
        onConflict: DoUpdate(
          (old) => BudgetsCompanion(
            amountMinor: entry.amountMinor,
            updatedAt: Value(DateTime.now()),
          ),
          target: [
            budgets.profileId,
            budgets.categoryId,
            budgets.month,
            budgets.year
          ],
        ),
      );
  Future<Budget> getBudget(int id) =>
      (select(budgets)..where((b) => b.id.equals(id))).getSingle();
  Future<List<Budget>> getAllBudgets({
    int? profileId,
    int? month,
    int? year,
    int? categoryId,
  }) {
    final query = select(budgets);
    if (profileId != null) query.where((b) => b.profileId.equals(profileId));
    if (month != null) query.where((b) => b.month.equals(month));
    if (year != null) query.where((b) => b.year.equals(year));
    if (categoryId != null) query.where((b) => b.categoryId.equals(categoryId));
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

  Future<int> getTotalBudgetLimit(int profileId, int month, int year) async {
    final query = selectOnly(budgets)
      ..addColumns([budgets.amountMinor.sum()])
      ..where(budgets.profileId.equals(profileId) &
          budgets.month.equals(month) &
          budgets.year.equals(year));

    final result = await query.getSingle();
    return result.read(budgets.amountMinor.sum()) ?? 0;
  }

  /// Bulk convert all budget limits to a new target currency
  Future<void> convertBudgetsCurrency({
    required int profileId,
    required double conversionRate,
  }) async {
    final allBudgets = await (select(budgets)
          ..where((b) => b.profileId.equals(profileId)))
        .get();

    for (final budget in allBudgets) {
      final newAmountMinor = (budget.amountMinor * conversionRate).round();
      await (update(budgets)..where((b) => b.id.equals(budget.id))).write(
        BudgetsCompanion(amountMinor: Value(newAmountMinor)),
      );
    }
  }
}
