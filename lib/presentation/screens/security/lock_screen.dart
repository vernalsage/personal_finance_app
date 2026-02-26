import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/security_providers.dart';
import '../../../main.dart'; // For theme constants

class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(securityProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimary.withOpacity(0.05),
              kBackground,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kSurface,
                shape: BoxShape.circle,
                border: Border.all(color: kBorder.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_person_outlined,
                size: 64,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'App Locked',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Please authenticate to access your financial records.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kTextSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 48),
            if (securityState.isAuthenticating)
              const CircularProgressIndicator(color: kPrimary)
            else
              ElevatedButton.icon(
                onPressed: () => ref.read(securityProvider.notifier).authenticate(),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock with Biometrics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                // Future: Add fallback to PIN if supported
              },
              child: Text(
                'Use Alternative Method',
                style: TextStyle(color: kPrimary.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
