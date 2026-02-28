import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/accounts/accounts_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';
import '../../main.dart';

/// Main scaffold with bottom navigation:
/// Home · Wallets · Insights · Budget · More
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AccountsScreen(),
    InsightsScreen(),
    BudgetScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for budget alerts
    ref.listen(budgetAlertProvider, (previous, next) {
      if (next != null) {
        _showBudgetAlert(context, next);
        // Clear alert after showing
        Future.microtask(() => ref.read(budgetAlertProvider.notifier).state = null);
      }
    });

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kBorder, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallets',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Budget',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetAlert(BuildContext context, BudgetUsage usage) {
    final isOver = usage.isOverBudget;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOver 
            ? 'Budget Exceeded! Spent ${usage.usagePercentage.toStringAsFixed(1)}% of limit.'
            : 'Budget Warning: Reached ${usage.usagePercentage.toStringAsFixed(1)}% of limit.',
        ),
        backgroundColor: isOver ? kError : kWarning,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _selectedIndex = 3); // Switch to Budget tab
          },
        ),
      ),
    );
  }
}
