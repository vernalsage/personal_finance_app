import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<Category> createCategory(CategoriesCompanion entry) =>
      into(categories).insertReturning(entry);
  Future<Category> getCategory(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingle();
  Future<List<Category>> getAllCategories({int? profileId, bool? isActive}) {
    final query = select(categories);
    if (profileId != null) query.where((c) => c.profileId.equals(profileId));
    if (isActive != null) query.where((c) => c.isActive.equals(isActive));
    return query.get();
  }

  Future<Category> updateCategory(CategoriesCompanion entry) => update(
    categories,
  ).writeReturning(entry).then((categories) => categories.first);
  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  Future<List<Category>> getSubcategories(int parentId) {
    return (select(
      categories,
    )..where((c) => c.parentId.equals(parentId))).get();
  }

  Future<List<Category>> getParentCategories(int profileId) {
    return (select(
      categories,
    )..where((c) => c.profileId.equals(profileId) & c.parentId.isNull())).get();
  }
}
