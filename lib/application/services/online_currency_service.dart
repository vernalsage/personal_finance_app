import 'package:flutter/foundation.dart';
import 'package:currency_converter/currency.dart';
import 'package:currency_converter/currency_converter.dart';

/// Online-only currency service using currency_converter package
/// No fallbacks - will throw errors if API fails
class OnlineCurrencyService {
  /// Convert currency using currency_converter package (online only)
  static Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    try {
      // Convert string currency codes to Currency enum
      final from = _stringToCurrency(fromCurrency);
      final to = _stringToCurrency(toCurrency);

      if (from == null || to == null) {
        throw Exception('Unsupported currency: $fromCurrency or $toCurrency');
      }

      debugPrint(
        'Converting $amount $fromCurrency to $toCurrency using currency_converter package',
      );

      // Use currency_converter package
      final result = await CurrencyConverter.convert(
        from: from,
        to: to,
        amount: amount,
      );

      if (result == null) {
        throw Exception('Currency conversion returned null');
      }

      debugPrint('Conversion result: $result');
      return result;
    } catch (e) {
      debugPrint('Currency conversion failed: $e');
      // Re-throw to ensure we know when API fails
      throw Exception('Currency conversion failed: $e');
    }
  }

  /// Convert currency code string to Currency enum
  static Currency? _stringToCurrency(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return Currency.usd;
      case 'EUR':
        return Currency.eur;
      case 'GBP':
        return Currency.gbp;
      case 'JPY':
        return Currency.jpy;
      case 'NGN':
        return Currency.ngn;
      case 'INR':
        return Currency.inr;
      case 'AUD':
        return Currency.aud;
      case 'CAD':
        return Currency.cad;
      case 'CHF':
        return Currency.chf;
      case 'CNY':
        return Currency.cny;
      case 'SEK':
        return Currency.sek;
      case 'NOK':
        return Currency.nok;
      case 'DKK':
        return Currency.dkk;
      case 'PLN':
        return Currency.pln;
      case 'CZK':
        return Currency.czk;
      case 'HUF':
        return Currency.huf;
      case 'RON':
        return Currency.ron;
      case 'BGN':
        return Currency.bgn;
      case 'HRK':
        return Currency.hrk;
      case 'RUB':
        return Currency.rub;
      // Skip TRY for now due to keyword conflict
      case 'ILS':
        return Currency.ils;
      case 'AED':
        return Currency.aed;
      case 'SAR':
        return Currency.sar;
      case 'KWD':
        return Currency.kwd;
      case 'QAR':
        return Currency.qar;
      case 'BHD':
        return Currency.bhd;
      case 'OMR':
        return Currency.omr;
      case 'JOD':
        return Currency.jod;
      case 'LBP':
        return Currency.lbp;
      case 'EGP':
        return Currency.egp;
      case 'MAD':
        return Currency.mad;
      case 'TND':
        return Currency.tnd;
      case 'DZD':
        return Currency.dzd;
      case 'LYD':
        return Currency.lyd;
      case 'GHS':
        return Currency.ghs;
      case 'XAF':
        return Currency.xaf;
      case 'XOF':
        return Currency.xof;
      case 'XPF':
        return Currency.xpf;
      case 'NZD':
        return Currency.nzd;
      case 'ZAR':
        return Currency.zar;
      case 'KES':
        return Currency.kes;
      case 'UGX':
        return Currency.ugx;
      case 'TZS':
        return Currency.tzs;
      case 'MZN':
        return Currency.mzn;
      case 'AOA':
        return Currency.aoa;
      case 'ZMW':
        return Currency.zmw;
      case 'BWP':
        return Currency.bwp;
      case 'SZL':
        return Currency.szl;
      case 'LSL':
        return Currency.lsl;
      case 'NAD':
        return Currency.nad;
      case 'MWK':
        return Currency.mwk;
      default:
        return null;
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

    // Convert 1 unit to get the rate
    final result = await convertCurrency(
      amount: 1.0,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );

    return result;
  }

  /// Check if currency is supported
  static bool isCurrencySupported(String currencyCode) {
    return _stringToCurrency(currencyCode) != null;
  }

  /// Get list of supported currencies
  static List<String> getSupportedCurrencies() {
    return [
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'NGN',
      'INR',
      'AUD',
      'CAD',
      'CHF',
      'CNY',
      'SEK',
      'NOK',
      'DKK',
      'PLN',
      'CZK',
      'HUF',
      'RON',
      'BGN',
      'HRK',
      'RUB',
      'ILS',
      'AED',
      'SAR',
      'KWD',
      'QAR',
      'BHD',
      'OMR',
      'JOD',
      'LBP',
      'EGP',
      'MAD',
      'TND',
      'DZD',
      'LYD',
      'GHS',
      'XAF',
      'XOF',
      'XPF',
      'NZD',
      'ZAR',
      'KES',
      'UGX',
      'TZS',
      'MZN',
      'AOA',
      'ZMW',
      'BWP',
      'SZL',
      'LSL',
      'NAD',
      'MWK',
    ];
  }
}
