import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;
  final _logger = Logger('BiometricService');

  /// Check if the device is capable of biometric authentication
  Future<bool> canAuthenticate() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return isSupported && canCheckBiometrics;
    } on PlatformException catch (e) {
      _logger.severe('Error checking biometric support: $e');
      return false;
    }
  }

  /// Get list of available biometrics
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      _logger.severe('Error getting available biometrics: $e');
      return <BiometricType>[];
    }
  }

  /// Authenticate the user
  Future<bool> authenticate({
    String reason = 'Please authenticate to access your financial data',
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      _logger.severe('Error during authentication: $e');
      return false;
    }
  }

  /// Cancel authentication
  Future<void> stopAuthentication() async {
    await _auth.stopAuthentication();
  }
}
