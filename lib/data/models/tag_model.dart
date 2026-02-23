/// Tag model for transaction tagging
class TagModel {
  const TagModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.color,
    required this.isActive,
  });

  final int id;
  final int profileId;
  final String name;
  final String color;
  final bool isActive;

  TagModel copyWith({
    int? id,
    int? profileId,
    String? name,
    String? color,
    bool? isActive,
  }) {
    return TagModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagModel &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        other.color == color &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      name,
      color,
      isActive,
    );
  }
}
