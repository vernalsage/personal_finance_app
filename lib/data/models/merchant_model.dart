/// Merchant model for transaction merchant information
class MerchantModel {
  const MerchantModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.normalizedName,
    required this.lastSeen,
    this.categoryId,
  });

  final int id;
  final int profileId;
  final String name;
  final String normalizedName;
  final DateTime lastSeen;
  final int? categoryId;

  MerchantModel copyWith({
    int? id,
    int? profileId,
    String? name,
    String? normalizedName,
    DateTime? lastSeen,
    int? categoryId,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      lastSeen: lastSeen ?? this.lastSeen,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchantModel &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        other.normalizedName == normalizedName &&
        other.lastSeen == lastSeen &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      name,
      normalizedName,
      lastSeen,
      categoryId,
    );
  }
}
