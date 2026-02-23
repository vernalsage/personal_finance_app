import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/merchant_model.dart';
import '../../data/models/tag_model.dart';

/// Service for exporting data to CSV files
class ExportService {
  ExportService._();

  static final ExportService _instance = ExportService._();
  static ExportService get instance => _instance;

  /// Export all data to Power BI ready CSV files
  Future<ExportResult> exportToPowerBI({
    required List<TransactionModel> transactions,
    required List<ProfileModel> profiles,
    required List<AccountModel> accounts,
    required List<CategoryModel> categories,
    required List<MerchantModel> merchants,
    required List<TagModel> tags,
    required Map<int, List<int>> transactionTags,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final files = <String, File>{};

      // Export Fact_Transactions
      files['Fact_Transactions'] = await _exportTransactions(
        transactions,
        '${exportDir.path}/Fact_Transactions_$timestamp.csv',
      );

      // Export Dim_Profiles
      files['Dim_Profiles'] = await _exportProfiles(
        profiles,
        '${exportDir.path}/Dim_Profiles_$timestamp.csv',
      );

      // Export Dim_Accounts
      files['Dim_Accounts'] = await _exportAccounts(
        accounts,
        '${exportDir.path}/Dim_Accounts_$timestamp.csv',
      );

      // Export Dim_Categories
      files['Dim_Categories'] = await _exportCategories(
        categories,
        '${exportDir.path}/Dim_Categories_$timestamp.csv',
      );

      // Export Dim_Merchants
      files['Dim_Merchants'] = await _exportMerchants(
        merchants,
        '${exportDir.path}/Dim_Merchants_$timestamp.csv',
      );

      // Export Dim_Tags
      files['Dim_Tags'] = await _exportTags(
        tags,
        '${exportDir.path}/Dim_Tags_$timestamp.csv',
      );

      // Export Bridge_TransactionTags
      files['Bridge_TransactionTags'] = await _exportTransactionTags(
        transactionTags,
        '${exportDir.path}/Bridge_TransactionTags_$timestamp.csv',
      );

      // Export Dim_Time
      files['Dim_Time'] = await _exportTimeDimension(
        transactions,
        '${exportDir.path}/Dim_Time_$timestamp.csv',
      );

      return ExportResult(
        success: true,
        files: files,
        message: 'Export completed successfully',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        files: {},
        message: 'Export failed: $e',
      );
    }
  }

  /// Export transactions fact table
  Future<File> _exportTransactions(
    List<TransactionModel> transactions,
    String filePath,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();

    // Write header
    sink.writeln(
      'TransactionId,ProfileId,AccountId,CategoryId,MerchantId,AmountMinor,Type,Description,Timestamp,ConfidenceScore,RequiresReview,TransferId,Note',
    );

    // Write data
    for (final transaction in transactions) {
      final row = [
        transaction.id,
        transaction.profileId,
        transaction.accountId,
        transaction.categoryId,
        transaction.merchantId,
        transaction.amountMinor,
        transaction.type.name,
        _escapeCsvField(transaction.description),
        transaction.timestamp.toIso8601String(),
        transaction.confidenceScore,
        transaction.requiresReview,
        transaction.transferId ?? '',
        _escapeCsvField(transaction.note ?? ''),
      ].join(',');
      sink.writeln(row);
    }

    await sink.close();
    return file;
  }

  /// Export profiles dimension
  Future<File> _exportProfiles(
    List<ProfileModel> profiles,
    String filePath,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();

    sink.writeln('ProfileId,Name,Currency,IsActive,CreatedAt,UpdatedAt');

    for (final profile in profiles) {
      final row = [
        profile.id,
        _escapeCsvField(profile.name),
        profile.currency,
        profile.isActive,
        profile.createdAt?.toIso8601String() ?? '',
        profile.updatedAt?.toIso8601String() ?? '',
      ].join(',');
      sink.writeln(row);
    }

    await sink.close();
    return file;
  }

