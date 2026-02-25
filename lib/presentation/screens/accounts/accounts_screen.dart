import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/account.dart';
import '../../../core/utils/currency_utils.dart';
import '../../providers/account_providers.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  String _selectedAccountType = 'checking';
  String _selectedCurrency = 'NGN';
  String? _balanceError;

  // Separate controllers for editing to avoid conflicts
  final _editNameController = TextEditingController();
  final _editBalanceController = TextEditingController();
  String _editSelectedAccountType = 'checking';
  String _editSelectedCurrency = 'NGN';
  String? _editBalanceError;

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: accountsState.accounts.isEmpty
          ? const Center(
              child: Text(
                'No accounts added yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: accountsState.accounts.length,
              itemBuilder: (context, index) {
                final account = accountsState.accounts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getAccountTypeColor(account.type),
                      child: Icon(
                        _getAccountTypeIcon(account.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(account.name),
                    subtitle: Text(
                      CurrencyUtils.formatMinorToDisplay(
                        account.balanceMinor,
                        account.currency,
                      ),
                      style: TextStyle(
                        color: account.balanceMinor >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(account.type),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditAccountDialog(account),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _showDeleteAccountDialog(account),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditAccountDialog(Account account) {
    // Reset edit form state first
    _editNameController.clear();
    _editBalanceController.clear();
    _editSelectedAccountType = 'checking';
    _editSelectedCurrency = 'NGN';
    _editBalanceError = null;

    // Pre-fill edit form with existing account data
    _editNameController.text = account.name;
    _editBalanceController.text = (account.balanceMinor / 100).toStringAsFixed(
      2,
    );
    _editSelectedAccountType = account.type;
    _editSelectedCurrency = account.currency;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Account'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _editBalanceController,
                  decoration: InputDecoration(
                    labelText: 'Current Balance',
                    border: const OutlineInputBorder(),
                    prefixText: CurrencyUtils.getCurrencySymbol(
                      _editSelectedCurrency,
                    ),
                    errorText: _editBalanceError,
                    helperText: 'Update current balance for this account',
                    helperStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _editSelectedAccountType,
                  decoration: const InputDecoration(
                    labelText: 'Account Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'checking',
                      child: Text('Checking'),
                    ),
                    DropdownMenuItem(value: 'savings', child: Text('Savings')),
                    DropdownMenuItem(
                      value: 'credit',
                      child: Text('Credit Card'),
                    ),
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text('Investment'),
                    ),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _editSelectedAccountType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _editSelectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'NGN',
                      child: Text('NGN - Nigerian Naira'),
                    ),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text('USD - US Dollar'),
                    ),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                    DropdownMenuItem(
                      value: 'GBP',
                      child: Text('GBP - British Pound'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _editSelectedCurrency = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _updateAccount(context, account.id),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(Account account) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${account.name}"?'),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. All transactions associated with this account will also be deleted.',
                style: TextStyle(color: Colors.red[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                'Account Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text('Name: ${account.name}'),
              Text('Type: ${account.type}'),
              Text(
                'Balance: ${CurrencyUtils.formatMinorToDisplay(account.balanceMinor, account.currency)}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _deleteAccount(context, account.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(BuildContext context, int accountId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final result = await ref.read(deleteAccountUseCaseProvider)(accountId);

      if (result.isSuccess) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          navigator.pop();
        }

        // Force immediate refresh by invalidating the provider
        ref.invalidate(accountsProvider);

        // Also trigger a reload to ensure fresh data
        ref.read(accountsProvider.notifier).loadAccounts(1);
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error deleting account: ${result.failureData}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Account'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: 'Initial Balance',
                    border: const OutlineInputBorder(),
                    prefixText: CurrencyUtils.getCurrencySymbol(
                      _selectedCurrency,
                    ),
                    errorText: _balanceError,
                    helperText: 'Enter initial balance for this account',
                    helperStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAccountType,
                  decoration: const InputDecoration(
                    labelText: 'Account Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'checking',
                      child: Text('Checking'),
                    ),
                    DropdownMenuItem(value: 'savings', child: Text('Savings')),
                    DropdownMenuItem(
                      value: 'credit',
                      child: Text('Credit Card'),
                    ),
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text('Investment'),
                    ),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'NGN',
                      child: Text('NGN - Nigerian Naira'),
                    ),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text('USD - US Dollar'),
                    ),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                    DropdownMenuItem(
                      value: 'GBP',
                      child: Text('GBP - British Pound'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveAccount(context),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _updateAccount(BuildContext context, int accountId) async {
    if (_editNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an account name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Create updated account with user-selected values
      final initialBalance =
          double.tryParse(_editBalanceController.text) ?? 0.0;
      final updatedAccount = Account(
        id: accountId,
        profileId: 1, // TODO: Get from user session
        name: _editNameController.text.trim(),
        currency: _editSelectedCurrency,
        balanceMinor: (initialBalance * 100).round(), // Convert to minor units
        type: _editSelectedAccountType,
        isActive: true,
      );

      final result = await ref.read(updateAccountUseCaseProvider)(
        updatedAccount,
      );

      if (result.isSuccess) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Account updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          navigator.pop();
        }

        // Force immediate refresh by invalidating the provider
        ref.invalidate(accountsProvider);

        // Also trigger a reload to ensure fresh data
        ref.read(accountsProvider.notifier).loadAccounts(1);
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error updating account: ${result.failureData}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error updating account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveAccount(BuildContext context) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an account name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Create new account with user-selected values
      final initialBalance = double.tryParse(_balanceController.text) ?? 0.0;
      final newAccount = Account(
        id: 0, // Will be set by database
        profileId: 1, // TODO: Get from user session
        name: _nameController.text.trim(),
        currency: _selectedCurrency,
        balanceMinor: (initialBalance * 100).round(), // Convert to minor units
        type: _selectedAccountType,
        isActive: true,
      );

      final result = await ref.read(createAccountUseCaseProvider)(newAccount);

      if (result.isSuccess) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Account added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _nameController.clear();
          _balanceController.text = '0';
          navigator.pop();
        }

        // Force immediate refresh by invalidating the provider
        ref.invalidate(accountsProvider);

        // Also trigger a reload to ensure fresh data
        ref.read(accountsProvider.notifier).loadAccounts(1);
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error adding account: ${result.failureData}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error adding account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getAccountTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'checking':
        return Colors.blue;
      case 'savings':
        return Colors.green;
      case 'credit':
        return Colors.purple;
      case 'investment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
