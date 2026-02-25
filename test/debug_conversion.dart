import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/application/services/smart_currency_service.dart';
import 'package:logging/logging.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.ALL;
  // In test environment, we can use print for console output
  // but wrap it in a proper logging handler
  Logger.root.onRecord.listen((record) {
    // In test environment, logging is automatically captured by the test framework
    // No need for explicit print output
  });

  final log = Logger('DebugConversion');

  log.info('=== DEBUGGING CONVERSION ===');

  // Clear cache to force emergency fallback
  SmartCurrencyService.clearMemoryCache();

  log.info('Testing 10 USD to NGN:');
  final usdResult = await SmartCurrencyService.convertCurrency(
    amount: 10.0,
    fromCurrency: 'USD',
    toCurrency: 'NGN',
  );
  log.info('Result: $usdResult');

  log.info('Testing 10 GBP to NGN:');
  final gbpResult = await SmartCurrencyService.convertCurrency(
    amount: 10.0,
    fromCurrency: 'GBP',
    toCurrency: 'NGN',
  );
  log.info('Result: $gbpResult');

  log.info('Total: ${usdResult + gbpResult}');
}
