/// Profile model representing a user profile
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.currency,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String currency;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileModel copyWith({
    int? id,
    String? name,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileModel &&
        other.id == id &&
        other.name == name &&
        other.currency == currency &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      currency,
      isActive,
      createdAt,
      updatedAt,
    );
  }
}
