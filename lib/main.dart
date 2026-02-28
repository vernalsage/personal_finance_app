import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/security_providers.dart';
import 'presentation/screens/security/lock_screen.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'data/database/app_database_simple.dart';

import 'core/style/app_theme.dart';
import 'presentation/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database default data (Profile, Categories, etc.)
  await AppDatabase().initializeDefaultData();

  // Override sqlite3 to use SQLCipher on Android
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: PersonalFinanceApp()));
}

class PersonalFinanceApp extends ConsumerWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Personal Finance',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const SecurityWrapper(child: MainScaffold()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SecurityWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const SecurityWrapper({super.key, required this.child});

  @override
  ConsumerState<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends ConsumerState<SecurityWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(securityProvider.notifier).lock();
    } else if (state == AppLifecycleState.resumed) {
      // Automatically trigger biometric prompt on resume
      final security = ref.read(securityProvider);
      if (security.isLocked && security.isBiometricEnabled) {
        ref.read(securityProvider.notifier).authenticate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);

    if (securityState.isLocked) {
      return const LockScreen();
    }

    return widget.child;
  }
}

