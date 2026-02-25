import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Smart currency service with persistent caching and graceful degradation
class SmartCurrencyService {
  static const String _baseUrl = 'https://api.exchangerate.host/latest';
  static const String _cacheKey = 'cached_exchange_rates';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const Duration _cacheExpiry = Duration(
    hours: 24,
  ); // Cache for 24 hours

  // In-memory cache for app session
  static Map<String, double>? _memoryCache;
  static DateTime? _memoryCacheTimestamp;

  /// Get cached rates from memory or SharedPreferences
  static Future<Map<String, double>?> _getCachedRates() async {
    // Try memory cache first (faster)
    if (_memoryCache != null &&
        _memoryCacheTimestamp != null &&
        DateTime.now().difference(_memoryCacheTimestamp!) < _cacheExpiry) {
      debugPrint('Using memory cache');
      return _memoryCache;
    }

    // Try SharedPreferences if memory cache is empty/expired
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (ratesJson != null && timestamp != null) {
        final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp),
        );
        if (cacheAge < _cacheExpiry) {
          final rates = Map<String, double>.from(
            json
                .decode(ratesJson)
                .map((key, value) => MapEntry(key, (value as num).toDouble())),
          );

          // Update memory cache
          _memoryCache = rates;
          _memoryCacheTimestamp = DateTime.now();

          debugPrint('Using cached rates from ${cacheAge.inHours} hours ago');
          return rates;
        }
      }
    } catch (e) {
      debugPrint('Error reading cached rates: $e');
      // Return null to trigger fresh API call
    }
    return null;
  }

  /// Save rates to both memory and SharedPreferences
  static Future<void> _saveCachedRates(Map<String, double> rates) async {
    // Update memory cache immediately
    _memoryCache = rates;
    _memoryCacheTimestamp = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = json.encode(rates);
      await prefs.setString(_cacheKey, ratesJson);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('Saved ${rates.length} exchange rates to cache');
    } catch (e) {
      debugPrint('Error saving cached rates: $e');
    }
  }

  /// Get fresh exchange rates from API
  static Future<Map<String, double>> _getFreshRates(String baseCurrency) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl?base=$baseCurrency'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null) {
          final rates = Map<String, double>.from(
            (data['rates'] as Map).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ),
          );

          // Cache the fresh rates
          await _saveCachedRates(rates);
          return rates;
        }
      }
      throw Exception('API returned status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error fetching fresh rates: $e');
      throw Exception('Failed to fetch exchange rates: $e');
    }
  }

  /// Get exchange rates with fallback strategy
  static Future<Map<String, double>> getExchangeRates(
    String baseCurrency,
  ) async {
    // Try cached rates first
    final cachedRates = await _getCachedRates();
    if (cachedRates != null) {
      return cachedRates;
    }

    // Try to get fresh rates
    try {
      return await _getFreshRates(baseCurrency);
    } catch (e) {
      // If API fails and we have no cache, return minimal safe fallback
      debugPrint('No cache and API failed, using emergency fallback');
      return _getEmergencyFallback(baseCurrency);
    }
  }

  /// Emergency fallback rates (only when no cache and API fails)
  static Map<String, double> _getEmergencyFallback(String baseCurrency) {
    // Realistic fallback rates based on current market rates
    switch (baseCurrency.toUpperCase()) {
      case 'USD':
        return {
          'EUR': 0.92,
          'GBP': 0.79,
          'NGN': 1600.0, // More realistic rate
          'JPY': 149.0,
        };
      case 'EUR':
        return {'USD': 1.09, 'GBP': 0.86, 'NGN': 1750.0, 'JPY': 162.0};
      case 'GBP':
        return {'USD': 1.27, 'EUR': 1.16, 'NGN': 2000.0, 'JPY': 188.0};
      case 'NGN':
        return {
          'USD': 0.000625, // 1/1600
          'EUR': 0.000571, // 1/1750
          'GBP': 0.0005, // 1/2000
          'JPY': 0.094,
        };
      default:
        return {'USD': 1.0, 'EUR': 1.0, 'GBP': 1.0, 'NGN': 1.0, 'JPY': 1.0};
    }
  }

  /// Convert currency using smart strategy
  static Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    try {
      final rates = await getExchangeRates(fromCurrency);
      final rate = rates[toCurrency];

      if (rate == null) {
        // Try reverse conversion if direct rate not available
        final reverseRates = await getExchangeRates(toCurrency);
        final reverseRate = reverseRates[fromCurrency];

        if (reverseRate != null && reverseRate > 0) {
          return amount / reverseRate;
        }

        throw Exception('Exchange rate not available for $toCurrency');
      }

      return amount * rate;
    } catch (e) {
      debugPrint('Currency conversion failed: $e');
      // Return original amount rather than 0 or crashing
      return amount;
    }
  }

  /// Clear cache (for testing or manual refresh)
  static Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache = null;
    _memoryCacheTimestamp = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      debugPrint('Currency cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Clear only memory cache (for testing)
  static void clearMemoryCache() {
    _memoryCache = null;
    _memoryCacheTimestamp = null;
    debugPrint('Memory cache cleared');
  }

  /// Get cache info for debugging
  static Future<Map<String, dynamic>?> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      final ratesJson = prefs.getString(_cacheKey);

      if (timestamp != null && ratesJson != null) {
        final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp),
        );
        return {
          'timestamp': timestamp,
          'ageHours': cacheAge.inHours,
          'ratesCount': json.decode(ratesJson).length,
        };
      }
    } catch (e) {
      debugPrint('Error getting cache info: $e');
    }
    return null;
  }
}
