import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Utility class for battery optimization exemption
class BatteryUtils {
  static const MethodChannel _channel = MethodChannel(
    'com.personal_finance_app/battery',
  );

  /// Check if the app is exempt from battery optimizations
  static Future<bool> isBatteryOptimizationExempt() async {
    if (!Platform.isAndroid) {
      return true; // iOS doesn't have battery optimization exemptions
    }

    try {
      final bool isExempt = await _channel.invokeMethod(
        'isBatteryOptimizationExempt',
      );
      return isExempt;
    } catch (e) {
      debugPrint('Error checking battery optimization status: $e');
      return false;
    }
  }

  /// Request battery optimization exemption
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) {
      return true; // iOS doesn't have battery optimization exemptions
    }

    try {
      // First check if we already have permission
      final isExempt = await isBatteryOptimizationExempt();
      if (isExempt) {
        debugPrint('App is already exempt from battery optimizations');
        return true;
      }

      // Request the exemption via platform channel
      final bool granted = await _channel.invokeMethod(
        'requestBatteryOptimizationExemption',
      );

      if (granted) {
        debugPrint('Battery optimization exemption granted');
        return true;
      } else {
        debugPrint('Battery optimization exemption denied');
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  /// Check if background execution is restricted
  static Future<bool> isBackgroundExecutionRestricted() async {
    if (!Platform.isAndroid) {
      return false; // iOS handles background execution differently
    }

    try {
      // Check battery optimization status as an indicator
      final isExempt = await isBatteryOptimizationExempt();
      return !isExempt;
    } catch (e) {
      debugPrint('Error checking background execution restriction: $e');
      return true; // Assume restricted if we can't check
    }
  }

  /// Open battery optimization settings for the app
  static Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod('openBatterySettings');
    } catch (e) {
      debugPrint('Error opening battery settings: $e');
    }
  }

  /// Request all necessary permissions for background execution
  static Future<Map<String, bool>> requestBackgroundPermissions() async {
    final results = <String, bool>{};

    try {
      // Request battery optimization exemption
      results['batteryOptimization'] =
          await requestBatteryOptimizationExemption();

      // For now, assume notification permission is handled separately
      results['notification'] = true;

      debugPrint('Background permission results: $results');
      return results;
    } catch (e) {
      debugPrint('Error requesting background permissions: $e');
      return {'batteryOptimization': false, 'notification': false};
    }
  }

  /// Get user-friendly message for battery optimization status
  static String getBatteryOptimizationMessage(bool isExempt) {
    if (isExempt) {
      return 'Background execution is enabled. The app will work reliably in the background.';
    } else {
      return 'Background execution may be restricted. Please enable battery optimization exemption for reliable performance.';
    }
  }
}
