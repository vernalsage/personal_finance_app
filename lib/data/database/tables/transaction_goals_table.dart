import 'package:drift/drift.dart';
import 'transactions_table.dart';
import 'goals_table.dart';

/// TransactionGoals table - bridge table for many-to-many relationship between transactions and goals
@DataClassName('TransactionGoal')
class TransactionGoals extends Table {
  @override
  String get tableName => 'transaction_goals';

  IntColumn get transactionId => integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  
  IntColumn get goalId => integer().references(Goals, #id, onDelete: KeyAction.cascade)();
  
  // Composite primary key
  @override
  Set<Column> get primaryKey => {transactionId, goalId};
}
