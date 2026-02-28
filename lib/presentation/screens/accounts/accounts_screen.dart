import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_providers.dart';
import '../../providers/profile_providers.dart';
import '../../../domain/entities/account.dart';
import '../../widgets/loading_widget.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/style/app_colors.dart';
import '../../../main.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  Future<void> _loadData() async {
    await ref.read(accountsProvider.notifier).loadAccounts(1);
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);
    final accounts = accountsState.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _navigateToAddAccount(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: accounts.isEmpty && !accountsState.isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined,
                              color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No accounts yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to add your first account',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddAccount(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Account'),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : accountsState.isLoading && accounts.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return _AccountCard(
                        account: account,
                        onEdit: () => _navigateToEditAccount(context, account),
                        onDelete: () => _confirmDelete(context, account),
                      );
                    },
                  ),
      ),
    );
  }

  void _navigateToAddAccount(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
  }

  void _navigateToEditAccount(BuildContext context, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddAccountScreen(existingAccount: account)),
    );
  }

  void _confirmDelete(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${account.name}"?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: AppColors.error, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This cannot be undone. All related transactions will be deleted.',
                      style: TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteAccount(account.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(int id) async {
    final result = await ref.read(deleteAccountUseCaseProvider)(id);
    if (!mounted) return;
    if (result.isSuccess) {
      ref.invalidate(accountsProvider);
      ref.read(accountsProvider.notifier).loadAccounts(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.failureData?.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ─── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = account.balanceMinor >= 0;
    final typeColor = _getTypeColor(account.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [typeColor.withOpacity(0.08), typeColor.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getTypeIcon(account.type),
                      color: typeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _TypeBadge(label: _capitalize(account.type)),
                          const SizedBox(width: 6),
                          _TypeBadge(label: account.currency, isSecondary: true),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Balance
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  CurrencyUtils.formatMinorToDisplay(
                      account.balanceMinor, account.currency),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'savings':
        return AppColors.primary;
      case 'checking':
        return const Color(0xFF2563EB);
      case 'credit':
        return const Color(0xFF7C3AED);
      case 'investment':
        return const Color(0xFFEA580C);
      case 'cash':
        return const Color(0xFF16A34A);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'savings':
        return Icons.savings_outlined;
      case 'checking':
        return Icons.account_balance_outlined;
      case 'credit':
        return Icons.credit_card_outlined;
      case 'investment':
        return Icons.trending_up;
      case 'cash':
        return Icons.payments_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final bool isSecondary;
  const _TypeBadge({required this.label, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSecondary 
            ? (isDark ? AppColors.surfaceDark : AppColors.backgroundLight) 
            : AppColors.primaryBg.withOpacity(isDark ? 0.2 : 1.0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSecondary ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight) : AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Add Account Screen ────────────────────────────────────────────────────────

class AddAccountScreen extends ConsumerStatefulWidget {
  final Account? existingAccount;
  const AddAccountScreen({super.key, this.existingAccount});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedCurrency = 'USD';
  String _selectedType = 'savings';
  String? _nameError;
  bool _isSaving = false;

  bool get _isEditing => widget.existingAccount != null;

  final List<Map<String, String>> _currencies = const [
    {'code': 'USD', 'label': 'US Dollar (USD)', 'symbol': '\$'},
    {'code': 'NGN', 'label': 'Nigerian Naira (NGN)', 'symbol': '₦'},
    {'code': 'EUR', 'label': 'Euro (EUR)', 'symbol': '€'},
    {'code': 'GBP', 'label': 'British Pound (GBP)', 'symbol': '£'},
    {'code': 'CAD', 'label': 'Canadian Dollar (CAD)', 'symbol': 'CA\$'},
    {'code': 'GHS', 'label': 'Ghana Cedi (GHS)', 'symbol': 'GH₵'},
  ];

  final List<Map<String, dynamic>> _accountTypes = const [
    {'value': 'savings', 'label': 'Savings'},
    {'value': 'checking', 'label': 'Checking'},
    {'value': 'credit', 'label': 'Credit Card'},
    {'value': 'investment', 'label': 'Investment'},
    {'value': 'cash', 'label': 'Cash'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existingAccount!.name;
      _selectedCurrency = widget.existingAccount!.currency;
      _selectedType = widget.existingAccount!.type;
      _balanceController.text = (widget.existingAccount!.balanceMinor / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Account' : 'Add Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Illustration ────────────────────────────────────────────
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: AppColors.primary, size: 34),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _isEditing
                    ? 'Update your account details below.'
                    : 'Create a new account to start\ntracking your expenses and savings\nefficiently.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 28),

            // ─── Account Name ─────────────────────────────────────────────
            Text('Account Name',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              onChanged: (_) => setState(() => _nameError = null),
              decoration: InputDecoration(
                hintText: 'e.g. Main Savings',
                prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                errorText: _nameError,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // ─── Starting Balance ─────────────────────────────────────────
            Text('Starting Balance',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Account Type ─────────────────────────────────────────────
            Text('Account Type',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // ─── Currency ─────────────────────────────────────────────────
            Text('Currency',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildCurrencyDropdown(),
            const SizedBox(height: 20),

            // ─── Info Note ────────────────────────────────────────────────
            if (!_isEditing)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.1 : 1.0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can change your account name anytime, but the base currency is fixed once the first transaction is recorded.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.primary.withOpacity(0.85)),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // ─── Save Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isEditing ? 'Update Account' : 'Save Account',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _accountTypes.map((type) {
        final isSelected = _selectedType == type['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                  color: isSelected ? AppColors.primary : Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2), width: 1.5),
            ),
            child: Text(
              type['label'] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurrencyDropdown() {
    final selected = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => _currencies.first,
    );

    return GestureDetector(
      onTap: _showCurrencyPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryBg.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  selected['symbol']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected['label']!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerTheme.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Select Currency',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ..._currencies.map((c) {
            final isSelected = _selectedCurrency == c['code'];
            return ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primaryBg.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    c['symbol']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ),
              title: Text(c['label']!),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedCurrency = c['code']!);
                Navigator.of(ctx).pop();
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter an account name');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final balanceMinor = (double.tryParse(_balanceController.text) ?? 0.0) * 100;
        final updated = Account(
          id: widget.existingAccount!.id,
          profileId: 1,
          name: name,
          currency: _selectedCurrency,
          balanceMinor: balanceMinor.round(),
          type: _selectedType,
          isActive: true,
        );
        final result = await ref.read(updateAccountUseCaseProvider)(updated);
        if (!mounted) return;
        if (result.isSuccess) {
          _onSuccess('Account updated successfully');
        } else {
          _onError('Update failed: ${result.failureData?.toString()}');
        }
      } else {
        final balanceMinor = (double.tryParse(_balanceController.text) ?? 0.0) * 100;
        final newAccount = Account(
          id: 0,
          profileId: 1,
          name: name,
          currency: _selectedCurrency,
          balanceMinor: balanceMinor.round(),
          type: _selectedType,
          isActive: true,
        );
        final result = await ref.read(createAccountUseCaseProvider)(newAccount);
        if (!mounted) return;
        if (result.isSuccess) {
          _onSuccess('Account added successfully');
        } else {
          _onError('Could not add account: ${result.failureData?.toString()}');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _onError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onSuccess(String msg) {
    ref.invalidate(accountsProvider);
    ref.read(accountsProvider.notifier).loadAccounts(1);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }

  void _onError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }
}
