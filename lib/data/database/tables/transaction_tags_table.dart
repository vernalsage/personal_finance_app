import 'package:drift/drift.dart';
import 'transactions_table.dart';
import 'tags_table.dart';

/// TransactionTags table - bridge table for many-to-many relationship between transactions and tags
@DataClassName('TransactionTag')
class TransactionTags extends Table {
  @override
  String get tableName => 'transaction_tags';

  IntColumn get transactionId => integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  
  IntColumn get tagId => integer().references(Tags, #id, onDelete: KeyAction.cascade)();
  
  // Composite primary key
  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}
