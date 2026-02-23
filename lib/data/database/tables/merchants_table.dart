import 'package:drift/drift.dart';
import 'profiles_table.dart';
import 'categories_table.dart';

/// Merchants table - represents transaction merchants
@DataClassName('Merchant')
class Merchants extends Table {
  @override
  String get tableName => 'merchants';

  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get profileId => integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  TextColumn get normalizedName => text().withLength(min: 1, max: 100)(); // Normalized for matching
  
  DateTimeColumn get lastSeen => dateTime()();
  
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
}
