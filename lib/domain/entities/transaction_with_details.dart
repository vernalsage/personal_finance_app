import 'transaction.dart';
import 'account.dart';
import 'category.dart';
import 'merchant.dart';

/// Transaction with joined details for UI display
class TransactionWithDetails {
  final Transaction transaction;
  final Account? account;
  final Category? category;
  final Merchant? merchant;

  const TransactionWithDetails({
    required this.transaction,
    this.account,
    this.category,
    this.merchant,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionWithDetails &&
        other.transaction == transaction &&
        other.account == account &&
        other.category == category &&
        other.merchant == merchant;
  }

  @override
  int get hashCode => Object.hash(transaction, account, category, merchant);
}
