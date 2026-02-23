import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'presentation/router/app_router.dart';
import 'platform/background/work_manager_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager for background execution
  await _initializeWorkManager();

  runApp(const ProviderScope(child: PersonalFinanceApp()));
}

/// Initialize WorkManager and register periodic tasks
Future<void> _initializeWorkManager() async {
  try {
    // Initialize WorkManager with the callback dispatcher
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Register periodic task for recurring transaction checks
    await Workmanager().registerPeriodicTask(
      'recurring_transaction_check',
      'recurring_transaction_check',
      frequency: const Duration(hours: 24), // Run once every 24 hours
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresCharging: false, // Allow running while not charging
        requiresDeviceIdle: false, // Allow running when device is active
        requiresBatteryNotLow: true, // Only run when battery is not low
        requiresStorageNotLow: true, // Only run when storage is not low
      ),
    );

    debugPrint(
      'WorkManager initialized and recurring transaction task registered',
    );
  } catch (e) {
    debugPrint('Failed to initialize WorkManager: $e');
  }
}

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}
