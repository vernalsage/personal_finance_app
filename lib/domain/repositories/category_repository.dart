import '../entities/category.dart';
import '../core/result.dart';

/// Repository interface for category operations
abstract class CategoryRepository {
  /// Create a new category
  Future<Result<Category, Exception>> createCategory(Category category);

  /// Update an existing category
  Future<Result<Category, Exception>> updateCategory(Category category);

  /// Delete a category
  Future<Result<void, Exception>> deleteCategory(int categoryId);

  /// Get category by ID
  Future<Result<Category?, Exception>> getCategoryById(int categoryId);

  /// Get categories for a profile
  Future<Result<List<Category>, Exception>> getCategories(int profileId);

  /// Get system categories
  Future<Result<List<Category>, Exception>> getSystemCategories();
}
