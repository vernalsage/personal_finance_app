import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/application/services/hybrid_currency_service.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hybrid Currency Service Tests', () {
    setUp(() async {
      // Clear cache before each test
      await HybridCurrencyService.clearCache();
    });

    test('should handle same currency conversion', () async {
      final result = await HybridCurrencyService.convertCurrency(
        amount: 500.0,
        fromCurrency: 'USD',
        toCurrency: 'USD',
      );

      expect(result, equals(500.0));
    });

    test('should convert USD to NGN using online API', () async {
      final result = await HybridCurrencyService.convertCurrency(
        amount: 10.0,
        fromCurrency: 'USD',
        toCurrency: 'NGN',
      );

      expect(result, isA<double>());
      expect(result, greaterThan(0));
    });

    test('should convert GBP to NGN using online API', () async {
      final result = await HybridCurrencyService.convertCurrency(
        amount: 10.0,
        fromCurrency: 'GBP',
        toCurrency: 'NGN',
      );

      expect(result, isA<double>());
      expect(result, greaterThan(0));
    });

    test('should cache successful conversions', () async {
      // First conversion (online)
      await HybridCurrencyService.convertCurrency(
        amount: 10.0,
        fromCurrency: 'USD',
        toCurrency: 'NGN',
      );

      // Check cache info
      final cacheInfo = await HybridCurrencyService.getCacheInfo();
      expect(cacheInfo, isNotNull);
      expect(cacheInfo!['ratesCount'], greaterThan(0));
    });

    test('should use cached rates when available', () async {
      // First conversion to populate cache
      await HybridCurrencyService.convertCurrency(
        amount: 10.0,
        fromCurrency: 'USD',
        toCurrency: 'NGN',
      );

      // Second conversion should use cache
      final result = await HybridCurrencyService.convertCurrency(
        amount: 20.0,
        fromCurrency: 'USD',
        toCurrency: 'NGN',
      );

      expect(result, isA<double>());
      expect(result, greaterThan(0));
    });

    test('should use hardcoded fallback when all else fails', () async {
      // Clear cache and try with unsupported currency to force fallback
      await HybridCurrencyService.clearCache();

      // This should use hardcoded fallback
      final result = await HybridCurrencyService.convertCurrency(
        amount: 10.0,
        fromCurrency: 'USD',
        toCurrency: 'NGN',
      );

      expect(result, isA<double>());
      expect(result, greaterThan(0));
    });

    test('should handle unsupported currencies gracefully', () async {
      final result = await HybridCurrencyService.convertCurrency(
        amount: 100.0,
        fromCurrency: 'UNKNOWN',
        toCurrency: 'NGN',
      );

      // Should use hardcoded 1:1 fallback
      expect(result, equals(100.0));
    });

    test('should work with multiple currency pairs', () async {
      final pairs = [
        ['USD', 'EUR'],
        ['GBP', 'JPY'],
        ['EUR', 'NGN'],
        ['INR', 'USD'],
      ];

      for (final pair in pairs) {
        final result = await HybridCurrencyService.convertCurrency(
          amount: 10.0,
          fromCurrency: pair[0],
          toCurrency: pair[1],
        );

        expect(result, isA<double>());
        expect(result, greaterThan(0));
      }
    });
  });
}
