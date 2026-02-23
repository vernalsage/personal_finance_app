import '../../data/models/tag_model.dart';

/// Tag entity for transaction tagging
class Tag {
  const Tag({
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

  /// Create from model
  factory Tag.fromModel(TagModel model) {
    return Tag(
      id: model.id,
      profileId: model.profileId,
      name: model.name,
      color: model.color,
      isActive: model.isActive,
    );
  }

  /// Convert to model
  TagModel toModel() {
    return TagModel(
      id: id,
      profileId: profileId,
      name: name,
      color: color,
      isActive: isActive,
    );
  }

  /// Check if tag is active
  bool get isInactive => !isActive;
}
