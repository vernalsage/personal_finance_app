import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for handling currency conversion rates
class CurrencyConversionService {
  // Switched to open.er-api.com which is free, requires no API key, and supports NGN
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  /// Cache for exchange rates to minimize API calls
  static Map<String, double>? _cachedRates;
  static DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(hours: 1);
  static String? _cachedBaseCurrency;

  /// Offline fallback rates relative to NGN
  static const Map<String, double> _offlineRatesToNgn = {
    'USD': 1600.0,
    'EUR': 1750.0,
    'GBP': 2000.0,
    'NGN': 1.0,
  };

  /// Calculate offline cross-rate between two currencies
  static double _getOfflineRate(String fromCurrency, String toCurrency) {
    final fromRate = _offlineRatesToNgn[fromCurrency] ?? 1.0;
    final toRate = _offlineRatesToNgn[toCurrency] ?? 1.0;
    return fromRate / toRate;
  }

  /// Get exchange rates from base currency
  static Future<Map<String, double>> _getExchangeRates(
    String baseCurrency,
  ) async {
    // Check cache first (ensure base currency matches the cached one)
    if (_cachedRates != null &&
        _lastFetch != null &&
        _cachedBaseCurrency == baseCurrency &&
        DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
      return _cachedRates!;
    }

    try {
      // open.er-api.com puts the base currency in the URL path
      final response = await http.get(Uri.parse('$_baseUrl/$baseCurrency'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null) {
          final rates = Map<String, double>.from(
            (data['rates'] as Map).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ),
          );

          // Cache the rates
          _cachedRates = rates;
          _lastFetch = DateTime.now();
          _cachedBaseCurrency = baseCurrency;

          return rates;
        }
      }

      throw Exception(
        'Failed to fetch exchange rates: Status ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Failed to fetch exchange rates: $e');
    }
  }

  /// Convert amount from one currency to another
  static Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    try {
      final rates = await _getExchangeRates(fromCurrency);
      final rate = rates[toCurrency];

      if (rate == null) {
        throw Exception('Exchange rate not available for $toCurrency');
      }

      return amount * rate;
    } catch (e) {
      debugPrint('API failed, using offline fallback. Error: $e');
      final fallbackRate = _getOfflineRate(fromCurrency, toCurrency);
      return amount * fallbackRate;
    }
  }

  /// Get exchange rate between two currencies
  static Future<double> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) {
      return 1.0;
    }

    try {
      final rates = await _getExchangeRates(fromCurrency);
      final rate = rates[toCurrency];

      if (rate == null) {
        throw Exception('Exchange rate not available for $toCurrency');
      }

      return rate;
    } catch (e) {
      debugPrint('API failed, using offline fallback. Error: $e');
      final fallbackRate = _getOfflineRate(fromCurrency, toCurrency);
      return fallbackRate;
    }
  }

  /// Convert multiple amounts to a target currency
  static Future<Map<String, double>> convertMultipleToTarget({
    required Map<String, double> amountsByCurrency,
    required String targetCurrency,
  }) async {
    final result = <String, double>{};

    for (final entry in amountsByCurrency.entries) {
      try {
        final convertedAmount = await convertCurrency(
          amount: entry.value,
          fromCurrency: entry.key,
          toCurrency: targetCurrency,
        );
        result[entry.key] = convertedAmount;
      } catch (e) {
        // If conversion fails, record 0.0 to avoid polluting totals with 1:1 sums
        result[entry.key] = 0.0;
      }
    }

    return result;
  }

  /// Clear cached rates (useful for testing or force refresh)
  static void clearCache() {
    _cachedRates = null;
    _lastFetch = null;
    _cachedBaseCurrency = null;
  }

  /// Check if service is available (basic connectivity test)
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/USD'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
