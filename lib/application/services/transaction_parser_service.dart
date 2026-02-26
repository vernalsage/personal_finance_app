import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Result of parsing a transaction notification
class ParsedTransactionResult {
  const ParsedTransactionResult({
    this.amountMinor,
    this.transactionType,
    this.merchantString,
    this.timestamp,
    this.balanceMinor,
    this.confidenceScore = 0,
    this.requiresReview = true,
    this.rawText,
  });

  final int? amountMinor;
  final String? transactionType;
  final String? merchantString;
  final DateTime? timestamp;
  final int? balanceMinor;
  final int confidenceScore;
  final bool requiresReview;
  final String? rawText;

  /// Generate hash fingerprint for duplicate detection
  String get fingerprint {
    if (rawText == null) return '';
    final bytes = utf8.encode(rawText!.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Service for parsing transaction notifications with confidence scoring
class TransactionParserService {
  TransactionParserService();

  // Confidence weights as specified in the requirements
  static const int _amountWeight = 40;
  static const int _typeWeight = 20;
  static const int _merchantWeight = 20;
  static const int _timestampWeight = 10;
  static const int _balanceWeight = 10;
  static const int _confidenceThreshold = 80;

  // Patterns for Amount
  static final List<RegExp> _amountPatterns = [
    RegExp(r'(?:Amt|Amount|₦|NGN)[:\s]*([\d,]+\.\d{2})', caseSensitive: false),
    RegExp(r'([\d,]+\.\d{2})\s*(?:DR|CR|Debit|Credit)', caseSensitive: false),
    RegExp(r'(?:sent|received|paid|withdrawn)\s+(?:NGN\s*|₦\s*)?([\d,]+\.?\d*)', caseSensitive: false),
    RegExp(r'(?:NGN\s*|₦\s*)([\d,]+\.\d{2})', caseSensitive: false),
  ];

  static final RegExp _creditPattern = RegExp(
    r'\b(credit|cr|deposit|received|inflow|credited)\b',
    caseSensitive: false,
  );

  static final RegExp _debitPattern = RegExp(
    r'\b(debit|dr|withdrawn|paid|sent|outflow|debited|charged)\b',
    caseSensitive: false,
  );

  // Patterns for Merchant
  static final List<RegExp> _merchantPatterns = [
    RegExp(r'(?:to|from|beneficiary|remitter|merchant)[:\s]*([A-Za-z0-9\s&\-\.]+?)(?:\s*(?:on|at|for|via|date|bal|balance)|[\|]|$)', caseSensitive: false),
    RegExp(r'(?:desc|description)[:\s]*([A-Za-z0-9\s&\-\.]+?)(?:\s*(?:on|at|for|via|date|bal|balance)|[\|]|$)', caseSensitive: false),
    RegExp(r'at\s+([A-Za-z0-9\s&\-\.]+?)(?:\s+(?:on|at|for|via)|$)', caseSensitive: false),
  ];

  // Patterns for Timestamp
  static final List<RegExp> _timestampPatterns = [
    RegExp(r'(?:Date|On)[:\s]*(\d{1,2}[\/\-\.][A-Za-z0-9]+[\/\-\.]\d{2,4})', caseSensitive: false),
    RegExp(r'(?:Date|On)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
    RegExp(r'(\d{1,2}[\/\-\.][A-Za-z0-9]+[\/\-\.]\d{2,4})', caseSensitive: false),
    RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
  ];

  // Patterns for Balance
  static final List<RegExp> _balancePatterns = [
    RegExp(r'(?:balance|bal|available|new balance)[:\s]*(?:is\s*)?(?:NGN\s*|₦\s*)?([\d,]+\.\d{2})', caseSensitive: false),
    RegExp(r'bal[:\s]*([\d,]+\.\d{2})', caseSensitive: false),
  ];

  /// Parse transaction notification text and return structured result with confidence score
  ParsedTransactionResult parseNotification(String rawText) {
    try {
      final amountMinor = _extractAmount(rawText);
      final transactionType = _extractTransactionType(rawText);
      final merchantString = _extractMerchant(rawText);
      final timestamp = _extractTimestamp(rawText);
      final balanceMinor = _extractBalance(rawText);

      final confidenceScore = _calculateConfidenceScore(
        amountMinor: amountMinor,
        transactionType: transactionType,
        merchantString: merchantString,
        timestamp: timestamp,
        balanceMinor: balanceMinor,
      );

      final requiresReview = confidenceScore < _confidenceThreshold;

      return ParsedTransactionResult(
        amountMinor: amountMinor,
        transactionType: transactionType,
        merchantString: merchantString,
        timestamp: timestamp,
        balanceMinor: balanceMinor,
        confidenceScore: confidenceScore,
        requiresReview: requiresReview,
        rawText: rawText,
      );
    } catch (e) {
      return ParsedTransactionResult(
        confidenceScore: 0,
        requiresReview: true,
        rawText: rawText,
      );
    }
  }

  /// Extract amount in Kobo (minor units) from NGN text
  int? _extractAmount(String text) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null) {
            return (amount * 100).round();
          }
        }
      }
    }
    return null;
  }

  /// Extract transaction type (credit/debit) from text
  String? _extractTransactionType(String text) {
    final lowerText = text.toLowerCase();
    
    if (_creditPattern.hasMatch(lowerText)) return 'credit';
    if (_debitPattern.hasMatch(lowerText)) return 'debit';

    if (lowerText.contains('sent to') || lowerText.contains('paid for')) return 'debit';
    if (lowerText.contains('received from') || lowerText.contains('credited with')) return 'credit';

    return null;
  }

  /// Extract merchant name from text
  String? _extractMerchant(String text) {
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        var merchant = match.group(1)?.trim();
        if (merchant != null && merchant.isNotEmpty) {
          // Clean up merchant name
          merchant = merchant.replaceAll(RegExp(r'\s+'), ' ');
          merchant = merchant.replaceAll(RegExp(r'[^\w\s&\-\.]'), '');
          if (merchant.length > 50) merchant = merchant.substring(0, 50).trim();
          if (merchant.isNotEmpty) return merchant;
        }
      }
    }
    return null;
  }

  /// Extract timestamp from text
  DateTime? _extractTimestamp(String text) {
    for (final pattern in _timestampPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final dateStr = match.group(1)!;
        final date = _parseDateTime(dateStr);
        if (date != null) return date;
      }
    }
    return null;
  }

  /// Extract balance in Kobo from text
  int? _extractBalance(String text) {
    for (final pattern in _balancePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final balanceStr = match.group(1)?.replaceAll(',', '');
        if (balanceStr != null) {
          final balance = double.tryParse(balanceStr);
          if (balance != null) {
            return (balance * 100).round();
          }
        }
      }
    }
    return null;
  }

  /// Calculate confidence score based on extracted fields
  int _calculateConfidenceScore({
    int? amountMinor,
    String? transactionType,
    String? merchantString,
    DateTime? timestamp,
    int? balanceMinor,
  }) {
    int score = 0;

    if (amountMinor != null && amountMinor > 0) {
      score += _amountWeight;
    }

    if (transactionType != null) {
      score += _typeWeight;
    }

    if (merchantString != null && merchantString.isNotEmpty) {
      score += _merchantWeight;
    }

    if (timestamp != null) {
      score += _timestampWeight;
    }

    if (balanceMinor != null && balanceMinor >= 0) {
      score += _balanceWeight;
    }

    return score;
  }

  /// Parse various date formats commonly found in notifications
  DateTime? _parseDateTime(String dateStr) {
    // Try different date formats
    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'MM/dd/yyyy',
      'MM-dd-yyyy',
      'yyyy/MM/dd',
      'yyyy-MM-dd',
      'dd/MM/yy',
      'dd-MM-yy',
      'MM/dd/yy',
      'MM-dd-yy',
      'yy/MM/dd',
      'yy-MM-dd',
    ];

    for (final format in formats) {
      try {
        // Simple date parsing - in a real implementation,
        // you'd use intl package for proper parsing
        final parts = dateStr.split(RegExp(r'[\/\-\.]'));
        if (parts.length == 3) {
          int day, month, year;

          if (format.startsWith('dd')) {
            day = int.parse(parts[0]);
            month = int.parse(parts[1]);
            year = int.parse(parts[2]);
          } else if (format.startsWith('MM')) {
            month = int.parse(parts[0]);
            day = int.parse(parts[1]);
            year = int.parse(parts[2]);
          } else {
            // yyyy
            year = int.parse(parts[0]);
            month = int.parse(parts[1]);
            day = int.parse(parts[2]);
          }

          // Handle 2-digit years
          if (year < 100) {
            year += 2000;
          }

          return DateTime(year, month, day);
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }
}
