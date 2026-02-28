import 'package:drift/drift.dart' hide isNull;
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
    
    // Create base profile
    await db.into(db.profiles).insert(
      ProfilesCompanion.insert(name: 'Test Profile', currency: 'NGN')
    );
    
    // Create default merchant
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

  group('TransactionsDao History Enhancements', () {
    test('Chronological Sorting (Newest First)', () async {
      final accountId = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: 1,
          name: 'Main Bank',
          type: 'bank',
          currency: 'NGN',
          balanceMinor: const Value(100000),
        )
      );

      final now = DateTime.now();
      
      // Insert transactions out of order
      await transactionsDao.createTransaction(
        TransactionsCompanion.insert(
          profileId: 1, accountId: accountId, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 1000, type: 'debit', description: 'Middle',
          timestamp: now.subtract(const Duration(days: 1)),
        )
      );
      await transactionsDao.createTransaction(
        TransactionsCompanion.insert(
          profileId: 1, accountId: accountId, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 2000, type: 'debit', description: 'Newest',
          timestamp: now,
        )
      );
      await transactionsDao.createTransaction(
        TransactionsCompanion.insert(
          profileId: 1, accountId: accountId, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 500, type: 'debit', description: 'Oldest',
          timestamp: now.subtract(const Duration(days: 2)),
        )
      );

      final txs = await transactionsDao.getAllTransactions(profileId: 1);
      
      expect(txs.length, 3);
      expect(txs[0].description, 'Newest');
      expect(txs[1].description, 'Middle');
      expect(txs[2].description, 'Oldest');
    });

    test('updateTransaction: Balance Management (Same Account)', () async {
      final accountId = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: 1,
          name: 'Main Bank',
          type: 'bank',
          currency: 'NGN',
          balanceMinor: const Value(1000000), // ₦10,000
        )
      );

      // Create initial transaction (₦2,000 debit)
      final tx = await transactionsDao.createTransaction(
        TransactionsCompanion.insert(
          profileId: 1, accountId: accountId, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 200000, type: 'debit', description: 'Initial',
          timestamp: DateTime.now(),
        )
      );
      
      // Verify initial balance: 10,000 - 2,000 = 8,000 (800,000 minor)
      var acc = await (db.select(db.accounts)..where((t) => t.id.equals(accountId))).getSingle();
      expect(acc.balanceMinor, 800000);

      // Update transaction amount: change from ₦2,000 to ₦5,000
      await transactionsDao.updateTransaction(
        TransactionsCompanion(
          id: Value(tx.id),
          amountMinor: const Value(500000),
        )
      );

      // Verify new balance: 10,000 - 5,000 = 5,000 (500,000 minor)
      // Logic: 800,000 (current) + 200,000 (revert old signed) - 500,000 (apply new signed) = 500,000
      acc = await (db.select(db.accounts)..where((t) => t.id.equals(accountId))).getSingle();
      expect(acc.balanceMinor, 500000);
    });

    test('updateTransaction: Balance Management (Change Account)', () async {
      final acc1Id = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: 1, name: 'Acc 1', type: 'bank', currency: 'NGN',
          balanceMinor: const Value(1000000), // ₦10,000
        )
      );
      final acc2Id = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: 1, name: 'Acc 2', type: 'bank', currency: 'NGN',
          balanceMinor: const Value(1000000), // ₦10,000
        )
      );

      // Create transaction on Acc 1 (₦3,000 debit)
      final tx = await transactionsDao.createTransaction(
        TransactionsCompanion.insert(
          profileId: 1, accountId: acc1Id, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 300000, type: 'debit', description: 'Transferable',
          timestamp: DateTime.now(),
        )
      );

      // Acc 1: 7,000. Acc 2: 10,000.
      var acc1 = await (db.select(db.accounts)..where((t) => t.id.equals(acc1Id))).getSingle();
      var acc2 = await (db.select(db.accounts)..where((t) => t.id.equals(acc2Id))).getSingle();
      expect(acc1.balanceMinor, 700000);
      expect(acc2.balanceMinor, 1000000);

      // Move transaction to Acc 2 and change to Credit
      await transactionsDao.updateTransaction(
        TransactionsCompanion(
          id: Value(tx.id),
          accountId: Value(acc2Id),
          type: const Value('credit'),
          amountMinor: const Value(100000), // ₦1,000 credit
        )
      );

      // Acc 1 should revert: 7,000 + 3,000 = 10,000.
      // Acc 2 should apply: 10,000 + 1,000 = 11,000.
      acc1 = await (db.select(db.accounts)..where((t) => t.id.equals(acc1Id))).getSingle();
      acc2 = await (db.select(db.accounts)..where((t) => t.id.equals(acc2Id))).getSingle();
      expect(acc1.balanceMinor, 1000000);
      expect(acc2.balanceMinor, 1100000);
    });

    test('updateTransaction: Linked Transfer Syncing', () async {
      final acc1Id = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: 1, name: 'Acc 1', type: 'bank', currency: 'NGN',
          balanceMinor: const Value(1000000),
        )
      );
      final acc2Id = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: 1, name: 'Acc 2', type: 'bank', currency: 'NGN',
          balanceMinor: const Value(1000000),
        )
      );

      final transferId = 'transfer-123';
      final now = DateTime.now();

      // Create linked transfer manually or via executeTransfer
      final txs = await transactionsDao.executeTransfer(
        outEntry: TransactionsCompanion.insert(
          profileId: 1, accountId: acc1Id, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 200000, type: 'transfer_out', description: 'Out',
          timestamp: now, transferId: Value(transferId),
        ),
        inEntry: TransactionsCompanion.insert(
          profileId: 1, accountId: acc2Id, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 200000, type: 'transfer_in', description: 'In',
          timestamp: now, transferId: Value(transferId),
        ),
      );

      // Verify initial balances: 8,000 and 12,000
      var a1 = await (db.select(db.accounts)..where((t) => t.id.equals(acc1Id))).getSingle();
      var a2 = await (db.select(db.accounts)..where((t) => t.id.equals(acc2Id))).getSingle();
      expect(a1.balanceMinor, 800000);
      expect(a2.balanceMinor, 1200000);

      // Update "Out" side: change amount to 5,000, new description
      await transactionsDao.updateTransaction(
        TransactionsCompanion(
          id: Value(txs[0].id),
          amountMinor: const Value(500000),
          description: const Value('Shared Update'),
        )
      );

      // Verify BOTH sides updated
      final updatedOut = await transactionsDao.getTransaction(txs[0].id);
      final updatedIn = await transactionsDao.getTransaction(txs[1].id);

      expect(updatedOut!.amountMinor, -500000);
      expect(updatedOut.description, 'Shared Update');
      expect(updatedIn!.amountMinor, 500000); // Auto-synced
      expect(updatedIn.description, 'Shared Update'); // Auto-synced

      // Verify new balances: 10,000 - 5,000 = 5,000 and 10,000 + 5,000 = 15,000
      a1 = await (db.select(db.accounts)..where((t) => t.id.equals(acc1Id))).getSingle();
      a2 = await (db.select(db.accounts)..where((t) => t.id.equals(acc2Id))).getSingle();
      expect(a1.balanceMinor, 500000);
      expect(a2.balanceMinor, 1500000);
    });

    test('deleteTransaction: Linked Transfer Robustness', () async {
      final acc1Id = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: 1, name: 'Acc 1', type: 'bank', currency: 'NGN',
          balanceMinor: const Value(1000000),
        )
      );
      final acc2Id = await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          profileId: 1, name: 'Acc 2', type: 'bank', currency: 'NGN',
          balanceMinor: const Value(1000000),
        )
      );

      final txs = await transactionsDao.executeTransfer(
        outEntry: TransactionsCompanion.insert(
          profileId: 1, accountId: acc1Id, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 200000, type: 'transfer_out', description: 'Out',
          timestamp: DateTime.now(), transferId: const Value('t-delete'),
        ),
        inEntry: TransactionsCompanion.insert(
          profileId: 1, accountId: acc2Id, 
          categoryId: const Value(1), merchantId: const Value(1),
          amountMinor: 200000, type: 'transfer_in', description: 'In',
          timestamp: DateTime.now(), transferId: const Value('t-delete'),
        ),
      );

      // Delete one side
      await transactionsDao.deleteTransaction(txs[0].id);

      // Both should be gone
      final t1 = await transactionsDao.getTransaction(txs[0].id);
      final t2 = await transactionsDao.getTransaction(txs[1].id);
      expect(t1, isNull);
      expect(t2, isNull);

      // Balances should be back to 10,000
      final a1 = await (db.select(db.accounts)..where((t) => t.id.equals(acc1Id))).getSingle();
      final a2 = await (db.select(db.accounts)..where((t) => t.id.equals(acc2Id))).getSingle();
      expect(a1.balanceMinor, 1000000);
      expect(a2.balanceMinor, 1000000);
    });
  });
}
