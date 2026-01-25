import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dartboard_provider.dart';
import '../services/dart_announcer_service.dart';
import '../widgets/dartboard_status_indicator.dart';
import '../widgets/compact_dartboard_info.dart';
import 'test_dartboard_screen.dart';
import 'options_screen.dart';
import 'games/carnival_horse_race/horse_race_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DartAnnouncerService _announcer = DartAnnouncerService();

  @override
  void dispose() {
    _announcer.dispose();
    super.dispose();
  }


  Widget _buildGameCard({
    required BuildContext context,
    IconData? icon,
    String? imageAssetPath,
    required String title,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    // If image asset is provided, use simple icon layout
    if (imageAssetPath != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Opacity(
                  opacity: isDisabled ? 0.5 : 1.0,
                  child: Image.asset(
                    imageAssetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDisabled ? Colors.grey : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Default card layout for icon-based games
    return Card(
      elevation: isDisabled ? 1 : 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isDisabled
                ? null
                : LinearGradient(
                    colors: [
                      color.withOpacity(0.7),
                      color.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon ?? Icons.games,
                size: 48,
                color: isDisabled ? Colors.grey : Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDisconnect(BuildContext context) async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Dartboard'),
        content: const Text('Are you sure you want to disconnect? You will need to set up the dartboard again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldDisconnect == true && context.mounted) {
      final dartboardProvider = context.read<DartboardProvider>();
      await dartboardProvider.clearDartboard();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dartboardProvider = context.watch<DartboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dart Games'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CompactDartboardInfo(provider: dartboardProvider),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: DartboardStatusIndicator(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'options') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OptionsScreen(announcer: _announcer),
                  ),
                );
              } else if (value == 'disconnect') {
                _handleDisconnect(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'options',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('Options'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(Icons.link_off, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Disconnect Dartboard'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Games',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 315,
                  height: 350,
                  child: _buildGameCard(
                    context: context,
                    imageAssetPath: 'assets/icon/icon.png',
                    title: 'Carnival\nDerby',
                    color: Colors.amber,
                    onTap: dartboardProvider.canPlayGames
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HorseRaceMenuScreen(),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
                SizedBox(
                  width: 315,
                  height: 350,
                  child: _buildGameCard(
                    context: context,
                    icon: Icons.casino,
                    title: 'More Games\nComing Soon',
                    color: Colors.grey,
                    onTap: null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
