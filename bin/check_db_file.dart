import 'dart:io';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

void main() async {
  print('--- Database Diagnostics ---');
  
  // Try to find the database file
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
  final dbPath = p.join(home, 'Documents', 'finance_ledger_v2_encrypted.sqlite');
  
  print('Looking for database at: $dbPath');
  final file = File(dbPath);
  if (!file.existsSync()) {
    print('ERROR: Database file not found!');
    return;
  }
  
  print('Database file size: ${file.lengthSync()} bytes');
  print('Note: This script cannot read encrypted data without the key.');
  print('We will use the application logic to check counts instead via a test.');
}
