import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/application/services/smart_currency_service.dart';

void main() {
  group('Smart Currency Service Tests', () {
    test('should handle same currency conversion', () async {
      final result = await SmartCurrencyService.convertCurrency(
        amount: 500.0,
        fromCurrency: 'USD',
        toCurrency: 'USD',
      );

      expect(result, equals(500.0));
    });

    test('should handle unknown currency gracefully', () async {
      final result = await SmartCurrencyService.convertCurrency(
        amount: 100.0,
        fromCurrency: 'UNKNOWN',
        toCurrency: 'NGN',
      );

      // Should return original amount, not crash
      expect(result, equals(100.0));
    });

    test('emergency fallback should work when API fails', () async {
      // Clear memory cache to force fallback
      SmartCurrencyService.clearMemoryCache();

      final result = await SmartCurrencyService.convertCurrency(
        amount: 100.0,
        fromCurrency: 'USD',
        toCurrency: 'NGN',
      );

      // Should use emergency fallback rate (750 NGN per USD)
      expect(result, equals(75000.0)); // 100 * 750
    });
  });
}
