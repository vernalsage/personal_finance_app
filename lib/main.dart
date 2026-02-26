import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/security_providers.dart';
import 'presentation/screens/security/lock_screen.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

// ─── Stitch Design System Tokens ───────────────────────────────────────────
const Color kPrimary = Color(0xFF19AEA7);         // Teal
const Color kPrimaryDark = Color(0xFF0D8A84);     // Teal dark
const Color kPrimaryBg = Color(0xFFE6F7F7);       // Teal 10%
const Color kSurface = Color(0xFFFFFFFF);         // White
const Color kBackground = Color(0xFFF5F7FA);      // Light grey bg
const Color kCardBg = Color(0xFFFFFFFF);          // Card white
const Color kTextPrimary = Color(0xFF0F1C2E);     // Near black
const Color kTextSecondary = Color(0xFF6B7A8D);   // Grey
const Color kBorder = Color(0xFFE2E8F0);          // Light border
const Color kSuccess = Color(0xFF16A34A);         // Green for income
const Color kError = Color(0xFFDC2626);           // Red for expense
const Color kWarning = Color(0xFFF59E0B);         // Amber for review

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance',
      theme: _buildStitchTheme(),
      home: const SecurityWrapper(child: MainScaffold()),
      debugShowCheckedModeBanner: false,
    );
  }

  static ThemeData _buildStitchTheme() {
    const seed = kPrimary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: kPrimary,
      onPrimary: Colors.white,
      secondary: kPrimaryDark,
      surface: kSurface,
      surfaceContainerHighest: kBackground,
      error: kError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: kBackground,
      fontFamily: 'Manrope',
      // Card theme
      cardTheme: CardThemeData(
        color: kCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kBorder, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 8),
      ),
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: kSurface,
        foregroundColor: kTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      // NavigationBar theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kSurface,
        indicatorColor: kPrimaryBg,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: kPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: kTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kPrimary, size: 22);
          }
          return const IconThemeData(color: kTextSecondary, size: 22);
        }),
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: kBorder,
      ),
      // InputDecoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      // TextButton theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kPrimary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: kTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: kTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: kTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: kTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: kTextSecondary,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kTextSecondary,
          letterSpacing: 0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: kBorder,
        thickness: 1,
        space: 0,
      ),
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

