import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/merchant.dart';
import '../../../domain/entities/account.dart';

/// Enriched transaction model for UI display
class EnrichedTransaction {
  final Transaction transaction;
  final Category? category;
  final Merchant? merchant;
  final Account? account;

  const EnrichedTransaction({
    required this.transaction,
    this.category,
    this.merchant,
    this.account,
  });

  /// Get confidence percentage
  int get confidence => transaction.confidenceScore;

  /// Get merchant name (fallback to transaction description if no merchant)
  String get merchantName => merchant?.name ?? transaction.description;

  /// Get category name (fallback to description if no category)
  String get categoryName => category?.name ?? transaction.description;

  /// Get account name
  String? get accountName => account?.name;

  /// Get currency
  String get currency => 'NGN'; // TODO: Get from account or profile

  /// Get notes
  String? get notes => transaction.note;
}
