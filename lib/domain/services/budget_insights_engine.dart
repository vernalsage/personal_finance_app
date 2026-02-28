import '../models/budget_overview.dart';

class BudgetInsightsEngine {
  /// Generates deterministic insights based on spending velocity and budget usage.
  static String getSpendingVelocityInsight(CategoryBudgetStatus status, DateTime currentDate) {
    if (status.budgetAmountMinor <= 0) return "No budget set for ${status.categoryName}.";
    
    final daysInMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
    final dayOfMonth = currentDate.day;
    
    final spendVelocity = status.percentUsed;
    final monthVelocity = dayOfMonth / daysInMonth;
    
    if (status.isOverBudget) {
      return "You've exceeded your budget for ${status.categoryName} by ${status.percentUsed.toStringAsFixed(0)}%.";
    }
    
    if (spendVelocity > monthVelocity + 0.15) {
      return "You are spending faster than the month is passing. Slow down on ${status.categoryName}.";
    }
    
    if (spendVelocity > 0.8 && monthVelocity < 0.5) {
      return "Crucial: You've used 80% of your ${status.categoryName} budget, but the month isn't even halfway through.";
    }
    
    if (spendVelocity < monthVelocity - 0.2) {
      return "Great job! You're well under budget for ${status.categoryName} this month.";
    }
    
    return "Your spending on ${status.categoryName} is on track for the month.";
  }

  static String getSummaryInsight(BudgetOverview overview, DateTime currentDate) {
    if (overview.categoryStatuses.isEmpty) return "Set a budget to start tracking your spending habits.";
    
    final daysInMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
    final dayOfMonth = currentDate.day;
    final monthPercent = dayOfMonth / daysInMonth;

    // 1. Check overall budget health
    if (overview.totalPercentUsed > 1.0) {
      return "You've exceeded your total budget. Review your top categories to find savings.";
    }
    
    if (overview.totalPercentUsed > monthPercent + 0.1) {
      return "Your total spending is pacing ahead of schedule for ${(monthPercent * 100).toStringAsFixed(0)}% through the month.";
    }

    // 2. Check for most critical category
    final sortedByUsage = List<CategoryBudgetStatus>.from(overview.categoryStatuses)
      ..sort((a, b) => b.percentUsed.compareTo(a.percentUsed));
      
    final critical = sortedByUsage.first;
    if (critical.isOverBudget) {
      return "Refine your spending: ${critical.categoryName} is already over budget.";
    }
    
    if (critical.percentUsed > monthPercent + 0.2) {
      return "Keep an eye on ${critical.categoryName}; it's growing faster than other categories.";
    }

    // 3. Fallback to general positive/neutral insight
    if (overview.totalPercentUsed < monthPercent - 0.1) {
      return "Excellent! You're well within your total budget limits for this point in the month.";
    }

    return "Your overall spending is currently on track with your monthly budget goals.";
  }
}
