/// Merchant entity for transaction merchant information
class Merchant {
  const Merchant({
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

  Merchant copyWith({
    int? id,
    int? profileId,
    String? name,
    String? normalizedName,
    DateTime? lastSeen,
    int? categoryId,
  }) {
    return Merchant(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      lastSeen: lastSeen ?? this.lastSeen,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  /// Check if merchant has a default category
  bool get hasDefaultCategory => categoryId != null;

  /// Check if merchant was recently seen (within last 30 days)
  bool get isRecentlySeen {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return lastSeen.isAfter(thirtyDaysAgo);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Merchant &&
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

  @override
  String toString() {
    return 'Merchant(id: $id, profileId: $profileId, name: $name, normalizedName: $normalizedName, lastSeen: $lastSeen, categoryId: $categoryId)';
  }
}
