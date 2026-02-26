import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityState {
  const SecurityState({
    this.isLocked = false,
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = false,
    this.isAuthenticating = false,
  });

  final bool isLocked;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final bool isAuthenticating;

  SecurityState copyWith({
    bool? isLocked,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    bool? isAuthenticating,
  }) {
    return SecurityState(
      isLocked: isLocked ?? this.isLocked,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier(this._biometricService) : super(const SecurityState()) {
    _init();
  }

  final BiometricService _biometricService;
  static const _biometricKey = 'security_biometric_enabled';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_biometricKey) ?? false;
    final isAvailable = await _biometricService.canAuthenticate();

    state = state.copyWith(
      isBiometricEnabled: isEnabled,
      isBiometricAvailable: isAvailable,
      // If biometric is enabled, we start locked
      isLocked: isEnabled,
    );
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  Future<bool> authenticate() async {
    if (!state.isBiometricEnabled) {
      state = state.copyWith(isLocked: false);
      return true;
    }

    state = state.copyWith(isAuthenticating: true);
    
    final success = await _biometricService.authenticate();
    
    if (success) {
      state = state.copyWith(
        isLocked: false,
        isAuthenticating: false,
      );
    } else {
      state = state.copyWith(isAuthenticating: false);
    }
    
    return success;
  }

  void lock() {
    if (state.isBiometricEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  void unlock() {
    state = state.copyWith(isLocked: false);
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  return SecurityNotifier(ref.watch(biometricServiceProvider));
});
