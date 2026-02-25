import '../database/daos/categories_dao.dart';
import '../mappers/category_mapper.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/category.dart' as domain;

/// Implementation of CategoryRepository using Drift DAO
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoriesDao _categoriesDao;

  CategoryRepositoryImpl(this._categoriesDao);

  @override
  Future<Result<domain.Category>> createCategory(
    domain.Category category,
  ) async {
    try {
      final companion = category.toCompanion();
      final createdCategory = await _categoriesDao.createCategory(companion);
      return Result.success(createdCategory.toEntity());
    } catch (e) {
      return Result.failure('Failed to create category: $e');
    }
  }

  @override
  Future<Result<domain.Category>> updateCategory(
    domain.Category category,
  ) async {
    try {
      final companion = category.toUpdateCompanion();
      final updatedCategory = await _categoriesDao.updateCategory(companion);
      return Result.success(updatedCategory.toEntity());
    } catch (e) {
      return Result.failure('Failed to update category: $e');
    }
  }

  @override
  Future<Result<void>> deleteCategory(int id) async {
    try {
      await _categoriesDao.deleteCategory(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to delete category: $e');
    }
  }

  @override
  Future<Result<domain.Category?>> getCategoryById(int id) async {
    try {
      final category = await _categoriesDao.getCategory(id);
      return Result.success(category.toEntity());
    } catch (e) {
      return Result.failure('Failed to get category by ID: $e');
    }
  }

  @override
  Future<Result<List<domain.Category>>> getCategories(
    int profileId, {
    bool? isActive,
    int? parentId,
  }) async {
    try {
      final categories = await _categoriesDao.getAllCategories(
        profileId: profileId,
        isActive: isActive,
      );

      // Filter by parentId in memory since DAO doesn't support it directly
      var filteredCategories = categories;
      if (parentId != null) {
        filteredCategories = categories
            .where((c) => c.parentId == parentId)
            .toList();
      }

      final domainCategories = filteredCategories
          .map((category) => category.toEntity())
          .toList();
      return Result.success(domainCategories);
    } catch (e) {
      return Result.failure('Failed to get categories by profile: $e');
    }
  }

  // Removed @override since getCategoryByName is a repository-specific helper, not in the base interface
  Future<Result<domain.Category?>> getCategoryByName(
    int profileId,
    String name,
  ) async {
    try {
      final categories = await _categoriesDao.getAllCategories(
        profileId: profileId,
      );
      domain.Category? category;
      try {
        final found = categories.firstWhere(
          (c) => c.name.toLowerCase() == name.toLowerCase(),
        );
        category = found.toEntity();
      } catch (e) {
        category = null;
      }
      return Result.success(category);
    } catch (e) {
      return Result.failure('Failed to get category by name: $e');
    }
  }

  @override
  Future<Result<List<domain.Category>>> getParentCategories(
    int profileId, {
    bool? isActive,
  }) async {
    try {
      final categories = await _categoriesDao.getAllCategories(
        profileId: profileId,
        isActive: isActive,
      );
      final parentCategories = categories
          .where((c) => c.parentId == null)
          .map((category) => category.toEntity())
          .toList();
      return Result.success(parentCategories);
    } catch (e) {
      return Result.failure('Failed to get parent categories: $e');
    }
  }

  @override
  Future<Result<List<domain.Category>>> getSubcategories(
    int profileId,
    int parentId, {
    bool? isActive,
  }) async {
    try {
      final categories = await _categoriesDao.getAllCategories(
        profileId: profileId,
        isActive: isActive,
      );
      final subcategories = categories
          .where((c) => c.parentId == parentId)
          .map((category) => category.toEntity())
          .toList();
      return Result.success(subcategories);
    } catch (e) {
      return Result.failure('Failed to get subcategories: $e');
    }
  }
}
