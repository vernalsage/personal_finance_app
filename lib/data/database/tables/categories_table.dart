import 'package:drift/drift.dart';
import 'profiles_table.dart';

/// Categories table - represents transaction categories
@DataClassName('Category')
class Categories extends Table {
  @override
  String get tableName => 'categories';

  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get profileId => integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get name => text().withLength(min: 1, max: 50)();
  
  TextColumn get color => text().withLength(min: 7, max: 7)(); // Hex color code
  
  TextColumn get icon => text().withLength(min: 1, max: 50)(); // Icon name
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  IntColumn get parentId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
}
