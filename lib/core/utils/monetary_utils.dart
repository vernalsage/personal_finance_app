/// Utility functions for monetary calculations using integer minor units
class MonetaryUtils {
  MonetaryUtils._();

  /// Convert major currency units to minor units (e.g., 5000.00 → 500000)
  static int toMinorUnits(double majorUnits) {
    return (majorUnits * 100).round();
  }

  /// Convert minor units to major currency units (e.g., 500000 → 5000.00)
  static double toMajorUnits(int minorUnits) {
    return minorUnits / 100.0;
  }

  /// Format minor units as currency string (e.g., 500000 → "5,000.00")
  static String formatCurrency(int minorUnits, {String symbol = '₦'}) {
    final majorUnits = toMajorUnits(minorUnits);
    final parts = majorUnits.toStringAsFixed(2).split('.');
    final integerPart = _formatIntegerPart(int.parse(parts[0]));
    return '$symbol$integerPart.${parts[1]}';
  }

  /// Format integer part with thousands separators
  static String _formatIntegerPart(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
  }

  /// Add two monetary amounts safely
  static int add(int a, int b) {
    return a + b;
  }

  /// Subtract two monetary amounts safely
  static int subtract(int a, int b) {
    return a - b;
  }

  /// Multiply monetary amount by a factor
  static int multiply(int amount, double factor) {
    return (amount * factor).round();
  }

  /// Calculate percentage of amount
  static int percentage(int amount, double percentage) {
    return (amount * percentage / 100).round();
  }
}
