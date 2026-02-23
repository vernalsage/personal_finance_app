import 'package:drift/drift.dart';
import 'profiles_table.dart';

/// Accounts table - represents financial accounts
@DataClassName('Account')
class Accounts extends Table {
  @override
  String get tableName => 'accounts';

  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get profileId => integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  TextColumn get type => text().withLength(min: 4, max: 10)(); // bank, cash, credit, wallet
  
  IntColumn get balanceMinor => integer().withDefault(const Constant(0))(); // CRITICAL: Integer minor units only
  
  TextColumn get currency => text().withLength(min: 3, max: 3)(); // ISO 4217 currency code
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  TextColumn get description => text().withLength(max: 255).nullable()();
}
