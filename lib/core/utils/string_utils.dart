/// Utility functions for string operations
class StringUtils {
  /// Normalize a string for comparison/comparison
  /// Converts to lowercase, trims whitespace, and removes special characters
  static String normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
  
  /// Generate a normalized version for merchant lookup
  static String normalizeMerchantName(String name) {
    return normalize(name);
  }
  
  /// Check if two strings are considered equal after normalization
  static bool normalizedEquals(String a, String b) {
    return normalize(a) == normalize(b);
  }
}
