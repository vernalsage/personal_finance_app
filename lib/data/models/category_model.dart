/// Category model for transaction categorization
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.color,
    required this.icon,
    required this.isActive,
    this.parentId,
  });

  final int id;
  final int profileId;
  final String name;
  final String color;
  final String icon;
  final bool isActive;
  final int? parentId;

  CategoryModel copyWith({
    int? id,
    int? profileId,
    String? name,
    String? color,
    String? icon,
    bool? isActive,
    int? parentId,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        other.color == color &&
        other.icon == icon &&
        other.isActive == isActive &&
        other.parentId == parentId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      name,
      color,
      icon,
      isActive,
      parentId,
    );
  }
}
