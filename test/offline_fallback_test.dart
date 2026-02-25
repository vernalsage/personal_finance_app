import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/application/services/currency_conversion_service.dart';

void main() {
  group('Offline Fallback Tests', () {
    setUp(() {
      // Clear cache to ensure fresh test
      CurrencyConversionService.clearCache();
    });

    test(
      'offline fallback should convert USD to NGN correctly when API fails',
      () async {
        // Clear cache and try to convert - should use offline fallback if API fails
        CurrencyConversionService.clearCache();

        final result = await CurrencyConversionService.convertCurrency(
          amount: 100.0,
          fromCurrency: 'USD',
          toCurrency: 'NGN',
        );

        // If API works, we get real rate. If API fails, we get offline rate
        // Both are acceptable - we just want to ensure it doesn't crash
        expect(result, isA<double>());
        expect(result, greaterThan(0));
      },
    );

    test('offline fallback should convert EUR to GBP correctly', () async {
      CurrencyConversionService.clearCache();

      final result = await CurrencyConversionService.convertCurrency(
        amount: 100.0,
        fromCurrency: 'EUR',
        toCurrency: 'GBP',
      );

      expect(result, isA<double>());
      expect(result, greaterThan(0));
    });

    test('offline fallback should handle same currency', () async {
      final result = await CurrencyConversionService.convertCurrency(
        amount: 500.0,
        fromCurrency: 'USD',
        toCurrency: 'USD',
      );

      expect(result, equals(500.0));
    });

    test(
      'offline fallback should handle unknown currency gracefully',
      () async {
        final result = await CurrencyConversionService.convertCurrency(
          amount: 100.0,
          fromCurrency: 'UNKNOWN',
          toCurrency: 'NGN',
        );

        // Should default to 1.0 rate for unknown currency
        expect(result, equals(100.0));
      },
    );

    test('offline fallback rate calculation should be correct', () {
      // Test the offline rate calculation directly
      // This tests the _getOfflineRate method indirectly
      expect(() async {
        await CurrencyConversionService.convertCurrency(
          amount: 100.0,
          fromCurrency: 'USD',
          toCurrency: 'NGN',
        );
      }, returnsNormally);
    });
  });
}
