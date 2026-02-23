import '../../core/errors/exceptions.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/monetary_utils.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/merchant_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';

/// Service for parsing bank notifications
class ParsingService {
  ParsingService._();

  static final ParsingService _instance = ParsingService._();
  static ParsingService get instance => _instance;

  /// Parse a bank notification and extract transaction information
  Future<ParsedTransaction> parseNotification({
    required String packageName,
    required String title,
    required String text,
    required int profileId,
    List<AccountModel>? accounts,
    List<CategoryModel>? categories,
    List<MerchantModel>? merchants,
  }) async {
    try {
      // Check if package is supported
      if (!_isSupportedPackage(packageName)) {
        throw ParsingException(
          'Unsupported package: $packageName',
          'UNSUPPORTED_PACKAGE',
        );
      }

      // Extract transaction details using regex patterns
      final extraction = await _extractTransactionDetails(
        packageName,
        title,
        text,
        accounts: accounts,
        categories: categories,
        merchants: merchants,
      );

      // Calculate confidence score
      final confidenceScore = _calculateConfidenceScore(extraction);

      // Check if confidence meets threshold
      if (confidenceScore < AppConstants.notificationConfidenceThreshold) {
        extraction.requiresReview = true;
      }

      return extraction;
    } catch (e) {
      throw ParsingException(
        'Failed to parse notification: $e',
        'PARSING_ERROR',
      );
    }
  }

  /// Check if the package is supported for parsing
  bool _isSupportedPackage(String packageName) {
    // TODO: Add supported bank package names
    const supportedPackages = [
      'com.stanbicbank',
      'com.gtbank',
      'com.accessbank',
      'com.firstbank',
      'com.ubagroup',
      'com.zenithbank',
      // Add more bank packages as needed
    ];

    return supportedPackages.contains(packageName);
  }

  /// Extract transaction details from notification text
  Future<ParsedTransaction> _extractTransactionDetails(
    String packageName,
    String title,
    String text, {
    List<AccountModel>? accounts,
    List<CategoryModel>? categories,
    List<MerchantModel>? merchants,
  }) async {
    // Normalize text for parsing
    final normalizedText = _normalizeText(text);

    // Extract amount
    final amount = _extractAmount(normalizedText);
    if (amount == null) {
      throw ParsingException('Could not extract amount', 'NO_AMOUNT_FOUND');
    }

    // Extract transaction type
    final transactionType = _extractTransactionType(normalizedText, title);

    // Extract merchant name
    final merchantName = _extractMerchantName(normalizedText, title);

    // Extract account information
    final accountInfo = _extractAccountInfo(normalizedText, accounts);

    // Extract description
    final description = _extractDescription(
      normalizedText,
      title,
      merchantName,
    );

    // Resolve merchant
    final resolvedMerchant = await _resolveMerchant(
      merchantName,
      profileId: 1, // TODO: Get actual profile ID
      merchants: merchants,
    );

    return ParsedTransaction(
      amountMinor: MonetaryUtils.toMinorUnits(amount),
      type: transactionType,
      description: description,
      merchantName: merchantName,
      resolvedMerchant: resolvedMerchant,
      accountId: accountInfo?.id ?? 0, // TODO: Handle default account
      categoryId: resolvedMerchant?.categoryId,
      confidenceScore: 0, // Will be calculated separately
      requiresReview: false, // Will be determined by confidence score
      packageName: packageName,
      rawText: text,
    );
  }

