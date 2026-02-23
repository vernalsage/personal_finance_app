import 'package:drift/drift.dart';

/// Profiles table - represents user profiles
@DataClassName('Profile')
class Profiles extends Table {
  @override
  String get tableName => 'profiles';

  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  TextColumn get currency => text().withLength(min: 3, max: 3)(); // ISO 4217 currency code
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
