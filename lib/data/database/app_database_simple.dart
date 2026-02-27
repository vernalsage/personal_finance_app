import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/auth_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'tables/profiles_table.dart';
import 'tables/accounts_table.dart';
import 'tables/categories_table.dart';
import 'tables/merchants_table.dart';
import 'tables/tags_table.dart';
import 'tables/transactions_table.dart';
import 'tables/budgets_table.dart';
import 'tables/recurring_rules_table.dart';
import 'tables/goals_table.dart';
import 'tables/transaction_tags_table.dart';
import 'tables/transaction_goals_table.dart';
import 'tables/notification_fingerprints_table.dart';

part 'app_database_simple.g.dart';

/// Main database class using Drift with SQLCipher encryption
@DriftDatabase(
  tables: [
    Profiles,
    Accounts,
    Categories,
    Merchants,
    Tags,
    Transactions,
    Budgets,
    RecurringRules,
    Goals,
    TransactionTags,
    TransactionGoals,
    NotificationFingerprints,
  ],
)
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal()
    : super(DatabaseConnection.delayed(_openConnection()));

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );

  /// Opens a connection to the database (non-blocking)
  static Future<DatabaseConnection> _openConnection() async {
    // Get the database file path asynchronously
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = '${dbFolder.path}/finance_ledger_v2_encrypted.sqlite';

    // Get or create encryption key
    final authService = AuthService.instance;
    String? key = await authService.getEncryptionKey();

    if (key == null) {
      // Generate a new 32-character random key
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64Url.encode(values);
      await authService.storeEncryptionKey(key);
    }

    final file = File(dbPath);

    // Fail-safe: ensure override is set before opening
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    // Open database with encryption
    return DatabaseConnection(
      NativeDatabase(
        file,
        setup: (database) {
          database.execute("PRAGMA key = '$key';");
          database.execute("PRAGMA foreign_keys = ON;");
        },
      ),
    );
  }

  /// Initialize database with default data
  Future<void> initializeDefaultData() async {
    // Check if profiles table is empty
    final profilesCount = await (select(
      profiles,
    )).get().then((list) => list.length);

    if (profilesCount == 0) {
      await transaction(() async {
        // Create default profile
        final profileId = await into(profiles).insert(
          ProfilesCompanion.insert(
            name: 'Default Profile',
            currency: 'NGN',
            isActive: const Value(true),
          ),
        );

        // Create default categories
        await _createDefaultCategories(profileId);

        // Create default tags
        await _createDefaultTags(profileId);
      });
    }
  }

  /// Create default categories for a new profile
  Future<void> _createDefaultCategories(int profileId) async {
    final defaultCategories = [
      ('Food & Dining', '#FF6B35', 'restaurant'),
      ('Transportation', '#4285F4', 'directions_car'),
      ('Shopping', '#9C27B0', 'shopping_cart'),
      ('Entertainment', '#FF9800', 'movie'),
      ('Bills & Utilities', '#F44336', 'receipt'),
      ('Healthcare', '#4CAF50', 'local_hospital'),
      ('Education', '#2196F3', 'school'),
      ('Salary', '#4CAF50', 'payments'),
      ('Investment', '#FF9800', 'trending_up'),
      ('Other', '#9E9E9E', 'more_horiz'),
    ];

    for (final (name, color, icon) in defaultCategories) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          profileId: profileId,
          name: name,
          color: color,
          icon: icon,
          isActive: const Value(true),
        ),
      );
    }
  }

  /// Create default tags for a new profile
  Future<void> _createDefaultTags(int profileId) async {
    final defaultTags = [
      ('Business', '#FF5722'),
      ('Personal', '#2196F3'),
      ('Urgent', '#F44336'),
      ('Tax Deductible', '#4CAF50'),
      ('Recurring', '#9C27B0'),
    ];

    for (final (name, color) in defaultTags) {
      await into(tags).insert(
        TagsCompanion.insert(
          profileId: profileId,
          name: name,
          color: color,
          isActive: const Value(true),
        ),
      );
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final profilesCount = await (select(
      profiles,
    )).get().then((list) => list.length);
    final accountsCount = await (select(
      accounts,
    )).get().then((list) => list.length);
    final transactionsCount = await (select(
      transactions,
    )).get().then((list) => list.length);
    final categoriesCount = await (select(
      categories,
    )).get().then((list) => list.length);
    final merchantsCount = await (select(
      merchants,
    )).get().then((list) => list.length);
    final tagsCount = await (select(tags)).get().then((list) => list.length);

    return {
      'profiles': profilesCount,
      'accounts': accountsCount,
      'transactions': transactionsCount,
      'categories': categoriesCount,
      'merchants': merchantsCount,
      'tags': tagsCount,
    };
  }
}
