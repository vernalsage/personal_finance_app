import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/security_providers.dart';
import '../budget/budget_screen.dart';
import '../goals/goals_screen.dart';
import '../recurring/recurring_rules_screen.dart';
import '../merchants/merchants_screen.dart';
import '../transactions/transactions_screen.dart';
import '../../providers/profile_providers.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/style/app_colors.dart';
import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(securityProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, 'Planning', [
            _SettingTile(
              icon: Icons.pie_chart_outline,
              title: 'Budgets',
              subtitle: 'Manage your monthly spending limits',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              ),
            ),
            _SettingTile(
              icon: Icons.flag_outlined,
              title: 'Goals',
              subtitle: 'Track your savings and financial targets',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GoalsScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'Automation & Data', [
            _SettingTile(
              icon: Icons.sync_outlined,
              title: 'Recurring Payments',
              subtitle: 'Automate your subscriptions and bills',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecurringRulesScreen()),
              ),
            ),
            _SettingTile(
              icon: Icons.storefront_outlined,
              title: 'Merchants',
              subtitle: 'Normalized merchant data and insights',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MerchantsScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'App Appearance', [
             _ThemeSelectionTile(
                currentMode: themeMode,
                onChanged: (mode) => ref.read(themeModeProvider.notifier).setThemeMode(mode),
              ),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'App Settings & Security', [
            const _BaseCurrencyTile(),
            _SettingTile(
              icon: Icons.history_outlined,
              title: 'Transaction History',
              subtitle: 'View and edit all past records',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionsScreen(initialFilter: 'All')),
              ),
            ),
            _SecurityToggleTile(
              isActive: securityState.isBiometricEnabled,
              isAvailable: securityState.isBiometricAvailable,
              onChanged: (v) => ref.read(securityProvider.notifier).setBiometricEnabled(v),
            ),
            _SettingTile(
              icon: Icons.cloud_outlined,
              title: 'Data Export',
              subtitle: 'Export your data to CSV',
              onTap: () async {
                final profile = ref.read(activeProfileProvider).value;
                if (profile == null) return;
                
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preparing export...')),
                  );
                  await ref.read(exportServiceProvider).exportTransactions(profile.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'App Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

class _ThemeSelectionTile extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onChanged;

  const _ThemeSelectionTile({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.palette_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Color Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'Customize app appearance',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_suggest_outlined, size: 16),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              onChanged(newSelection.first);
            },
            showSelectedIcon: false,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityToggleTile extends StatelessWidget {
  final bool isActive;
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const _SecurityToggleTile({
    required this.isActive,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.security_outlined, color: AppColors.primary, size: 20),
      ),
      title: const Text('Biometric Lock', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        isAvailable ? 'Secure your data with biometrics' : 'Biometrics not available on this device',
        style: const TextStyle(fontSize: 12),
      ),
      value: isAvailable && isActive,
      onChanged: isAvailable ? onChanged : null,
      activeColor: AppColors.primary,
    );
  }
}

class _BaseCurrencyTile extends ConsumerWidget {
  const _BaseCurrencyTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);

    // Listen for errors to show a SnackBar
    ref.listen(activeProfileProvider, (previous, next) {
      if (next is AsyncError && previous is! AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update currency: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final currentCurrency = profileAsync.value?.currency ?? 'NGN';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.currency_exchange_outlined, color: AppColors.primary, size: 20),
      ),
      title: const Text('Base Currency', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: profileAsync.isLoading && profileAsync.value == null
        ? const Text('Loading...')
        : Text('Primary display currency: $currentCurrency', style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _showCurrencyPicker(context, ref, currentCurrency),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Base Currency', style: Theme.of(context).textTheme.titleMedium),
            ),
            ...['NGN', 'USD', 'GBP', 'EUR'].map((c) => ListTile(
              title: Text(c),
              trailing: c == current ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                ref.read(activeProfileProvider.notifier).updateCurrency(c);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}
