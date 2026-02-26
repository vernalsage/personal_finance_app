import 'package:drift/drift.dart';
import 'profiles_table.dart';
import 'categories_table.dart';

/// Budgets table - represents monthly budgets
@DataClassName('Budget')
class Budgets extends Table {
  @override
  String get tableName => 'budgets';

  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get profileId => integer()
      .references(Profiles, #id, onDelete: KeyAction.cascade)();
  
  IntColumn get categoryId => integer()
      .references(Categories, #id, onDelete: KeyAction.cascade)();
  
  IntColumn get amountMinor => integer()(); // CRITICAL: Integer minor units only
  
  IntColumn get month => integer()(); // 1-12
  
  IntColumn get year => integer()(); // YYYY
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  DateTimeColumn get updatedAt => dateTime().nullable()();
  
  // Composite unique key for profile, category, month, year
  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, categoryId, month, year},
  ];
}
