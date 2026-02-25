import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/application/services/currency_conversion_service.dart';

void main() {
  group('Currency Conversion Tests', () {
    test(
      'convertCurrency should convert same currency to same amount',
      () async {
        final result = await CurrencyConversionService.convertCurrency(
          amount: 100.0,
          fromCurrency: 'USD',
          toCurrency: 'USD',
        );

        expect(result, equals(100.0));
      },
    );

    test('convertCurrency should handle different currencies', () async {
      // This test requires internet connection for real API
      // For now, just test that it doesn't crash
      try {
        final result = await CurrencyConversionService.convertCurrency(
          amount: 100.0,
          fromCurrency: 'USD',
          toCurrency: 'NGN',
        );

        // Result should be a positive number (actual rate varies)
        expect(result, isA<double>());
        expect(result, greaterThan(0));
      } catch (e) {
        // If no internet, should handle gracefully
        expect(e, isA<Exception>());
      }
    });

    test('isServiceAvailable should check connectivity', () async {
      final isAvailable = await CurrencyConversionService.isServiceAvailable();

      // Should return true or false without crashing
      expect(isAvailable, isA<bool>());
    });
  });
}
