import 'package:drift/drift.dart';
import 'profiles_table.dart';
import 'accounts_table.dart';
import 'categories_table.dart';
import 'merchants_table.dart';

/// Transactions table - represents financial transactions
@DataClassName('Transaction')
class Transactions extends Table {
  @override
  String get tableName => 'transactions';

  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get profileId => integer()
      .references(Profiles, #id, onDelete: KeyAction.cascade)();
  
  IntColumn get accountId => integer()
      .references(Accounts, #id, onDelete: KeyAction.restrict)();
  
  IntColumn get categoryId => integer()
      .references(Categories, #id, onDelete: KeyAction.restrict)();
  
  IntColumn get merchantId => integer()
      .references(Merchants, #id, onDelete: KeyAction.setNull)();
  
  IntColumn get amountMinor => integer()(); // CRITICAL: Integer minor units only (Kobo)
  
  TextColumn get type => text().withLength(min: 4, max: 12)(); // income, expense, transfer_out, transfer_in
  
  TextColumn get description => text().withLength(min: 1, max: 255)();
  
  DateTimeColumn get timestamp => dateTime()();
  
  IntColumn get confidenceScore => integer().withDefault(const Constant(100))(); // 0-100
  
  BoolColumn get requiresReview => boolean().withDefault(const Constant(false))();
  
  TextColumn get transferId => text().withLength(min: 1, max: 50).nullable()(); // UUID for transfer pairs
  
  TextColumn get note => text().withLength(max: 500).nullable()();
}
