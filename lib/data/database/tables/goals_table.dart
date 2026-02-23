import 'package:drift/drift.dart';
import 'profiles_table.dart';

/// Goals table - represents financial goals
@DataClassName('Goal')
class Goals extends Table {
  @override
  String get tableName => 'goals';

  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get profileId => integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  IntColumn get targetAmountMinor => integer()(); // CRITICAL: Integer minor units only
  
  IntColumn get currentAmountMinor => integer().withDefault(const Constant(0))(); // CRITICAL: Integer minor units only
  
  DateTimeColumn get targetDate => dateTime()();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  TextColumn get description => text().withLength(max: 500).nullable()();
  
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
