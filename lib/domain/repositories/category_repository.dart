import '../entities/category.dart';
import '../repositories/transaction_repository.dart';

/// Repository interface for category operations
abstract class CategoryRepository {
  /// Create a new category
  Future<Result<Category>> createCategory(Category category);

  /// Update an existing category
  Future<Result<Category>> updateCategory(Category category);

  /// Delete a category
  Future<Result<void>> deleteCategory(int categoryId);

  /// Get category by ID
  Future<Result<Category?>> getCategoryById(int categoryId);

  /// Get categories for a profile
  Future<Result<List<Category>>> getCategories(
    int profileId, {
    bool? isActive,
    int? parentId,
  });

  /// Get parent categories (categories without parent)
  Future<Result<List<Category>>> getParentCategories(
    int profileId, {
    bool? isActive,
  });

  /// Get subcategories for a parent category
  Future<Result<List<Category>>> getSubcategories(
    int profileId,
    int parentId, {
    bool? isActive,
  });
}
