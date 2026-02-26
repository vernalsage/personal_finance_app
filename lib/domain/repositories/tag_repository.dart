import '../entities/tag.dart';
import '../core/result.dart';

/// Repository interface for tag operations
abstract class TagRepository {
  /// Create a new tag
  Future<Result<Tag, Exception>> createTag(Tag tag);

  /// Update an existing tag
  Future<Result<Tag, Exception>> updateTag(Tag tag);

  /// Delete a tag
  Future<Result<void, Exception>> deleteTag(int tagId);

  /// Get tag by ID
  Future<Result<Tag?, Exception>> getTagById(int tagId);

  /// Get tags for a profile
  Future<Result<List<Tag>, Exception>> getTags(int profileId);

  /// Link a tag to a transaction
  Future<Result<void, Exception>> linkTagToTransaction(
    int transactionId,
    int tagId,
  );

  /// Unlink a tag from a transaction
  Future<Result<void, Exception>> unlinkTagFromTransaction(
    int transactionId,
    int tagId,
  );

  /// Get tags for a transaction
  Future<Result<List<Tag>, Exception>> getTagsForTransaction(int transactionId);
}
