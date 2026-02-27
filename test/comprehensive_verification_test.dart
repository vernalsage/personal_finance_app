import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/data/database/app_database_simple.dart';
import 'package:personal_finance_app/data/database/daos/transactions_dao.dart';

void main() {
  late AppDatabase db;
  late TransactionsDao transactionsDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    transactionsDao = TransactionsDao(db);
    
    // Create required base data
    await db.into(db.merchants).insert(
      MerchantsCompanion.insert(
        profileId: 1,
        name: 'Default Merchant',
        normalizedName: 'default',
        lastSeen: DateTime.now(),
      )
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Comprehensive Feature Verification', () {
    test('1. Profile & Account Integrity (CRUD + Starting Balance)', () async {
      // Create Profile
      final profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(name: 'Test Profile', currency: 'NGN')
      );

      // Create Account with Starting Balance
      final accountId = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: profileId,
          name: 'Main Bank',
          type: 'bank',
          currency: 'NGN',
          balanceMinor: const Value(500000), // ₦5,000.00
        )
      );

      final account = await (db.select(db.accounts)..where((t) => t.id.equals(accountId))).getSingle();
      expect(account.balanceMinor, 500000);
    });

    test('2. Signed Transaction Logic (Negative Expenses, Positive Income)', () async {
      final profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(name: 'Test Profile', currency: 'NGN')
      );
      final accountId = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: profileId,
          name: 'Main Bank',
          type: 'bank',
          currency: 'NGN',
          balanceMinor: const Value(1000000), // ₦10,000.00
        )
      );

      // Create Expense (Debit)
      await transactionsDao.createTransaction(
        TransactionsCompanion.insert(
          profileId: profileId,
          accountId: accountId,
          categoryId: 1,
          merchantId: 1,
          amountMinor: 200000, // Absolute ₦2,000.00
          type: 'debit',
          description: 'Grocery Shopping',
          timestamp: DateTime.now(),
        )
      );

      // Create Income (Credit)
      await transactionsDao.createTransaction(
        TransactionsCompanion.insert(
          profileId: profileId,
          accountId: accountId,
          categoryId: 1,
          merchantId: 1,
          amountMinor: 500000, // Absolute ₦5,000.00
          type: 'credit',
          description: 'Freelance Work',
          timestamp: DateTime.now(),
        )
      );

      final txs = await transactionsDao.getAllTransactions(profileId: profileId);
      final expense = txs.firstWhere((t) => t.description == 'Grocery Shopping');
      final income = txs.firstWhere((t) => t.description == 'Freelance Work');

      // Verify signed storage
      expect(expense.amountMinor, -200000);
      expect(income.amountMinor, 500000);

      // Verify account balance update (10,000 - 2,000 + 5,000 = 13,000)
      final account = await (db.select(db.accounts)..where((t) => t.id.equals(accountId))).getSingle();
      expect(account.balanceMinor, 1300000);
    });

    test('3. Atomic Transfer Integrity', () async {
      final profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(name: 'Test Profile', currency: 'NGN')
      );
      final sourceId = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: profileId,
          name: 'Source Bank',
          type: 'bank',
          currency: 'NGN',
          balanceMinor: const Value(1000000), // ₦10,000.00
        )
      );
      final destId = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: profileId,
          name: 'Dest Wallet',
          type: 'wallet',
          currency: 'NGN',
          balanceMinor: const Value(0),
        )
      );

      await transactionsDao.executeTransfer(
        outEntry: TransactionsCompanion.insert(
          profileId: profileId,
          accountId: sourceId,
          categoryId: 1,
          merchantId: 1,
          amountMinor: 300000, // ₦3,000.00
          type: 'transfer_out',
          description: 'Transfer to Wallet',
          timestamp: DateTime.now(),
        ),
        inEntry: TransactionsCompanion.insert(
          profileId: profileId,
          accountId: destId,
          categoryId: 1,
          merchantId: 1,
          amountMinor: 300000, // ₦3,000.00
          type: 'transfer_in',
          description: 'Transfer from Bank',
          timestamp: DateTime.now(),
        ),
      );

      final sourceAcc = await (db.select(db.accounts)..where((t) => t.id.equals(sourceId))).getSingle();
      final destAcc = await (db.select(db.accounts)..where((t) => t.id.equals(destId))).getSingle();

      expect(sourceAcc.balanceMinor, 700000); // ₦7,000.00
      expect(destAcc.balanceMinor, 300000); // ₦3,000.00
    });

    test('4. Budget Usage Tracking', () async {
       final profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(name: 'Test Profile', currency: 'NGN')
      );
      final accountId = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: profileId,
          name: 'Main Bank',
          type: 'bank',
          currency: 'NGN',
          balanceMinor: const Value(1000000),
        )
      );

      // Create Budget for Category 1
      await db.into(db.budgets).insert(
        BudgetsCompanion.insert(
          profileId: profileId,
          categoryId: 1,
          amountMinor: 500000, // ₦5,000 limit
          month: DateTime.now().month,
          year: DateTime.now().year,
        )
      );

      // Add spending for that category
      await transactionsDao.createTransaction(
        TransactionsCompanion.insert(
          profileId: profileId,
          accountId: accountId,
          categoryId: 1,
          merchantId: 1,
          amountMinor: 200000, // ₦2,000 spent
          type: 'debit',
          description: 'Budgeted Expense',
          timestamp: DateTime.now(),
        )
      );

      // Verify spending in that month (Summing negative amounts as positive expenses)
      final totalSpent = await transactionsDao.getTotalAmountByType(
        profileId, 
        'debit',
        categoryId: 1,
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
      );

      expect(totalSpent.abs(), 200000); // Verify it tracks the spend
    });
  });
}
