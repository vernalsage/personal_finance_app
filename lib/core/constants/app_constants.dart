/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Database
  static const String databaseName = 'personal_finance.db';
  static const int databaseVersion = 1;

  // Security
  static const String secureStorageKey = 'secure_storage_key';
  static const int autoLockTimeoutSeconds = 60;

  // Notifications
  static const int notificationConfidenceThreshold = 80;
  static const int duplicatePreventionWindowSeconds = 30;

  // Budgets
  static const double budgetAlertThreshold = 0.8; // 80%

  // Export
  static const String csvDateFormat = 'yyyy-MM-dd';
  static const String csvTimeFormat = 'HH:mm:ss';
}
