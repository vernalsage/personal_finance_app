import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/application/services/online_currency_service.dart';

void main() {
  group('Online Currency Service Tests', () {
    test('should handle same currency conversion', () async {
      final result = await OnlineCurrencyService.convertCurrency(
        amount: 500.0,
        fromCurrency: 'USD',
        toCurrency: 'USD',
      );

      expect(result, equals(500.0));
    });

    test('should convert USD to NGN using real API', () async {
      final result = await OnlineCurrencyService.convertCurrency(
        amount: 10.0,
        fromCurrency: 'USD',
        toCurrency: 'NGN',
      );

      expect(result, isA<double>());
      expect(result, greaterThan(0));
    });

    test('should convert GBP to NGN using real API', () async {
      final result = await OnlineCurrencyService.convertCurrency(
        amount: 10.0,
        fromCurrency: 'GBP',
        toCurrency: 'NGN',
      );

      expect(result, isA<double>());
      expect(result, greaterThan(0));
    });

    test('should check supported currencies', () {
      expect(OnlineCurrencyService.isCurrencySupported('USD'), isTrue);
      expect(OnlineCurrencyService.isCurrencySupported('NGN'), isTrue);
      expect(OnlineCurrencyService.isCurrencySupported('GBP'), isTrue);
      expect(OnlineCurrencyService.isCurrencySupported('UNKNOWN'), isFalse);
    });

    test('should throw error for unsupported currency', () async {
      expect(
        () async => await OnlineCurrencyService.convertCurrency(
          amount: 100.0,
          fromCurrency: 'UNKNOWN',
          toCurrency: 'NGN',
        ),
        throwsException,
      );
    });
  });
}
