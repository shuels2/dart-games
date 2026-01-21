import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dartboard_provider.dart';
import '../providers/setup_wizard_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final authProvider = context.read<AuthProvider>();
    final dartboardProvider = context.read<DartboardProvider>();
    final wizardProvider = context.read<SetupWizardProvider>();

    // Small delay for splash effect
    await Future.delayed(const Duration(seconds: 1));

    // Check authentication status
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    // If not authenticated, go to setup wizard
    if (!authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/welcome');
      return;
    }

    // If authenticated, check dartboard status
    await dartboardProvider.checkDartboardStatus(authProvider.bearerToken!);

    if (!mounted) return;

    // If no dartboard registered, go to dartboard registration
    if (!dartboardProvider.isRegistered) {
      // Skip to dartboard registration step
      wizardProvider.goToStep(2);
      Navigator.of(context).pushReplacementNamed('/register-board');
      return;
    }

    // If everything is set up, go to home
    await wizardProvider.completeSetup();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports,
                size: 120,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(height: 24),
              Text(
                'Dart Games',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
