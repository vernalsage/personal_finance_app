import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_overview.freezed.dart';

@freezed
class CategoryBudgetStatus with _$CategoryBudgetStatus {
  const factory CategoryBudgetStatus({
    required int categoryId,
    required String categoryName,
    required String categoryColor,
    required String categoryIcon,
    required int budgetAmountMinor,
    required int spentAmountMinor,
    required int month,
    required int year,
  }) = _CategoryBudgetStatus;

  const CategoryBudgetStatus._();

  double get percentUsed => budgetAmountMinor > 0 ? spentAmountMinor / budgetAmountMinor : 0;
  int get remainingAmountMinor => budgetAmountMinor - spentAmountMinor;
  bool get isOverBudget => spentAmountMinor > budgetAmountMinor;
}

@freezed
class BudgetOverview with _$BudgetOverview {
  const factory BudgetOverview({
    required List<CategoryBudgetStatus> categoryStatuses,
    required int totalBudgetedMinor,
    required int totalSpentMinor,
    required int month,
    required int year,
  }) = _BudgetOverview;

  const BudgetOverview._();

  double get totalPercentUsed => totalBudgetedMinor > 0 ? totalSpentMinor / totalBudgetedMinor : 0;
  int get totalRemainingMinor => totalBudgetedMinor - totalSpentMinor;
}
