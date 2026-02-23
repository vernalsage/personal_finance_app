import 'package:drift/drift.dart';
import '../database/app_database_simple.dart';
import '../../domain/entities/category.dart' as domain;

/// Extension methods to map between Drift Category and Domain Category
extension CategoryMapper on Category {
  /// Convert Drift Category to Domain Category
  domain.Category toEntity() {
    return domain.Category(
      id: id,
      profileId: profileId,
      name: name,
      color: color,
      icon: icon,
      isActive: isActive,
      parentId: parentId,
    );
  }
}

/// Extension methods to map from Domain Category to Drift objects
extension DomainCategoryMapper on domain.Category {
  /// Convert Domain Category to Drift CategoriesCompanion for inserts
  CategoriesCompanion toCompanion() {
    return CategoriesCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      profileId: Value(profileId),
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
      isActive: Value(isActive),
      parentId: parentId != null ? Value(parentId!) : const Value.absent(),
    );
  }

  /// Convert Domain Category to Drift CategoriesCompanion for updates
  CategoriesCompanion toUpdateCompanion() {
    return CategoriesCompanion(
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
      isActive: Value(isActive),
      parentId: parentId != null ? Value(parentId!) : const Value.absent(),
    );
  }
}
