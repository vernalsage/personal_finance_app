/// Account entity representing a financial account
class Account {
  const Account({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    required this.balanceMinor,
    required this.currency,
    required this.isActive,
    this.description,
  });

  final int id;
  final int profileId;
  final String name;
  final String type;
  final int balanceMinor;
  final String currency;
  final bool isActive;
  final String? description;

  Account copyWith({
    int? id,
    int? profileId,
    String? name,
    String? type,
    int? balanceMinor,
    String? currency,
    bool? isActive,
    String? description,
  }) {
    return Account(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      type: type ?? this.type,
      balanceMinor: balanceMinor ?? this.balanceMinor,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }

  /// Check if account is a credit account
  bool get isCredit => type == 'credit';

  /// Check if account is active
  bool get isInactive => !isActive;

  /// Get formatted balance
  String get formattedBalance {
    final absBalance = balanceMinor.abs();
    final prefix = balanceMinor < 0 ? '-' : '';
    return '$prefix${(absBalance / 100).toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        other.type == type &&
        other.balanceMinor == balanceMinor &&
        other.currency == currency &&
        other.isActive == isActive &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      name,
      type,
      balanceMinor,
      currency,
      isActive,
      description,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, profileId: $profileId, name: $name, type: $type, balanceMinor: $balanceMinor, currency: $currency, isActive: $isActive, description: $description)';
  }
}
