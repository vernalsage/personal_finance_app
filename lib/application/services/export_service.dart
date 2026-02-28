import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/repositories/itransaction_repository.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';

class CSVExportService {
  final ITransactionRepository _transactionRepository;

  CSVExportService(this._transactionRepository);

  Future<void> exportTransactions(int profileId) async {
    try {
      final result = await _transactionRepository.getTransactionsWithDetails(
        profileId: profileId,
      );

      if (result.isFailure) {
        throw Exception('Failed to fetch transactions: ${result.failureData}');
      }

      final transactions = result.successData!;
      if (transactions.isEmpty) {
        throw Exception('No transactions found to export');
      }

      final List<List<dynamic>> rows = [];
      
      // Headers
      rows.add([
        'Date',
        'Description',
        'Account',
        'Category',
        'Merchant',
        'Amount',
        'Currency',
        'Type',
        'Note'
      ]);

      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      for (final txDetails in transactions) {
        final tx = txDetails.transaction;
        final account = txDetails.account;
        final category = txDetails.category;
        final merchant = txDetails.merchant;
        
        final currency = account?.currency ?? 'NGN';
        final amount = tx.amountMinor / 100.0;
        
        rows.add([
          dateFormat.format(tx.timestamp),
          tx.description,
          account?.name ?? 'Unknown',
          category?.name ?? 'Uncategorized',
          merchant?.name ?? '',
          amount,
          currency,
          tx.type,
          tx.note ?? '',
        ]);
      }

      final csvContent = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/transactions_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Transactions Export',
        text: 'Here is your transaction history export from Personal Finance App.',
      );
    } catch (e) {
      debugPrint('🚨 Export failed: $e');
      rethrow;
    }
  }
}