  /// Export accounts dimension
  Future<File> _exportAccounts(
    List<AccountModel> accounts,
    String filePath,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();

    sink.writeln(
      'AccountId,ProfileId,Name,Type,BalanceMinor,Currency,IsActive,Description',
    );

    for (final account in accounts) {
      final row = [
        account.id,
        account.profileId,
        _escapeCsvField(account.name),
        account.type.name,
        account.balanceMinor,
        account.currency,
        account.isActive,
        _escapeCsvField(account.description ?? ''),
      ].join(',');
      sink.writeln(row);
    }

    await sink.close();
    return file;
  }

  /// Export categories dimension
  Future<File> _exportCategories(
    List<CategoryModel> categories,
    String filePath,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();

    sink.writeln('CategoryId,ProfileId,Name,Color,Icon,IsActive,ParentId');

    for (final category in categories) {
      final row = [
        category.id,
        category.profileId,
        _escapeCsvField(category.name),
        category.color,
        category.icon,
        category.isActive,
        category.parentId ?? '',
      ].join(',');
      sink.writeln(row);
    }

    await sink.close();
    return file;
  }

  /// Export merchants dimension
  Future<File> _exportMerchants(
    List<MerchantModel> merchants,
    String filePath,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();

    sink.writeln(
      'MerchantId,ProfileId,Name,NormalizedName,LastSeen,CategoryId',
    );

    for (final merchant in merchants) {
      final row = [
        merchant.id,
        merchant.profileId,
        _escapeCsvField(merchant.name),
        _escapeCsvField(merchant.normalizedName),
        merchant.lastSeen.toIso8601String(),
        merchant.categoryId ?? '',
      ].join(',');
      sink.writeln(row);
    }

    await sink.close();
    return file;
  }

  /// Export tags dimension
  Future<File> _exportTags(List<TagModel> tags, String filePath) async {
    final file = File(filePath);
    final sink = file.openWrite();

    sink.writeln('TagId,ProfileId,Name,Color,IsActive');

    for (final tag in tags) {
      final row = [
        tag.id,
        tag.profileId,
        _escapeCsvField(tag.name),
        tag.color,
        tag.isActive,
      ].join(',');
      sink.writeln(row);
    }

    await sink.close();
    return file;
  }

  /// Export transaction tags bridge table
  Future<File> _exportTransactionTags(
    Map<int, List<int>> transactionTags,
    String filePath,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();

    sink.writeln('TransactionId,TagId');

    for (final entry in transactionTags.entries) {
      final transactionId = entry.key;
      for (final tagId in entry.value) {
        sink.writeln('$transactionId,$tagId');
      }
    }

    await sink.close();
    return file;
  }

  /// Export time dimension
  Future<File> _exportTimeDimension(
    List<TransactionModel> transactions,
    String filePath,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();

    sink.writeln('DateId,Date,Year,Month,Quarter,DayOfWeek,IsWeekend');

    if (transactions.isEmpty) {
      await sink.close();
      return file;
    }

    final dates = transactions
        .map(
          (t) => DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day),
        )
        .toSet()
        .toList();
    dates.sort();

    for (final date in dates) {
      final dateId = DateUtils.toDateId(date);
      final isWeekend = DateUtils.isWeekend(date);
      final quarter = DateUtils.getQuarter(date);

      final row = [
        dateId,
        date.toIso8601String(),
        date.year,
        date.month,
        quarter,
        date.weekday,
        isWeekend,
      ].join(',');
      sink.writeln(row);
    }

    await sink.close();
    return file;
  }

  /// Escape CSV field to handle commas and quotes
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

/// Result of export operation
class ExportResult {
  const ExportResult({
    required this.success,
    required this.files,
    required this.message,
  });

  final bool success;
  final Map<String, File> files;
  final String message;

  int get fileCount => files.length;

  List<String> get fileNames => files.values.map((file) => file.path).toList();
}
