import 'package:drift/drift.dart';
import '../database/app_database_simple.dart';
import '../../domain/entities/tag.dart' as domain;

/// Extension methods to map between Drift Tag and Domain Tag
extension TagMapper on Tag {
  /// Convert Drift Tag to Domain Tag
  domain.Tag toEntity() {
    return domain.Tag(
      id: id,
      profileId: profileId,
      name: name,
      color: color,
      isActive: isActive,
    );
  }
}

/// Extension methods to map from Domain Tag to Drift objects
extension DomainTagMapper on domain.Tag {
  /// Convert Domain Tag to Drift TagsCompanion for inserts
  TagsCompanion toCompanion() {
    return TagsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      profileId: Value(profileId),
      name: Value(name),
      color: Value(color),
      isActive: Value(isActive),
    );
  }

  /// Convert Domain Tag to Drift TagsCompanion for updates
  TagsCompanion toUpdateCompanion() {
    return TagsCompanion(
      name: Value(name),
      color: Value(color),
      isActive: Value(isActive),
    );
  }
}
