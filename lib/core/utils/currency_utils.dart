/// Utility functions for currency handling following by Monetary Handling rule
class CurrencyUtils {
  CurrencyUtils._();

  /// Get currency symbol for a given currency code
  static String getCurrencySymbol(String? currency) {
    switch (currency?.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'NGN':
        return '₦';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency?.toUpperCase() ?? '';
    }
  }

  /// Convert user input string to minor units (kobo)
  /// Takes "5000.50" and returns 500050
  static int formatAmountToMinor(String input) {
    if (input.isEmpty) return 0;

    try {
      // Remove any non-numeric characters except decimal point
      final cleanInput = input.replaceAll(RegExp(r'[^\d.]'), '');

      // Parse as double
      final amount = double.tryParse(cleanInput);
      if (amount == null) return 0;

      // Convert to minor units (multiply by 100)
      final minorAmount = (amount * 100).round();

      return minorAmount;
    } catch (e) {
      return 0;
    }
  }

  /// Convert minor units to display string with proper currency symbol
  /// Takes 500050 and currency 'USD' and returns "$5,000.50"
  static String formatMinorToDisplay(int minorAmount, [String? currency]) {
    if (minorAmount == 0) return '${getCurrencySymbol(currency)}0.00';

    // Convert to major units
    final majorAmount = minorAmount / 100;

    // Format with proper decimal places and currency symbol
    final formattedAmount = majorAmount.toStringAsFixed(2);

    // Add thousand separators
    final parts = formattedAmount.split('.');
    final integerPart = _formatWithThousandsSeparator(parts[0]);
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    return '${getCurrencySymbol(currency)}$integerPart.$decimalPart';
  }

  /// Format integer with thousands separator
  static String _formatWithThousandsSeparator(String value) {
    if (value.length <= 3) return value;

    final buffer = StringBuffer();
    int count = 0;

    // Process from right to left
    for (int i = value.length - 1; i >= 0; i--) {
      buffer.write(value[i]);
      count++;

      // Add comma after every 3 digits from right
      if (count == 3 && i != 0) {
        buffer.write(',');
        count = 0;
      }
    }

    return buffer.toString().split('').reversed.join('');
  }

  /// Validate amount string
  static bool isValidAmount(String input) {
    if (input.isEmpty) return false;

    try {
      final cleanInput = input.replaceAll(RegExp(r'[^\d.]'), '');
      final amount = double.tryParse(cleanInput);

      if (amount == null) return false;
      if (amount <= 0) return false;

      // Check for at most 2 decimal places
      final parts = cleanInput.split('.');
      if (parts.length > 2) return false;
      if (parts.length == 2 && parts[1].length > 2) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Format amount for input field (allows decimal input)
  static String formatForInput(int minorAmount) {
    if (minorAmount == 0) return '0.00';

    final majorAmount = minorAmount / 100;
    return majorAmount.toStringAsFixed(2);
  }
}
