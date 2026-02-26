import '../database/daos/tags_dao.dart';
import '../mappers/tag_mapper.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/tag.dart' as domain;

/// Implementation of TagRepository using Drift DAO
class TagRepositoryImpl implements TagRepository {
  final TagsDao _tagsDao;

  TagRepositoryImpl(this._tagsDao);

  @override
  Future<Result<domain.Tag, Exception>> createTag(
    domain.Tag tag,
  ) async {
    try {
      final companion = tag.toCompanion();
      final createdTag = await _tagsDao.createTag(companion);
      return Success(createdTag.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to create tag: $e'));
    }
  }

  @override
  Future<Result<domain.Tag, Exception>> updateTag(
    domain.Tag tag,
  ) async {
    try {
      final companion = tag.toUpdateCompanion();
      final updatedTag = await _tagsDao.updateTag(companion);
      return Success(updatedTag.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to update tag: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> deleteTag(int tagId) async {
    try {
      await _tagsDao.deleteTag(tagId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to delete tag: $e'));
    }
  }

  @override
  Future<Result<domain.Tag?, Exception>> getTagById(int tagId) async {
    try {
      final tag = await _tagsDao.getTag(tagId);
      return Success(tag?.toEntity());
    } catch (e) {
      return Failure(Exception('Failed to get tag by ID: $e'));
    }
  }

  @override
  Future<Result<List<domain.Tag>, Exception>> getTags(int profileId) async {
    try {
      final tags = await _tagsDao.getAllTags(profileId: profileId);
      return Success(tags.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Failure(Exception('Failed to get tags: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> linkTagToTransaction(
    int transactionId,
    int tagId,
  ) async {
    try {
      await _tagsDao.linkTagToTransaction(transactionId, tagId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to link tag to transaction: $e'));
    }
  }

  @override
  Future<Result<void, Exception>> unlinkTagFromTransaction(
    int transactionId,
    int tagId,
  ) async {
    try {
      await _tagsDao.unlinkTagFromTransaction(transactionId, tagId);
      return Success(null);
    } catch (e) {
      return Failure(Exception('Failed to unlink tag from transaction: $e'));
    }
  }

  @override
  Future<Result<List<domain.Tag>, Exception>> getTagsForTransaction(
    int transactionId,
  ) async {
    try {
      final tags = await _tagsDao.getTagsForTransaction(transactionId);
      return Success(tags.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Failure(Exception('Failed to get tags for transaction: $e'));
    }
  }
}
