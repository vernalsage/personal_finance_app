/// Account model representing a financial account
class AccountModel {
  const AccountModel({
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
  final AccountType type;
  final int balanceMinor; // Always stored in minor units
  final String currency;
  final bool isActive;
  final String? description;

  AccountModel copyWith({
    int? id,
    int? profileId,
    String? name,
    AccountType? type,
    int? balanceMinor,
    String? currency,
    bool? isActive,
    String? description,
  }) {
    return AccountModel(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountModel &&
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
}

enum AccountType {
  bank,
  cash,
  credit,
  wallet,
}

extension AccountTypeExtension on AccountType {
  String get name {
    switch (this) {
      case AccountType.bank:
        return 'bank';
      case AccountType.cash:
        return 'cash';
      case AccountType.credit:
        return 'credit';
      case AccountType.wallet:
        return 'wallet';
    }
  }
}
