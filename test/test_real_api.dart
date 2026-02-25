import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/application/services/smart_currency_service.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Clear cache to force API call
  SmartCurrencyService.clearMemoryCache();

  // Test currency conversion
  await SmartCurrencyService.convertCurrency(
    amount: 10.0,
    fromCurrency: 'USD',
    toCurrency: 'NGN',
  );

  await SmartCurrencyService.convertCurrency(
    amount: 10.0,
    fromCurrency: 'GBP',
    toCurrency: 'NGN',
  );

  // Check cache info
  await SmartCurrencyService.getCacheInfo();
}
