import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/game_filter_registry.dart';
import '../constants/test_keys.dart';
import '../models/game_metadata.dart';
import '../providers/dartboard_provider.dart';
import '../services/dart_announcer_service.dart';
import '../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import '../widgets/game_filter_bar/game_filter_bar.dart';
import 'options_screen.dart';
import 'games/carnival_horse_race/horse_race_menu_screen.dart';
import 'games/target_tag/target_tag_menu_screen.dart';
import 'games/monster_mash/monster_mash_menu_screen.dart';
import 'games/reef_royale/reef_royale_menu_screen.dart';
import 'games/clockwork_quest/clockwork_quest_menu_screen.dart';
import 'games/lunar_lander/lunar_lander_menu_screen.dart';
import 'games/pirates_grid/pirates_grid_menu_screen.dart';
import 'games/gladiator_arena/gladiator_arena_menu_screen.dart';
import 'games/tiki_golf/tiki_golf_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // App-wide shared instance — same instance used by every game's
  // GameAnnouncementQueueService and by the app-root pause/reconnect
  // announcer, so voice changes saved from Options are what games
  // speak with. See [DartAnnouncerService.shared].
  final DartAnnouncerService _announcer = DartAnnouncerService.shared;

  /// Active filter selections, keyed by criterion. Empty / missing entries
  /// mean "no filter applied" for that criterion. See game_metadata.dart for
  /// AND/OR semantics.
  Map<FilterCriterion, Set<Object>> _filters = const {};

  @override
  void dispose() {
    // No _announcer.dispose() — the app-wide shared instance is kept
    // alive intentionally. `dispose()` on the shared instance is a
    // no-op anyway (see DartAnnouncerService.dispose), but skipping
    // the call here makes the intent explicit.
    super.dispose();
  }

  /// Resolves a game card's label style from the registry (WS03 §3.2).
  ///
  /// This replaced an eleven-way ternary keyed on the DISPLAY STRING
  /// (`title == 'Carnival Derby' ? ... : title == 'Target Tag' ? ...`).
  /// Keying on the display name meant renaming a game silently dropped its
  /// card to the default style, and adding game #11 meant remembering to
  /// extend a chain buried in a build method. Games with no registered style
  /// (Pirate's Grid) get the app default, exactly as the ternary's else did.
  TextStyle? _cardTitleStyle(
      BuildContext context, String? gameId, bool isDisabled) {
    final theme = Theme.of(context);
    final color =
        isDisabled ? Colors.grey : theme.colorScheme.onSurface;
    final base = theme.textTheme.titleMedium?.fontSize ?? 16;

    final entry = gameId == null ? null : GameFilterRegistry.byId(gameId);
    final style = entry?.cardTitleStyle;
    if (style == null) {
      return theme.textTheme.titleMedium
          ?.copyWith(color: color, fontWeight: FontWeight.bold);
    }
    return style.resolve(baseSize: base, color: color);
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
      case 'pirates_grid':
        menuScreen = const PiratesGridMenuScreen();
        break;
      case 'gladiator_arena':
        menuScreen = const GladiatorArenaMenuScreen();
        break;
      case 'tiki_golf':
        menuScreen = const TikiGolfMenuScreen();
        break;
      case 'treasure_divide':
        Navigator.pushNamed(context, '/treasure-divide');
        return;
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
    /// Registry key — drives the card's label style (WS03 §3.2).
    String? gameId,
    required String title,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    // If image asset is provided, use simple icon layout
    if (imageAssetPath != null) {
      // Three-container layout per user instruction:
      //   - Outer container (the parent SizedBox at line 558-560 sets it to
      //     tileWidth × 400) is the overall tile.
      //   - Inner image container: SizedBox(height: 340) — same fixed height
      //     for every card so all icons sit in an identical-sized box. Source
      //     PNG dimensions are the visible content size (no transparent
      //     padding); BoxFit.contain renders each icon at its natural aspect
      //     inside this fixed box. Some icons render slightly taller/shorter
      //     within the 340-tall area depending on aspect — that's expected.
      //   - Inner label container: SizedBox(height: 44) — fixed height so the
      //     label sits at the same Y position across every card regardless of
      //     icon aspect or font.
      // 340 + 44 = 384 = 400 (outer card height) - 16 (vertical padding).
      // No Expanded anywhere, so the icon never expands to fill the column
      // and push the label to the bottom; no AspectRatio, so the icon area
      // never depends on tile width (which caused the 13px overflow on wide
      // tiles previously).
      return Container(
        key: key,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
            child: Column(
              children: [
                // Image container — fixed 340 tall.
                SizedBox(
                  height: 340,
                  child: Opacity(
                    opacity: isDisabled ? 0.5 : 1.0,
                    child: Center(
                      child: Image.asset(
                        imageAssetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Label container — fixed 44 tall; text centered within.
                // Boogaloo (Tiki Golf) has descenders that push the visual
                // baseline lower than peer fonts, so the Tiki Golf label sits
                // visibly below the others. Shift it up 10px via
                // Transform.translate (visual-only, doesn't affect layout).
                SizedBox(
                  height: 44,
                  child: Center(
                    child: Transform.translate(
                      offset: title == 'Tiki Golf'
                          ? const Offset(0, -7)
                          : Offset.zero,
                      child: Text(
                  title,
                  style: _cardTitleStyle(context, gameId, isDisabled),
                      textAlign: TextAlign.center,
                    ),
                    ),
                  ),
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
    // Define all available games here. Each entry's `gameId` matches the
    // registry id in lib/constants/game_filter_registry.dart so the filter
    // bar can match cards by id.
    final games = [
      {
        'gameId': 'carnival_derby',
        'title': 'Carnival Derby',
        'key': HomeKeys.carnivalDerbyCard,
        'imageAssetPath': 'assets/common/icons/icon.png',
        'color': Colors.amber,
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('carnival_derby')
            : null,
      },
      {
        'gameId': 'target_tag',
        'title': 'Target Tag',
        'key': HomeKeys.targetTagCard,
        'imageAssetPath': 'assets/games/target_tag/icons/TargetTag-Icon.png',
        'color': const Color(0xFFFF007A),
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('target_tag')
            : null,
      },
      {
        'gameId': 'monster_mash',
        'title': 'Monster Mash',
        'key': HomeKeys.monsterMashCard,
        'imageAssetPath': 'assets/games/monster_mash/icons/MonsterMash-Icon.png',
        'color': const Color(0xFF4B0082), // Haunted Purple
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('monster_mash')
            : null,
      },
      {
        'gameId': 'reef_royale',
        'title': 'Reef Royale',
        'key': HomeKeys.reefRoyaleCard,
        'imageAssetPath': 'assets/games/reef_royale/icons/ReefRoyale-Icon.png',
        'color': const Color(0xFF0B3D91), // Deep Reef Blue
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('reef_royale')
            : null,
      },
      {
        'gameId': 'clockwork_quest',
        'title': 'Clockwork Quest',
        'key': HomeKeys.clockworkQuestCard,
        'imageAssetPath': 'assets/games/clockwork_quest/icons/icon.png',
        'color': const Color(0xFF2C2C34), // Dark Iron
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('clockwork_quest')
            : null,
      },
      {
        'gameId': 'lunar_lander',
        'title': 'Lunar Lander',
        'key': HomeKeys.lunarLanderCard,
        'imageAssetPath': 'assets/games/lunar_lander/icons/LunarLander-Icon.png',
        'color': const Color(0xFF1B4965), // Earth Blue
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('lunar_lander')
            : null,
      },
      {
        'gameId': 'pirates_grid',
        'title': "Pirate's Grid",
        'key': HomeKeys.piratesGridCard,
        'imageAssetPath': 'assets/games/pirates_grid/icons/PiratesGrid-Icon.png',
        'color': const Color(0xFF1B2838), // Ocean Navy
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('pirates_grid')
            : null,
      },
      {
        'gameId': 'gladiator_arena',
        'title': 'Gladiator Arena',
        'key': HomeKeys.gladiatorArenaCard,
        'imageAssetPath': 'assets/games/gladiator_arena/icons/GladiatorArena-Icon.png',
        'color': const Color(0xFF7B2D8E), // Imperial Purple
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('gladiator_arena')
            : null,
      },
      {
        'gameId': 'tiki_golf',
        'title': 'Tiki Golf',
        'key': HomeKeys.tikiGolfCard,
        'imageAssetPath': 'assets/games/tiki_golf/icons/TikiGolf-Icon.png',
        'color': const Color(0xFF2D6A4F), // Palm Green
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('tiki_golf')
            : null,
      },
      {
        'gameId': 'treasure_divide',
        'title': 'Treasure Divide',
        'key': HomeKeys.treasureDivideCard,
        'imageAssetPath': 'assets/games/treasure_divide/icons/TreasureDivide-Icon.png',
        'color': const Color(0xFF008B8B), // Ocean Teal
        'onTap': dartboardProvider.canPlayGames
            ? () => _navigateToMenu('treasure_divide')
            : null,
      },
      // Add new games here - they will automatically be sorted alphabetically
    ];

    // Sort games alphabetically by title
    games.sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));

    return games;
  }

  /// Apply the current `_filters` selections to the games list, dropping
  /// any whose registry metadata doesn't match. Games not registered in
  /// [GameFilterRegistry] (shouldn't happen, AR-4 enforces registration)
  /// are kept — better to show an unfiltered card than hide it silently.
  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> games) {
    if (_filters.isEmpty) return games;
    return games.where((g) {
      final id = g['gameId'] as String;
      final metadata = GameFilterRegistry.byId(id);
      if (metadata == null) return true;
      return metadata.matchesFilters(_filters);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final allGames = _getAvailableGames(dartboardProvider);
    final games = _applyFilters(allGames);

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
          // Body: Column[FilterBar (sticky), Expanded(scrollable grid)].
          // The filter bar stays pinned below the AppBar; only the grid scrolls.
          body: Column(
            children: [
              GameFilterBar(
                filters: _filters,
                onFiltersChanged: (next) => setState(() => _filters = next),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const tileWidth = 360.0;
                      const minSpacing = 12.0;
                      final availableWidth = constraints.maxWidth;

                      // Guard against the filtered list being empty —
                      // games.length=0 would crash itemsPerRow.clamp(1, 0).
                      if (games.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No games match the selected filters.\nTry clearing one or more filters.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }

                      // Natural fit per the screen width (NOT clamped to
                      // games.length). With 2 games on a wide screen this
                      // stays at e.g. 5 — so the single row of 2 is treated
                      // as a partial row (left-justified with minSpacing)
                      // rather than being stretched to fill the row width.
                      int itemsPerRow = ((availableWidth + minSpacing) / (tileWidth + minSpacing)).floor();
                      if (itemsPerRow < 1) itemsPerRow = 1;

                      final rows = <List<Map<String, dynamic>>>[];
                      for (var i = 0; i < games.length; i += itemsPerRow) {
                        rows.add(games.sublist(i, (i + itemsPerRow).clamp(0, games.length)));
                      }

                      // Spacing used to fully justify a full row across the
                      // available width — i.e. what MainAxisAlignment
                      // .spaceBetween produces for itemsPerRow tiles.
                      final justifiedSpacing = itemsPerRow > 1
                          ? (availableWidth - itemsPerRow * tileWidth) /
                              (itemsPerRow - 1)
                          : 0.0;

                      // Spacing rule:
                      //   - Single row that is NOT full → use minSpacing
                      //     (compact, left-justified — avoids 2 tiles
                      //     stretching across a wide screen).
                      //   - Otherwise (multi-row layout, OR a single full
                      //     row) → use justifiedSpacing so every row's tiles
                      //     land at the same x-positions as row 0's first N
                      //     tiles. Partial last rows in a multi-row layout
                      //     therefore align vertically with the rows above.
                      final isOnlySinglePartialRow = rows.length == 1 &&
                          rows[0].length < itemsPerRow;
                      final interTileSpacing = isOnlySinglePartialRow
                          ? minSpacing
                          : justifiedSpacing;

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                              if (rowIndex > 0) const SizedBox(height: 12),
                              Row(
                                children: [
                                  for (var i = 0; i < rows[rowIndex].length; i++) ...[
                                    if (i > 0) SizedBox(width: interTileSpacing),
                                    SizedBox(
                                      width: tileWidth,
                                      height: 400,
                                      child: _buildGameCard(
                                        context: context,
                                        key: rows[rowIndex][i]['key'] as Key?,
                                        imageAssetPath: rows[rowIndex][i]['imageAssetPath'] as String?,
                                        gameId: rows[rowIndex][i]['gameId'] as String?,
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
