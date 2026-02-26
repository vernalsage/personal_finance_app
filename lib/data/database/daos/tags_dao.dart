import 'package:drift/drift.dart';
import '../app_database_simple.dart';
import '../tables/tags_table.dart';
import '../tables/transaction_tags_table.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags, TransactionTags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  Future<Tag> createTag(TagsCompanion entry) =>
      into(tags).insertReturning(entry);
  Future<Tag> getTag(int id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingle();
  Future<List<Tag>> getAllTags({int? profileId, bool? isActive}) {
    final query = select(tags);
    if (profileId != null) query.where((t) => t.profileId.equals(profileId));
    if (isActive != null) query.where((t) => t.isActive.equals(isActive));
    return query.get();
  }

  Future<Tag> updateTag(TagsCompanion entry) =>
      update(tags).writeReturning(entry).then((tags) => tags.first);
  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  Future<void> linkTagToTransaction(int transactionId, int tagId) async {
    await into(transactionTags).insert(
      TransactionTagsCompanion.insert(
        transactionId: transactionId,
        tagId: tagId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> unlinkTagFromTransaction(int transactionId, int tagId) async {
    await (delete(transactionTags)
          ..where((t) => t.transactionId.equals(transactionId) & t.tagId.equals(tagId)))
        .go();
  }

  Future<List<Tag>> getTagsForTransaction(int transactionId) async {
    final query = select(tags).join([
      innerJoin(
        transactionTags,
        transactionTags.tagId.equalsExp(tags.id),
      ),
    ])
      ..where(transactionTags.transactionId.equals(transactionId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(tags)).toList();
  }
}
