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

    // loadConfiguration() returns before _onWebSocketConnected's 5s
    // hardware-status timeout can fire — when HELLO_CLIENT auth succeeds
    // but the dartboard hardware is powered off, status sits in
    // `connecting` for up to 5 more seconds. Poll briefly so the
    // navigation decision below sees the FINAL status, not the
    // mid-resolution one.
    // Listens for the status notification instead of polling every 100ms
    // (WS04 4.8) — resolves on the first frame the answer is known.
    await dartboardProvider.whenStatusResolved();

    if (!mounted) return;

    // No saved config → setup screen (existing behaviour).
    if (!dartboardProvider.isRegistered) {
      Navigator.of(context).pushReplacementNamed('/dartboard-setup');
      return;
    }

    // Saved config exists but auto-reconnect failed (hardware off,
    // wrong serial/API key, network down, etc.) → send the user to the
    // dartboard setup screen so they can register a new one or fix the
    // existing config without being blocked by the paused-modal overlay
    // that home would otherwise show. The saved config is intentionally
    // NOT cleared — if the user just needs to power on their dartboard
    // and retry, the existing config is still in place.
    if (!dartboardProvider.canPlayGames) {
      Navigator.of(context).pushReplacementNamed('/dartboard-setup');
      return;
    }

    // Saved config + reachable dartboard (or emulator mode) → home.
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
