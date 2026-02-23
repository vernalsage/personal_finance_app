import 'package:drift/drift.dart';
import 'profiles_table.dart';
import 'categories_table.dart';
import 'merchants_table.dart';
import 'accounts_table.dart';

/// RecurringRules table - represents recurring transaction rules
@DataClassName('RecurringRule')
class RecurringRules extends Table {
  @override
  String get tableName => 'recurring_rules';

  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get profileId => integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  IntColumn get amountMinor => integer()(); // CRITICAL: Integer minor units only
  
  TextColumn get type => text().withLength(min: 4, max: 7)(); // income, expense
  
  TextColumn get frequency => text().withLength(min: 4, max: 7)(); // daily, weekly, monthly, yearly
  
  DateTimeColumn get startDate => dateTime()();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  TextColumn get description => text().withLength(max: 255).nullable()();
  
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  
  IntColumn get merchantId => integer().nullable().references(Merchants, #id, onDelete: KeyAction.setNull)();
  
  IntColumn get accountId => integer().nullable().references(Accounts, #id, onDelete: KeyAction.setNull)();
  
  DateTimeColumn get endDate => dateTime().nullable()();
  
  DateTimeColumn get lastExecutedDate => dateTime().nullable()();
  
  DateTimeColumn get nextExecutionDate => dateTime().nullable()();
}
