import 'package:drift/drift.dart';
import 'profiles_table.dart';

/// Tags table - represents transaction tags
@DataClassName('Tag')
class Tags extends Table {
  @override
  String get tableName => 'tags';

  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get profileId => integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get name => text().withLength(min: 1, max: 50)();
  
  TextColumn get color => text().withLength(min: 7, max: 7)(); // Hex color code
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
