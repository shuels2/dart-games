import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dartboard_provider.dart';
import '../providers/player_provider.dart';

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
    final dartboardProvider = context.read<DartboardProvider>();
    final playerProvider = context.read<PlayerProvider>();

    // Small delay for splash effect
    await Future.delayed(const Duration(seconds: 1));

    // Load dartboard config and player data in parallel — both must complete
    // before navigation so game menus never open with an empty player list.
    await Future.wait([
      dartboardProvider.loadConfiguration(),
      playerProvider.loadPlayers(),
    ]);

    if (!mounted) return;

    // If no dartboard configured, go to setup screen
    if (!dartboardProvider.isRegistered) {
      Navigator.of(context).pushReplacementNamed('/dartboard-setup');
      return;
    }

    // If dartboard is configured, go to home
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF44336), // Red
              Color(0xFFFFC107), // Amber
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/common/images/logo.png',
                width: 400,
                height: 400,
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
