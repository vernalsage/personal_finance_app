/// Transaction entity representing a financial transaction
class Transaction {
  const Transaction({
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
  final int? categoryId;
  final int? merchantId;
  final int amountMinor;
  final String type;
  final String description;
  final DateTime timestamp;
  final int confidenceScore;
  final bool requiresReview;
  final String? transferId;
  final String? note;

  Transaction copyWith({
    int? id,
    int? profileId,
    int? accountId,
    int? categoryId,
    int? merchantId,
    int? amountMinor,
    String? type,
    String? description,
    DateTime? timestamp,
    int? confidenceScore,
    bool? requiresReview,
    String? transferId,
    String? note,
  }) {
    return Transaction(
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

  /// Check if transaction is a transfer
  bool get isTransfer => type == 'transfer_out' || type == 'transfer_in';

  /// Check if transaction needs review
  bool get needsReview => requiresReview || confidenceScore < 80;

  /// Check if transaction is recent (within last 7 days)
  bool get isRecent {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return timestamp.isAfter(sevenDaysAgo);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
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

  @override
  String toString() {
    return 'Transaction(id: $id, profileId: $profileId, accountId: $accountId, categoryId: $categoryId, merchantId: $merchantId, amountMinor: $amountMinor, type: $type, description: $description, timestamp: $timestamp, confidenceScore: $confidenceScore, requiresReview: $requiresReview, transferId: $transferId, note: $note)';
  }
}

/// Statistics for transactions
class TransactionStats {
  const TransactionStats({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.transactionCount,
    required this.averageTransactionAmount,
  });

  final int totalIncome;
  final int totalExpenses;
  final int netIncome;
  final int transactionCount;
  final double averageTransactionAmount;
}
