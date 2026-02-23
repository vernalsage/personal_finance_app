import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/errors/exceptions.dart';

/// Service for authentication and security
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Initialize authentication service
  Future<void> initialize() async {
    // Check if device supports biometric authentication
    final isSupported = await _localAuth.isDeviceSupported();
    if (!isSupported) {
      throw SecurityException(
        'Device does not support biometric authentication',
        'DEVICE_NOT_SUPPORTED',
      );
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _localAuth.canCheckBiometrics;
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access the app',
  }) async {
    try {
      return await _localAuth.authenticate(localizedReason: reason);
    } catch (e) {
      throw SecurityException(
        'Biometric authentication failed: $e',
        'BIOMETRIC_AUTH_FAILED',
      );
    }
  }

  /// Store authentication token securely
  Future<void> storeAuthToken(String token) async {
    try {
      await _secureStorage.write(
        key: 'auth_token',
        value: token,
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw SecurityException(
        'Failed to store auth token: $e',
        'STORAGE_ERROR',
      );
    }
  }

  /// Retrieve authentication token
  Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(
        key: 'auth_token',
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw SecurityException(
        'Failed to retrieve auth token: $e',
        'STORAGE_ERROR',
      );
    }
  }

  /// Delete authentication token
  Future<void> deleteAuthToken() async {
    try {
      await _secureStorage.delete(
        key: 'auth_token',
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw SecurityException(
        'Failed to delete auth token: $e',
        'STORAGE_ERROR',
      );
    }
  }

  /// Store encryption key securely
  Future<void> storeEncryptionKey(String key) async {
    try {
      await _secureStorage.write(
        key: 'encryption_key',
        value: key,
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw SecurityException(
        'Failed to store encryption key: $e',
        'STORAGE_ERROR',
      );
    }
  }

  /// Retrieve encryption key
  Future<String?> getEncryptionKey() async {
    try {
      return await _secureStorage.read(
        key: 'encryption_key',
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw SecurityException(
        'Failed to retrieve encryption key: $e',
        'STORAGE_ERROR',
      );
    }
  }

  /// Store user preferences securely
  Future<void> storeUserPreference(String key, String value) async {
    try {
      await _secureStorage.write(
        key: 'pref_$key',
        value: value,
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw SecurityException(
        'Failed to store user preference: $e',
        'STORAGE_ERROR',
      );
    }
  }

  /// Retrieve user preference
  Future<String?> getUserPreference(String key) async {
    try {
      return await _secureStorage.read(
        key: 'pref_$key',
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      throw SecurityException(
        'Failed to retrieve user preference: $e',
        'STORAGE_ERROR',
      );
    }
  }

  /// Clear all stored data
  Future<void> clearAllData() async {
    try {
      await _secureStorage.deleteAll(aOptions: _getAndroidOptions());
    } catch (e) {
      throw SecurityException('Failed to clear all data: $e', 'STORAGE_ERROR');
    }
  }

  /// Check if app is locked
  Future<bool> isAppLocked() async {
    try {
      final lastActiveTime = await _secureStorage.read(
        key: 'last_active_time',
        aOptions: _getAndroidOptions(),
      );

      if (lastActiveTime == null) return true;

      final lastActive = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastActiveTime),
      );
      final now = DateTime.now();

      // Check if 60 seconds have passed
      return now.difference(lastActive).inSeconds >= 60;
    } catch (e) {
      return true; // Assume locked if we can't check
    }
  }

  /// Update last active time
  Future<void> updateLastActiveTime() async {
    try {
      await _secureStorage.write(
        key: 'last_active_time',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      // Don't throw error for this, it's not critical
    }
  }

  /// Lock the app
  Future<void> lockApp() async {
    try {
      await _secureStorage.delete(
        key: 'last_active_time',
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      // Don't throw error for this, it's not critical
    }
  }

  /// Get Android options for secure storage
  AndroidOptions _getAndroidOptions() {
    return const AndroidOptions(encryptedSharedPreferences: true);
  }
}
