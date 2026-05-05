import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/test_keys.dart';
import '../providers/dartboard_provider.dart';
import '../services/dart_announcer_service.dart';
import '../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import 'options_screen.dart';
import 'games/carnival_horse_race/horse_race_menu_screen.dart';
import 'games/target_tag/target_tag_menu_screen.dart';
import 'games/monster_mash/monster_mash_menu_screen.dart';
import 'games/reef_royale/reef_royale_menu_screen.dart';
import 'games/clockwork_quest/clockwork_quest_menu_screen.dart';
import 'games/lunar_lander/lunar_lander_menu_screen.dart';

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

  void _navigateToMenu(String gameType) {
    Widget menuScreen;
    switch (gameType) {
      case 'carnival_derby':
        menuScreen = const HorseRaceMenuScreen();
        break;
      case 'target_tag':
        menuScreen = const TargetTagMenuScreen();
        break;
      case 'monster_mash':
        menuScreen = const MonsterMashMenuScreen();
        break;
      case 'reef_royale':
        menuScreen = const ReefRoyaleMenuScreen();
        break;
      case 'clockwork_quest':
        menuScreen = const ClockworkQuestMenuScreen();
        break;
      case 'lunar_lander':
        menuScreen = const LunarLanderMenuScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => menuScreen));
  }

  Widget _buildGameCard({
    required BuildContext context,
    Key? key,
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
      return Container(
        key: key,
        child: InkWell(
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
                SizedBox(height: title == 'Target Tag' || title == 'Monster Mash' ? 10 : 8),
                Text(
                  title,
                  style: title == 'Carnival Derby'
                      ? GoogleFonts.rye(
                          fontSize: theme.textTheme.titleMedium?.fontSize,
                          color: isDisabled ? Colors.grey : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        )
                      : title == 'Target Tag'
                          ? GoogleFonts.luckiestGuy(
                              fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 4,
                              color: isDisabled ? Colors.grey : theme.colorScheme.onSurface,
                              letterSpacing: 1.2,
                            )
                          : title == 'Monster Mash'
                              ? GoogleFonts.creepster(
                                  fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 7,
                                  fontWeight: FontWeight.bold,
                                  color: isDisabled ? Colors.grey : theme.colorScheme.onSurface,
                                  letterSpacing: 1.0,
                                )
                          : title == 'Reef Royale'
                              ? GoogleFonts.fredoka(
                                  fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 6,
                                  fontWeight: FontWeight.bold,
                                  color: isDisabled ? Colors.grey : theme.colorScheme.onSurface,
                                )
                          : title == 'Clockwork Quest'
                              ? GoogleFonts.cinzelDecorative(
                                  fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 4,
                                  fontWeight: FontWeight.bold,
                                  color: isDisabled ? Colors.grey : theme.colorScheme.onSurface,
                                  letterSpacing: 1.2,
                                )
                          : title == 'Lunar Lander'
                              ? GoogleFonts.orbitron(
                                  fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 3,
                                  fontWeight: FontWeight.bold,
                                  color: isDisabled ? Colors.grey : theme.colorScheme.onSurface,
                                  letterSpacing: 1.0,
                                )
                          : theme.textTheme.titleMedium?.copyWith(
                              color: isDisabled ? Colors.grey : theme.colorScheme.onSurface,
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

    // Default card layout for icon-based games
    return Card(
      key: key,
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

  List<Map<String, dynamic>> _getAvailableGames(DartboardProvider dartboardProvider) {
    // Define all available games here
    final games = [
      {
        'title': 'Carnival Derby',
        'key': HomeKeys.carnivalDerbyCard,
        'imageAssetPath': 'assets/common/icons/icon.png',
        'color': Colors.amber,
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('carnival_derby')
            : null,
      },
      {
        'title': 'Target Tag',
        'key': HomeKeys.targetTagCard,
        'imageAssetPath': 'assets/games/target_tag/icons/TargetTag-Icon.png',
        'color': const Color(0xFFFF007A),
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('target_tag')
            : null,
      },
      {
        'title': 'Monster Mash',
        'key': HomeKeys.monsterMashCard,
        'imageAssetPath': 'assets/games/monster_mash/icons/MonsterMash-Icon.png',
        'color': const Color(0xFF4B0082), // Haunted Purple
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('monster_mash')
            : null,
      },
      {
        'title': 'Reef Royale',
        'key': HomeKeys.reefRoyaleCard,
        'imageAssetPath': 'assets/games/reef_royale/icons/ReefRoyale-Icon.png',
        'color': const Color(0xFF0B3D91), // Deep Reef Blue
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('reef_royale')
            : null,
      },
      {
        'title': 'Clockwork Quest',
        'key': HomeKeys.clockworkQuestCard,
        'imageAssetPath': 'assets/games/clockwork_quest/icons/icon.png',
        'color': const Color(0xFF2C2C34), // Dark Iron
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('clockwork_quest')
            : null,
      },
      {
        'title': 'Lunar Lander',
        'key': HomeKeys.lunarLanderCard,
        'imageAssetPath': 'assets/games/lunar_lander/icons/LunarLander-Icon.png',
        'color': const Color(0xFF1B4965), // Earth Blue
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('lunar_lander')
            : null,
      },
      // Add new games here - they will automatically be sorted alphabetically
    ];

    // Sort games alphabetically by title
    games.sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));

    return games;
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final games = _getAvailableGames(dartboardProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF44336),
                    Color(0xFFFFC107),
                  ],
                ),
              ),
            ),
            title: Row(
              children: [
                Image.asset(
                  'assets/common/images/logo.png',
                  height: 40,
                  width: 40,
                ),
                const SizedBox(width: 12),
                const Text('Let\'s play some Dart Games'),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.homeScreen(),
                ),
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
                        Icon(Icons.settings, color: Colors.grey),
                        SizedBox(width: 12),
                        Text('System Settings'),
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
            foregroundColor: Colors.white,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const tileWidth = 360.0;
                    const minSpacing = 12.0;
                    final availableWidth = constraints.maxWidth;

                    int itemsPerRow = ((availableWidth + minSpacing) / (tileWidth + minSpacing)).floor();
                    itemsPerRow = itemsPerRow.clamp(1, games.length);

                    final justifiedSpacing = itemsPerRow > 1
                        ? (availableWidth - (itemsPerRow * tileWidth)) / (itemsPerRow - 1)
                        : 0.0;

                    final rows = <List<Map<String, dynamic>>>[];
                    for (var i = 0; i < games.length; i += itemsPerRow) {
                      rows.add(games.sublist(i, (i + itemsPerRow).clamp(0, games.length)));
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                            if (rowIndex > 0) const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: rows[rowIndex].length == itemsPerRow
                                  ? MainAxisAlignment.spaceBetween
                                  : MainAxisAlignment.start,
                              children: [
                                for (var i = 0; i < rows[rowIndex].length; i++) ...[
                                  if (i > 0 && rows[rowIndex].length < itemsPerRow)
                                    SizedBox(width: justifiedSpacing),
                                  SizedBox(
                                    width: tileWidth,
                                    height: 400,
                                    child: _buildGameCard(
                                      context: context,
                                      key: rows[rowIndex][i]['key'] as Key?,
                                      imageAssetPath: rows[rowIndex][i]['imageAssetPath'] as String?,
                                      title: rows[rowIndex][i]['title'] as String,
                                      color: rows[rowIndex][i]['color'] as Color,
                                      onTap: rows[rowIndex][i]['onTap'] as VoidCallback?,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status != DartboardConnectionStatus.connected &&
            dartboardProvider.status != DartboardConnectionStatus.emulator)
          DartboardPausedModal(
            config: DartboardPausedModalConfig.homeScreen(),
          ),
      ],
    );
  }
}
