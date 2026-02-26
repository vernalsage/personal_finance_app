import 'package:flutter/material.dart';
import '../budgets/budgets_screen.dart';
import '../goals/goals_screen.dart';
import '../recurring/recurring_rules_screen.dart';
import '../merchants/merchants_screen.dart';
import '../../../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('More'),
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
                MaterialPageRoute(builder: (_) => const BudgetsScreen()),
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
          _buildSection(context, 'App Settings', [
            _SettingTile(
              icon: Icons.security_outlined,
              title: 'Security',
              subtitle: 'Biometrics and data encryption',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.cloud_outlined,
              title: 'Data Export',
              subtitle: 'Export your data to CSV',
              onTap: () {},
            ),
          ]),
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
              color: kTextSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
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
          color: kPrimaryBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: kTextSecondary),
      onTap: onTap,
    );
  }
}
