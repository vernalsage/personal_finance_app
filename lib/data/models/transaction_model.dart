/// Transaction model representing a financial transaction
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.categoryId,
    required this.merchantId,
    required this.amountMinor,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.confidenceScore,
    required this.requiresReview,
    this.transferId,
    this.note,
  });

  final int id;
  final int profileId;
  final int accountId;
  final int categoryId;
  final int merchantId;
  final int amountMinor; // Always stored in minor units
  final TransactionType type;
  final String description;
  final DateTime timestamp;
  final int confidenceScore; // 0-100
  final bool requiresReview;
  final String? transferId;
  final String? note;

  TransactionModel copyWith({
    int? id,
    int? profileId,
    int? accountId,
    int? categoryId,
    int? merchantId,
    int? amountMinor,
    TransactionType? type,
    String? description,
    DateTime? timestamp,
    int? confidenceScore,
    bool? requiresReview,
    String? transferId,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      merchantId: merchantId ?? this.merchantId,
      amountMinor: amountMinor ?? this.amountMinor,
      type: type ?? this.type,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      requiresReview: requiresReview ?? this.requiresReview,
      transferId: transferId ?? this.transferId,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.profileId == profileId &&
        other.accountId == accountId &&
        other.categoryId == categoryId &&
        other.merchantId == merchantId &&
        other.amountMinor == amountMinor &&
        other.type == type &&
        other.description == description &&
        other.timestamp == timestamp &&
        other.confidenceScore == confidenceScore &&
        other.requiresReview == requiresReview &&
        other.transferId == transferId &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      accountId,
      categoryId,
      merchantId,
      amountMinor,
      type,
      description,
      timestamp,
      confidenceScore,
      requiresReview,
      transferId,
      note,
    );
  }
}

enum TransactionType {
  income,
  expense,
  transferOut,
  transferIn,
}

extension TransactionTypeExtension on TransactionType {
  String get name {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transferOut:
        return 'transfer_out';
      case TransactionType.transferIn:
        return 'transfer_in';
    }
  }
}
