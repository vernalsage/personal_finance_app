import '../entities/tag.dart';
import '../repositories/transaction_repository.dart';

/// Repository interface for tag operations
abstract class TagRepository {
  /// Create a new tag
  Future<Result<Tag>> createTag(Tag tag);

  /// Update an existing tag
  Future<Result<Tag>> updateTag(Tag tag);

  /// Delete a tag
  Future<Result<void>> deleteTag(int tagId);

  /// Get tag by ID
  Future<Result<Tag?>> getTagById(int tagId);

  /// Get tags for a profile
  Future<Result<List<Tag>>> getTags(
    int profileId, {
    bool? isActive,
  });

  /// Link tags to a transaction
  Future<Result<void>> linkTagsToTransaction(
    int transactionId,
    List<int> tagIds,
  );

  /// Unlink tags from a transaction
  Future<Result<void>> unlinkTagsFromTransaction(
    int transactionId,
    List<int> tagIds,
  );

  /// Get tags for a transaction
  Future<Result<List<Tag>>> getTagsForTransaction(int transactionId);

  /// Get transactions for a tag
  Future<Result<List<int>>> getTransactionsForTag(int tagId);
}