  /// Normalize text for parsing
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\.\,\-\₦\$€£]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extract amount from text
  double? _extractAmount(String text) {
    // Pattern for amounts with currency symbols
    final patterns = [
      RegExp(r'₦\s*([\d,]+\.?\d*)'), // Nigerian Naira
      RegExp(r'\$\s*([\d,]+\.?\d*)'), // US Dollar
      RegExp(r'€\s*([\d,]+\.?\d*)'), // Euro
      RegExp(r'£\s*([\d,]+\.?\d*)'), // British Pound
      RegExp(r'([\d,]+\.?\d*)\s*ngn'), // NGN suffix
      RegExp(r'([\d,]+\.?\d*)\s*usd'), // USD suffix
      RegExp(
        r'debited\s+([\d,]+\.?\d*)',
        caseSensitive: false,
      ), // Debited amount
      RegExp(
        r'credited\s+([\d,]+\.?\d*)',
        caseSensitive: false,
      ), // Credited amount
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          return double.tryParse(amountStr);
        }
      }
    }

    return null;
  }

  /// Extract transaction type from text
  TransactionType _extractTransactionType(String text, String title) {
    final debitKeywords = [
      'debit',
      'withdraw',
      'deduct',
      'charge',
      'payment',
      'transfer',
      'sent',
    ];
    final creditKeywords = [
      'credit',
      'deposit',
      'receive',
      'received',
      'incoming',
      'got',
    ];

    final combinedText = '$text $title'.toLowerCase();

    for (final keyword in debitKeywords) {
      if (combinedText.contains(keyword)) {
        return TransactionType.expense;
      }
    }

    for (final keyword in creditKeywords) {
      if (combinedText.contains(keyword)) {
        return TransactionType.income;
      }
    }

    // Default to expense if unclear
    return TransactionType.expense;
  }

  /// Extract merchant name from text
  String _extractMerchantName(String text, String title) {
    // Common patterns for merchant extraction
    final patterns = [
      RegExp(r'to\s+([a-z0-9\s]+)', caseSensitive: false), // "to merchant"
      RegExp(r'from\s+([a-z0-9\s]+)', caseSensitive: false), // "from merchant"
      RegExp(r'at\s+([a-z0-9\s]+)', caseSensitive: false), // "at merchant"
      RegExp(
        r'payment\s+to\s+([a-z0-9\s]+)',
        caseSensitive: false,
      ), // "payment to merchant"
      RegExp(
        r'transfer\s+to\s+([a-z0-9\s]+)',
        caseSensitive: false,
      ), // "transfer to merchant"
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        var merchant = match.group(1)?.trim();
        if (merchant != null && merchant.isNotEmpty) {
          // Clean up merchant name
          merchant = merchant.split(' ').take(3).join(' '); // Limit to 3 words
          return merchant;
        }
      }
    }

    // Try to extract from title if no match in text
    if (title.isNotEmpty) {
      return title.split(' ').take(2).join(' ');
    }

    return 'Unknown Merchant';
  }

  /// Extract account information from text
  AccountModel? _extractAccountInfo(String text, List<AccountModel>? accounts) {
    if (accounts == null || accounts.isEmpty) return null;

    // Look for account number patterns
    final accountPattern = RegExp(r'account\s+(\*+\d+)', caseSensitive: false);
    final match = accountPattern.firstMatch(text);

    if (match != null) {
      // Find account by masked number
      for (final account in accounts) {
        // TODO: Implement account number masking logic
        if (account.name.toLowerCase().contains(text.toLowerCase())) {
          return account;
        }
      }
    }

    return null;
  }

  /// Extract description from text
  String _extractDescription(String text, String title, String merchantName) {
    // Use title as primary description
    if (title.isNotEmpty && title != 'Notification') {
      return title;
    }

    // Use merchant name as fallback
    if (merchantName != 'Unknown Merchant') {
      return 'Transaction at $merchantName';
    }

    // Use a portion of the text as last resort
    final words = text.split(' ');
    if (words.length >= 3) {
      return words.take(3).join(' ');
    }

    return 'Bank Transaction';
  }

  /// Resolve merchant from existing merchants or create new one
  Future<MerchantModel?> _resolveMerchant(
    String merchantName, {
    required int profileId,
    List<MerchantModel>? merchants,
  }) async {
    if (merchants == null || merchants.isEmpty) return null;

    // Normalize merchant name for matching
    final normalizedName = merchantName.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    // Try to find existing merchant
    for (final merchant in merchants) {
      if (merchant.normalizedName == normalizedName &&
          merchant.profileId == profileId) {
        return merchant;
      }
    }

    return null; // TODO: Create new merchant if not found
  }

  /// Calculate confidence score for parsed transaction
  int _calculateConfidenceScore(ParsedTransaction transaction) {
    int score = 0;

    // Amount extraction (40 points)
    if (transaction.amountMinor > 0) {
      score += 40;
    }

    // Transaction type clarity (20 points)
    if (transaction.type != TransactionType.expense ||
        transaction.description.toLowerCase().contains('debit')) {
      score += 20;
    }

    // Merchant name quality (20 points)
    if (transaction.merchantName != 'Unknown Merchant' &&
        transaction.merchantName.length > 2) {
      score += 20;
    }

    // Description quality (10 points)
    if (transaction.description.isNotEmpty &&
        transaction.description != 'Bank Transaction') {
      score += 10;
    }

    // Account resolution (10 points)
    if (transaction.accountId > 0) {
      score += 10;
    }

    return score.clamp(0, 100);
  }
}

/// Parsed transaction result
class ParsedTransaction {
  ParsedTransaction({
    required this.amountMinor,
    required this.type,
    required this.description,
    required this.merchantName,
    this.resolvedMerchant,
    required this.accountId,
    this.categoryId,
    required this.confidenceScore,
    required this.requiresReview,
    required this.packageName,
    required this.rawText,
  });

  final int amountMinor;
  final TransactionType type;
  final String description;
  final String merchantName;
  final MerchantModel? resolvedMerchant;
  final int accountId;
  final int? categoryId;
  int confidenceScore;
  bool requiresReview;
  final String packageName;
  final String rawText;

  /// Convert to transaction model
  TransactionModel toTransactionModel({
    required int profileId,
    required DateTime timestamp,
    String? transferId,
    String? note,
  }) {
    return TransactionModel(
      id: 0, // Will be set by database
      profileId: profileId,
      accountId: accountId,
      categoryId: categoryId ?? 0, // TODO: Handle default category
      merchantId: resolvedMerchant?.id ?? 0, // TODO: Handle default merchant
      amountMinor: amountMinor,
      type: type,
      description: description,
      timestamp: timestamp,
      confidenceScore: confidenceScore,
      requiresReview: requiresReview,
      transferId: transferId,
      note: note,
    );
  }
}
