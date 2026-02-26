import '../database/daos/categories_dao.dart';
import '../mappers/category_mapper.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/category.dart' as domain;

/// Implementation of CategoryRepository using Drift DAO
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoriesDao _categoriesDao;

  CategoryRepositoryImpl(this._categoriesDao);

  @override
  Future<Result<domain.Category, Exception>> createCategory(
    domain.Category category,
  ) async {
    try {
      final companion = category.toCompanion();
      final createdCategory = await _categoriesDao.createCategory(companion);
      return Success(createdCategory.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to create category: $e'));
    }
  }

  @override
  Future<Result<domain.Category, Exception>> updateCategory(
    domain.Category category,
  ) async {
    try {
      final companion = category.toUpdateCompanion();
      final updatedCategory = await _categoriesDao.updateCategory(companion);
      return Success(updatedCategory.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update category: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> deleteCategory(int id) async {
    try {
      await _categoriesDao.deleteCategory(id);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to delete category: $e'));
    }
  }

  @override
  Future<Result<domain.Category?, Exception>> getCategoryById(int id) async {
    try {
      final category = await _categoriesDao.getCategory(id);
      return Success(category?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get category by ID: $e'));
    }
  }

  @override
  Future<Result<List<domain.Category>, Exception>> getCategories(int profileId) async {
    try {
      final categories = await _categoriesDao.getAllCategories(
        profileId: profileId,
      );
      final domainCategories = categories
          .map((category) => category.toEntity())
          .toList();
      return Success(domainCategories);
    } catch (e) {
      return Failure(Exception('Failed to get categories: $e'));
    }
  }

  @override
  Future<Result<List<domain.Category>, Exception>> getSystemCategories() async {
    try {
      final categories = await _categoriesDao.getSystemCategories();
      final domainCategories = categories
          .map((category) => category.toEntity())
          .toList();
      return Success(domainCategories);
    } catch (e) {
      return Failure(Exception('Failed to get system categories: $e'));
    }
  }
}
