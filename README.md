# Dart Games

A Flutter-based container app for interactive dartboard games powered by the Scolia 2 dartboard system.

> **⚠️ Important:** This app requires a **Scolia 2 dartboard** and a valid **Scolia API key** to function. You must contact [Scolia](https://scolia.com) to obtain an API key before using this application.

## Overview

Dart Games is a cross-platform (web and tablet) application that provides a framework for building interactive dartboard games. The app handles dartboard connectivity, user management, and common game features, allowing developers to focus on creating unique game experiences.

### Current Games

- **Carnival Derby** - A horse race-style game where players advance by scoring points with darts
- **Clockwork Quest** - A steampunk gear progression game where players activate sequential gears on a clockwork tower
- **Monster Mash** - A monster-themed battle game where players attack opponents and heal themselves using target numbers
- **Reef Royale** - An ocean-themed coral claiming game where players compete for territory on the dartboard
- **Target Tag** - A strategic elimination game where players build shields and tag opponents to win

## Features

### Core Infrastructure

- **Dartboard Integration** - Seamless connection to Scolia 2 physical dartboards via API
- **Emulator Mode** - Test games without physical hardware using the built-in dartboard emulator
- **Server-Side Storage** - Dart Shelf backend server with SQLite for centralized data persistence, schema migrations, failed stats logging, and per-session database isolation for UI test parallelism
- **Global User Management** - Shared player profiles, statistics, and game history across all games
- **Global Announcement Queue** - Priority-based announcement system with sound effects for consistent audio experience
- **Voice Announcer** - Customizable text-to-speech announcements with multiple voice engines and personalities
- **Victory Music** - Custom victory music management with random selection
- **Responsive Design** - Works on web browsers (Chrome, Safari, Firefox, Edge) and tablets (iOS, Android)

### Shared Services

All games in the Dart Games ecosystem integrate with these shared systems:

#### 1. Dartboard Provider (`DartboardProvider`)
- Manages connection to physical Scolia dartboard or emulator
- Real-time dart throw detection
- Status tracking (connected, disconnected, connecting)

```dart
// Access dartboard provider
final dartboardProvider = context.read<DartboardProvider>();

// Listen to dart throws
dartboardProvider.apiService?.dartThrowStream.listen((event) {
  final score = event['score'];
  final multiplier = event['multiplier'];
  // Handle dart throw
});
```

#### 2. Player Provider (`PlayerProvider`)
- Global player list shared across all games
- Player profiles with photos and statistics
- Game history tracking with duration

```dart
// Access player provider
final playerProvider = context.read<PlayerProvider>();

// Get all players
final players = playerProvider.allPlayers;

// Add new player
await playerProvider.savePlayer(Player(
  id: generateId(),
  name: 'Player Name',
  photoPath: photoPath,
));

// Update player stats when game ends (for ALL players - winners AND losers)
await playerProvider.updatePlayerStats(
  playerId,
  won: true,  // or false for losers
  gameName: 'Your Game Name',
  gameDuration: gameDuration,
  dartThrows: game.getTotalDartsThrown(playerId),    // Total darts thrown by player
  turns: game.getTotalTurns(playerId),                // Total turns taken by player
  playerCount: game.getPlayerCount(),                 // Total players in the game
);
```

**Failed Stats Handling:** If a stats update fails (e.g. player deleted mid-game, server 404, network error), `PlayerProvider` automatically logs the failure to the server's `failed_stats` table via `POST /api/v1/stats/failed`. This preserves the failure payload for later investigation or replay. Failed entries can be retrieved with `GET /api/v1/stats/failed` and cleared with `DELETE /api/v1/stats/failed`.

#### 3. Announcer Service (`DartAnnouncerService`)
- Text-to-speech for game events
- Multiple voice engines (Browser Voices, ResponsiveVoice)
- Customizable personalities (Professional, Excited, Calm, Funny, Drill Sergeant)

**NOTE:** Games should NOT use `DartAnnouncerService` directly. Instead, use the `GameAnnouncementQueueService` (see section 5 below) which manages the announcer automatically with sound effects and queuing.

```dart
// ❌ DON'T use DartAnnouncerService directly in games
final announcer = DartAnnouncerService();

// ✅ DO use GameAnnouncementQueueService with game-specific helper
final globalQueue = GameAnnouncementQueueService();
await globalQueue.loadSettings();
final audioQueue = YourGameAnnouncementHelper(globalQueue);
```

#### 4. Victory Music Service (`VictoryMusicService`)
- Custom music file management via backend API
- Random selection from user's music library
- Music uploaded to server as base64, played via server URLs

```dart
// Access victory music service
final musicService = VictoryMusicService();

// Check if custom music is available
if (await musicService.hasCustomMusic()) {
  final musicSource = await musicService.getRandomMusicSource();
  // Play music via server URL
}
```

#### 5. Game Announcement Queue (`GameAnnouncementQueueService`)
- Global priority-based announcement queue used by ALL games
- Manages voice announcements with optional sound effects
- Prevents announcement overlap with intelligent queuing
- Games create helpers that wrap this service with game-specific methods

```dart
// Create game-specific announcement helper
import 'package:dart_games/services/game_announcement_queue_service.dart';
import 'your_game_sound_effects.dart';

class YourGameAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  YourGameAnnouncementHelper(this._queue);

  void announcePlayerTurn(String playerName) {
    _queue.announce(
      '$playerName, your turn',
      AudioPriority.turnTransition,
      soundEffect: YourGameSoundEffects.turnStart,
    );
  }
}

// Initialize in your game screen
final globalQueue = GameAnnouncementQueueService();
await globalQueue.loadSettings();
final audioQueue = YourGameAnnouncementHelper(globalQueue);

// Use throughout your game
audioQueue.announcePlayerTurn(player.name);
```

**Priority Levels:**
- `turnTransition` (1) - Turn changes, remove darts
- `hitConfirm` (2) - Dart hit/miss announcements
- `shieldStatus` (3) - Status updates (Target Tag specific)
- `statusChange` (4) - Game status changes
- `victory` (5) - Game completion, winners

See [CLAUDE.md](CLAUDE.md) for complete integration guide.

#### 6. Edit Score Dialog (`lib/widgets/edit_score/`)
- Shared modal for editing three dart scores (ring + number picker) during a turn
- Ensures consistent dart-picker logic while allowing game-specific styling
- Supports optional per-dart border color overrides for result-based coloring (Target Tag)
- Supports optional score display transform (Carnival Derby shows calculated points, Target Tag shows raw segment)

```dart
// Import the shared component
import 'package:dart_games/widgets/edit_score/edit_score.dart';

// Show Edit Score dialog
showEditScoreDialog(
  context: context,
  playerName: currentPlayer.name,
  initialSegments: yourProvider.getCurrentTurnDartScores(currentPlayer.id),
  onSubmit: (newSegments) =>
      yourProvider.updateAllDartScores(currentPlayer.id, newSegments),
  config: EditScoreDialogConfig.yourGame(), // Use appropriate factory
  // dartBorderColors: _computeDartBorderColors(currentPlayer.id), // optional
);
```

**Features:**
- Ring/number picker for all 3 darts (Single inner/outer, Double, Triple, Outer Bull, Bullseye, Miss)
- Submit disabled until all 3 darts have valid selections
- Game-specific styling via configuration factories
- Eliminates ~860 lines of duplicated code

**Available Configurations:**
- `EditScoreDialogConfig.carnivalDerby()` - Midnight Navy bg, Canary Yellow accents, calculated score display
- `EditScoreDialogConfig.targetTag()` - Dark Navy bg, Hot Pink border, Neon Green selected, raw segment display

See [CLAUDE.md](CLAUDE.md) for complete integration guide and custom configuration examples.

#### 7. Add Player Dialog (`lib/widgets/add_player/`)
- Shared modal for adding new players across all games and System Settings
- Ensures consistent player creation logic while allowing screen-specific styling
- Returns `Player?` object if created, `null` if cancelled

```dart
// Import the shared component
import 'package:dart_games/widgets/add_player/add_player.dart';

// Show Add Player dialog
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.yourGame(), // Use appropriate factory
);

if (player != null && mounted) {
  final playerProvider = context.read<PlayerProvider>();
  await playerProvider.savePlayer(player);

  // Optional: Auto-select player (games only)
  if (playerProvider.selectedPlayers.length < maxPlayers) {
    playerProvider.selectPlayer(player, maxPlayers: maxPlayers);
  }

  // Optional: Show success feedback (System Settings only)
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Player "${player.name}" added')),
  );
}
```

**Features:**
- Photo upload via camera or gallery
- Name validation
- Photo preview with remove button
- Game-specific styling via configuration factories
- Eliminates ~750 lines of duplicated code

**Available Configurations:**
- `AddPlayerDialogConfig.carnivalDerby()` - Carnival theme (red/yellow/teal)
- `AddPlayerDialogConfig.targetTag()` - Tech/neon theme (pink/green)
- `AddPlayerDialogConfig.optionsScreen(context)` - Material Design defaults

See [CLAUDE.md](CLAUDE.md) for complete integration guide and custom configuration examples.

#### 8. In-Game Dartboard Emulator Components (`lib/widgets/dartboard_emulator/`)
- Shared UI components for offline development and testing when a physical Scolia dartboard is NOT connected
- ONLY shown when `dartboardProvider.isConnected` is `false` (emulator mode)
- Automatically hidden when connected to a real Scolia dartboard
- Allows developers to test game logic without physical hardware

```dart
// Import dartboard emulator components
import 'package:dart_games/widgets/dartboard_emulator/dartboard_emulator.dart';

class _YourGameScreenState extends State<YourGameScreen> {
  final DartboardEmulatorController _dartboardEmulatorController = DartboardEmulatorController();
  final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey<InteractiveDartboardState>();

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();

    return Scaffold(
      // FAB only appears when NOT connected to real dartboard
      floatingActionButton: DartboardEmulatorFAB(
        controller: _dartboardEmulatorController,
        isConnected: dartboardProvider.isConnected,
        config: DartboardFABConfig.yourGame(),
      ),
      body: Column(
        children: [
          // Your game UI

          // Dartboard emulator only appears when NOT connected to real dartboard
          DartboardEmulatorSection(
            controller: _dartboardEmulatorController,
            isConnected: dartboardProvider.isConnected,
            shouldPromptTakeout: shouldPromptTakeout,
            dartboardKey: _dartboardKey,
            onDartThrow: (score, multiplier, baseScore, position) {
              // Handle dart throw (simulates physical dartboard input)
            },
            onRemoveDarts: () {
              // Handle darts removed
            },
            config: DartboardSectionConfig.yourGame(),
          ),
        ],
      ),
    );
  }
}
```

**Components:**
- **DartboardEmulatorController** - Manages show/hide state using ChangeNotifier pattern
- **DartboardEmulatorSection** - Dartboard container widget with disabled overlay
- **DartboardEmulatorFAB** - Floating action button for toggling dartboard visibility
- **Configuration Classes** - Game-specific styling via factory methods

**Benefits:**
- Ensures consistent dartboard behavior across all games during offline testing
- Reduces code duplication (~200 lines eliminated per game)
- Allows game-specific visual styling (colors, fonts, backgrounds)
- Bug fixes in shared component benefit all games automatically
- New games only need to provide configuration objects
- Seamlessly hidden when playing with real dartboard

See [CLAUDE.md](CLAUDE.md) for complete integration guide.

#### 9. Dartboard Connection Info (`lib/widgets/dartboard_connection_info/`)
- Shared widget displaying dartboard name, type (emulator/hardware), and connection status
- Uses `Consumer<DartboardProvider>` internally for reactive updates
- Game-specific theming via `DartboardConnectionInfoConfig` factory methods
- Returns `SizedBox.shrink()` if no dartboard configured

```dart
// Import the shared component
import 'package:dart_games/widgets/dartboard_connection_info/dartboard_connection_info.dart';
import 'package:dart_games/widgets/dartboard_connection_info/dartboard_connection_info_config.dart';

// Add to AppBar actions
AppBar(
  title: Text('Your Game'),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: DartboardConnectionInfo(
        config: DartboardConnectionInfoConfig.yourGame(),
      ),
    ),
  ],
),
```

**Available Configurations:**
- `DartboardConnectionInfoConfig.homeScreen()` - White background, standard styling
- `DartboardConnectionInfoConfig.carnivalDerby()` - Carnival theme (Rye font, Lava Red/Canary Yellow)
- `DartboardConnectionInfoConfig.targetTag()` - Tech/neon theme (Luckiest Guy font, Hot Pink/Neon Green)
- `DartboardConnectionInfoConfig.monsterMash()` - Gothic theme (Creepster font, Lime Green/Beige)

See [CLAUDE.md](CLAUDE.md) for complete integration guide.

#### 10. Skip Turn Helper (`GameSkipTurnHelper`)
- Global utility for consistent skip turn behavior across ALL games
- Ensures skip turn does NOT increment dart throw or turn counters
- Provides validation and visual marker management
- **ALL games MUST use this helper for skip turn functionality**

```dart
// Import the skip turn helper
import 'package:dart_games/services/game_skip_turn_helper.dart';

// In your game provider's skipTurn() method
void skipTurn() {
  if (_currentGame == null) return;

  final currentPlayerId = _currentGame!.getCurrentPlayerId();
  final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();

  // Validate using global helper
  if (!GameSkipTurnHelper.canSkipTurn(
    gameActive: isGameActive,
    waitingForTakeout: _waitingForTakeout,
    currentDartCount: dartsThrown,
    maxDartsPerTurn: 3,
  )) {
    return;
  }

  // Execute skip using global helper
  GameSkipTurnHelper.skipRemainingDarts(
    currentDartCount: dartsThrown,
    maxDartsPerTurn: 3,
    addVisualMarker: (marker) {
      // Add "Skip" to your game's display list
      _currentGame!.currentTurnDarts[currentPlayerId]!.add(marker);
    },
  );

  _waitingForTakeout = true;
  notifyListeners();
}
```

**Key Behavior:**
- Skip turn adds visual "Skip" markers but does NOT call dart processing methods
- Dart throw counters are NOT incremented
- Turn counters are NOT incremented if player threw 0 darts
- If player threw 1+ darts before skipping, turn IS counted (turn increments on first dart)

**Benefits:**
- Ensures all games (current and future) have identical skip turn behavior
- Centralized logic - bug fixes benefit all games
- Clear documentation of skip turn requirements
- Easier to test (unit test the helper directly)

**Reference Implementations:**
- Target Tag: `lib/providers/target_tag_provider.dart`
- Carnival Derby: `lib/providers/horse_race_provider.dart`
- Helper source: `lib/services/game_skip_turn_helper.dart`

#### 11. Remove Darts Modal (`lib/widgets/remove_darts_modal/`)
- Shared full-screen overlay prompting the player to remove their darts from the board
- Appears when a turn ends and no physical dartboard is connected
- Game-specific theming via `RemoveDartsModalConfig` factory methods
- Includes "Edit player score" button with game-specific callback

```dart
// Import the shared component
import 'package:dart_games/widgets/remove_darts_modal/remove_darts_modal.dart';

// In your game screen's Stack:
if (shouldPromptTakeout && !dartboardProvider.isConnected)
  RemoveDartsModal(
    config: RemoveDartsModalConfig.yourGame(),
    playerName: currentPlayer?.name ?? 'Player',
    editScoreButtonKey: YourGameKeys.editScoreButton,
    onEditScore: () {
      if (currentPlayer == null) return;
      showEditScoreDialog(
        context: context,
        playerName: currentPlayer.name,
        initialSegments: yourProvider.getCurrentTurnDarts(currentPlayer.id),
        onSubmit: (newSegments) =>
            yourProvider.updateAllDartScores(currentPlayer.id, newSegments),
        config: EditScoreDialogConfig.yourGame(),
      );
    },
  ),
```

**Available Configurations:**
- `RemoveDartsModalConfig.carnivalDerby()` - Canary Yellow border, LuckiestGuy/Bangers fonts
- `RemoveDartsModalConfig.targetTag()` - Hot Pink border, Fredoka font
- `RemoveDartsModalConfig.monsterMash()` - Lime Green border with green glow, Creepster/PirataOne fonts

See [CLAUDE.md](CLAUDE.md) for complete integration guide.

#### 12. Player List Panel (`lib/widgets/player_list_panel/`)
- Shared, configurable player management UI for game menu screens
- Two patterns: dual-list (Available + Selected) and single-list with team assignment
- Game-specific theming via config classes with factory methods
- Custom button builders for unique game styling (Monster Mash stone buttons)

```dart
// Dual-list pattern (Carnival Derby, Monster Mash)
import 'package:dart_games/widgets/player_list_panel/player_list_panel.dart';

DualPlayerListPanel(
  config: DualPlayerListPanelConfig.carnivalDerby(),
  addPlayerButtonKey: CarnivalDerbyMenuKeys.addPlayerButton,
  addPlayerButtonEmptyStateKey: CarnivalDerbyMenuKeys.addPlayerButtonEmptyState,
  playerListViewKey: CarnivalDerbyMenuKeys.playerListView,
  playerTileKey: (id) => CarnivalDerbyMenuKeys.playerTile(id),
  removePlayerButtonKey: (id) => CarnivalDerbyMenuKeys.removePlayerButton(id),
)

// Team game pattern (Target Tag)
TeamPlayerListPanel(
  config: TeamPlayerListPanelConfig.targetTag(),
  isTeamMode: _isTeamMode,
  isManualTeamAssignment: !_isRandomTeams,
  teamIconPaths: _teamIconPaths,
  onTeamAssignmentsChanged: (assignments) {
    setState(() { _playerTeamAssignments = assignments; });
  },
)
```

**Available Configurations:**
- `DualPlayerListPanelConfig.carnivalDerby()` - Navy containers, Bangers font, Lava Red button
- `DualPlayerListPanelConfig.monsterMash()` - Dark slate containers, PirataOne headers, Creepster names
- `TeamPlayerListPanelConfig.targetTag()` - Hot Pink/Neon Green theme, Fredoka font

See [CLAUDE.md](CLAUDE.md) for complete integration guide.

#### 13. Save Game Modal (`lib/widgets/save_game_modal/`)
- Shared modal that prompts players to save their game when leaving mid-game
- Appears when pressing back button during an active game
- Game-specific theming via `SaveGameModalConfig` factory methods
- Handles save confirmation, discard, and cancel actions

```dart
// Import the shared component
import 'package:dart_games/widgets/save_game_modal/save_game_modal.dart';
import 'package:dart_games/widgets/save_game_modal/save_game_modal_config.dart';

// Show save game modal when leaving mid-game
SaveGameModal(
  config: SaveGameModalConfig.yourGame(),
  onSave: () async {
    await yourProvider.saveGame();
    Navigator.of(context).pop();
  },
  onDontSave: () => Navigator.of(context).pop(),
  onCancel: () {}, // Dismiss modal, continue playing
)
```

**Available Configurations:**
- `SaveGameModalConfig.carnivalDerby()` - Carnival theme
- `SaveGameModalConfig.targetTag()` - Tech/neon theme
- `SaveGameModalConfig.monsterMash()` - Gothic theme
- `SaveGameModalConfig.reefRoyale()` - Ocean theme

#### 14. Resume Game Modal (`lib/widgets/resume_game_modal/`)
- Shared modal for browsing and selecting saved games to resume
- Displays saved game metadata (date, players, progress, mode)
- Supports selecting, deleting, and resuming saved games
- Game-specific theming via `ResumeGameModalConfig` factory methods

```dart
// Import the shared component
import 'package:dart_games/widgets/resume_game_modal/resume_game_modal.dart';
import 'package:dart_games/widgets/resume_game_modal/resume_game_modal_config.dart';

// Show resume game modal on menu screen
ResumeGameModal(
  config: ResumeGameModalConfig.yourGame(),
  gameType: 'your_game',
  onResume: (savedGame) async {
    await yourProvider.restoreGame(savedGame);
    Navigator.of(context).pushReplacement(/* game screen */);
  },
  onDismiss: () => setState(() => _showResumeModal = false),
)
```

**Available Configurations:**
- `ResumeGameModalConfig.carnivalDerby()` - Carnival theme
- `ResumeGameModalConfig.targetTag()` - Tech/neon theme
- `ResumeGameModalConfig.monsterMash()` - Gothic theme
- `ResumeGameModalConfig.reefRoyale()` - Ocean theme

#### 15. Save Game Service (`lib/services/save_game_service.dart`)
- Shared service for persisting and retrieving saved game state
- Uses the backend API via `ApiClient` for centralized storage
- Supports saving, loading, listing, and deleting saved games
- Each game type stores games independently

```dart
// Import the service
import 'package:dart_games/services/save_game_service.dart';

// Save a game
final service = SaveGameService();
await service.saveGame('your_game', gameData);

// Check for saved games
final hasSaved = await service.hasSavedGames('your_game');

// List saved games
final savedGames = await service.getSavedGames('your_game');

// Delete a saved game
await service.deleteSavedGame('your_game', savedGameId);
```

#### 16. Resume Game Button (`lib/widgets/resume_game_button.dart`)
- Shared button for accessing saved games from game menu screens
- Appears in AppBar next to Dartboard Connection Info
- Automatically enabled/disabled based on saved game availability
- Game-specific color theming

```dart
// Import the shared component
import 'package:dart_games/widgets/resume_game_button.dart';

// Add to AppBar actions
AppBar(
  title: Text('Your Game Setup'),
  actions: [
    ResumeGameButton(
      key: YourGameMenuKeys.resumeGameButton,
      hasSavedGames: _hasSavedGames,
      onPressed: () => setState(() => _showResumeModal = true),
      color: yourGameThemeColor,
    ),
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: DartboardConnectionInfo(
        config: DartboardConnectionInfoConfig.yourGame(),
      ),
    ),
  ],
)

// Check for saved games on screen load
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final hasSaved = await SaveGameService().hasSavedGames('your_game');
    if (mounted) {
      setState(() {
        _hasSavedGames = hasSaved;
        _showResumeModal = hasSaved; // Auto-show modal if games exist
      });
    }
  });
}
```

**Features:**
- History icon (`Icons.history`) for visual consistency
- Enabled state: Full color, "Resume saved game" tooltip
- Disabled state: 30% opacity, "No saved games" tooltip
- Integrates with ResumeGameModal and Save & Resume feature

**Benefits:**
- Consistent access to saved games across all games
- Visual feedback when saved games exist
- Direct access from menu without navigating to home screen
- Minimal integration code per game

See [CLAUDE.md](CLAUDE.md) for complete integration guide.

## Architecture

### Container App Structure

Dart Games uses a container app architecture:

```
dart_games/
├── server/                          # Dart Shelf backend server
│   ├── bin/server.dart              # Server entry point
│   ├── lib/
│   │   ├── database/                # SQLite database layer, migrations, per-session DB registry
│   │   ├── models/                  # Server-side models
│   │   ├── routes/                  # REST API route handlers
│   │   └── middleware/              # CORS and logging middleware
│   └── test/                       # Server tests (178 tests)
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   ├── providers/                   # State management
│   ├── services/                    # Shared services
│   │   ├── api/                     # API client layer (ApiClient, ApiConfig)
│   │   └── game_skip_turn_helper.dart  # Shared skip turn logic
│   ├── widgets/                     # Reusable widgets
│   └── screens/
│       ├── splash_screen.dart       # Initial loading
│       ├── dartboard_setup_screen.dart
│       ├── home_screen.dart         # Game selection
│       ├── options_screen.dart      # System settings
│       └── games/
│           ├── carnival_horse_race/ # Carnival Derby game
│           ├── clockwork_quest/     # Clockwork Quest game
│           ├── monster_mash/        # Monster Mash game
│           ├── reef_royale/         # Reef Royale game
│           └── target_tag/          # Target Tag game
├── test/                            # Flutter non-UI tests (1179 tests)
├── integration_test/                # UI automation tests (364 tests)
└── assets/
    ├── common/                      # Shared assets (logo, app icon)
    │   ├── icons/
    │   └── images/
    └── games/                       # Game-specific assets
        ├── carnival_derby/          # Carnival Derby assets
        │   ├── icons/
        │   ├── images/
        │   └── sounds/
        ├── clockwork_quest/         # Clockwork Quest assets
        │   ├── icons/
        │   ├── images/
        │   └── sounds/
        ├── monster_mash/            # Monster Mash assets
        │   ├── icons/
        │   ├── images/
        │   └── sounds/
        ├── reef_royale/             # Reef Royale assets
        │   ├── icons/
        │   ├── images/
        │   └── sounds/
        └── target_tag/              # Target Tag assets
            ├── icons/
            └── sounds/
```

**Asset Organization:**
- All game assets (images, sounds, icons) are organized in game-specific folders under `assets/games/[game_name]/`
- Shared assets (app logo, app icon) are placed in `assets/common/`
- This prevents file name conflicts between games and creates clear ownership of assets
- When adding a new game, create `assets/games/your_game/` and organize all game assets there
- See [CLAUDE.md](CLAUDE.md) Asset Organization section for complete guidelines

### Design Philosophy

- **Core Container App** - Provides infrastructure (dartboard, users, settings)
- **Individual Games** - Built on top of container, each with unique visual identity
- **Shared Systems** - Games integrate with global user management, announcer, and victory music
- **Consistent Experience** - Unified UX patterns across all games

## Adding a New Game

To add a new game to Dart Games:

### 1. Create Game Screens

Create a new directory in `lib/screens/games/[game_name]/` with:
- Menu/setup screen
- Active gameplay screen
- Results/victory screen

### 2. Design Unique Visual Identity

Each game should have its own:
- Custom color palette
- Custom typography
- Unique UI elements and animations
- Theme consistency within the game

### 3. Integrate with Global Systems

**Required integrations:**

```dart
// Import shared systems
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/services/game_announcement_queue_service.dart';
import 'package:dart_games/services/victory_music_service.dart';
import 'package:dart_games/widgets/add_player/add_player.dart';
import 'package:dart_games/widgets/edit_score/edit_score.dart';
import 'package:dart_games/widgets/dartboard_emulator/dartboard_emulator.dart';

// Use global user list
final playerProvider = context.read<PlayerProvider>();
final availablePlayers = playerProvider.allPlayers;

// Use shared Add Player dialog
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.yourGame(),
);
if (player != null) {
  await playerProvider.savePlayer(player);
}

// Use shared Dartboard Emulator components
// (Only appears when NOT connected to physical dartboard)
final DartboardEmulatorController _dartboardEmulatorController = DartboardEmulatorController();
final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey<InteractiveDartboardState>();

// Create game-specific announcement helper
final globalQueue = GameAnnouncementQueueService();
await globalQueue.loadSettings();
final audioQueue = YourGameAnnouncementHelper(globalQueue);

// Track game start time
final startTime = DateTime.now();

// On game completion, update stats for ALL players (winners AND losers)
final gameDuration = DateTime.now().difference(startTime);
for (final playerId in game.playerIds) {
  final isWinner = playerId == game.winnerId;
  await playerProvider.updatePlayerStats(
    playerId,
    won: isWinner,
    gameName: 'Your Game Name',
    gameDuration: gameDuration,  // SAME duration for all players
    dartThrows: game.getTotalDartsThrown(playerId),    // Total darts thrown
    turns: game.getTotalTurns(playerId),                // Total turns taken
    playerCount: game.getPlayerCount(),                 // Total players in game
  );
}

// Play victory music
final musicService = VictoryMusicService();
if (await musicService.hasCustomMusic()) {
  final musicSource = await musicService.getRandomMusicSource();
  // Play music
}
```

### 4. Organize Game Assets

Create a dedicated asset folder for your game following the standard structure:

```bash
# Create asset folders
mkdir -p assets/games/your_game/icons
mkdir -p assets/games/your_game/images
mkdir -p assets/games/your_game/sounds

# Place all game-specific assets in these folders
# - Game icons → assets/games/your_game/icons/
# - Game images → assets/games/your_game/images/
# - Game sounds → assets/games/your_game/sounds/
```

**Update pubspec.yaml:**
```yaml
assets:
  # Shared/common assets
  - assets/common/icons/
  - assets/common/images/

  # Game-specific assets
  - assets/games/carnival_derby/
  - assets/games/target_tag/
  - assets/games/your_game/        # ← Add your game folder
```

**Reference assets in code:**
```dart
// Use full paths to game assets
Image.asset('assets/games/your_game/icons/your_icon.png')
AssetImage('assets/games/your_game/images/background.jpg')

// In sound effects service
static const String _basePath = 'assets/games/your_game/sounds/';
```

See [CLAUDE.md](CLAUDE.md) Asset Organization section for complete guidelines.

### 5. Add Game Card to Home Screen

Update `lib/screens/home_screen.dart` to include navigation to your game.

### 6. Create Configuration Factories

Add factory methods to:
- `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart` for dartboard styling
- `lib/widgets/add_player/add_player_dialog_config.dart` for Add Player dialog styling
- `lib/widgets/edit_score/edit_score_dialog_config.dart` for Edit Score dialog styling (if your game supports dart score editing)
- `lib/widgets/save_game_modal/save_game_modal_config.dart` for Save Game modal styling
- `lib/widgets/resume_game_modal/resume_game_modal_config.dart` for Resume Game modal styling

See existing examples for Carnival Derby, Target Tag, Monster Mash, and Reef Royale.

### 7. Create Tests

Follow existing patterns in `test/screens/games/` to create integration tests:
- User management tests (player selection, stats tracking)
- Game logic tests (scoring, win conditions)
- Announcement tests (game events, audio queue)

All tests must pass before deployment (`flutter test`).

### 8. Update Documentation

Update `CLAUDE.md` with new test counts and game-specific notes.

## Development

### Prerequisites

- Flutter SDK
- Dart SDK (for the backend server)
- Scolia 2 dartboard (for production use)
- Scolia API key (required)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/shuels2/dart-games.git
cd dart_games

# Install dependencies
flutter pub get
cd server && dart pub get && cd ..

# Start the backend server
cd server && dart run bin/server.dart &

# Run non-UI tests (all 1357 tests must pass)
flutter test                  # 1179 Flutter tests
cd server && dart test        # 171 server tests

# Optional: Run UI automation tests (364 tests, requires chromedriver)
# See CLAUDE.md for complete UI testing guide

# Launch in Chrome (web)
flutter run -d chrome

# Launch on tablet
flutter run
```

### Testing Requirements

**All 1357 non-UI tests must pass before any build or deployment.**

```bash
# Flutter tests (1179 tests)
flutter test

# Server tests (178 tests)
cd server && dart test
```

**Flutter Test Coverage (1179 tests):**
- API client tests (49 tests: 5 config, 38 client, 6 voice settings)
- Model tests (98 tests: 40 core, 58 additional)
- Model serialization (74 tests: HorseRace 10, TargetTag 13, MonsterMash 13, ReefRoyale 19, ClockworkQuest 19)
- Provider tests (74 tests: PlayerProvider 44, DartboardProvider 30)
- Provider save/restore (35 tests: 5 games x 7)
- Provider game mechanics (233 tests: HorseRace 50, ClockworkQuest 49, MonsterMash 44, ReefRoyale 45, TargetTag 45)
- Service tests (91 tests: AppSettings 20, VictoryMusic 22, Storage 24, ApiLogger 25)
- Save game service (13 tests)
- Announcement queue models (30 tests)
- Game integration - Carnival Derby (43 tests: 26 user management, 17 announcements)
- Game integration - Target Tag (68 tests: 54 announcements, 14 user management)
- Game integration - Monster Mash (65 tests: 47 game logic, 18 announcements)
- Game integration - Reef Royale (~154 tests: game logic + announcements)
- Game integration - Clockwork Quest (84 tests: 66 game logic, 18 announcements)
- Save/resume integration (20 tests)
- Utility tests (34 tests: DartboardLayout)
- Shared test components (24 tests)
- Widget tests (44 tests: 23 dartboard, 8 save modal, 13 resume modal)

**Server Test Coverage (178 tests):**
- Database & helpers (25 tests)
- Database registry & session middleware (10 tests)
- Model roundtrips (32 tests)
- Migration runner, V1 baseline & V2 failed_stats (29 tests)
- Settings routes (9 tests)
- Dartboard routes (10 tests)
- Player routes (24 tests)
- Saved game routes (13 tests)
- Victory music routes (14 tests)
- Failed stats routes (6 tests)
- Test routes (6 tests)

**Per-Session Database Isolation (UI Tests):**

Flutter bug [#67090](https://github.com/flutter/flutter/issues/67090) causes `flutter drive -d chrome` to spawn two browser instances. Both execute the test code, which previously caused duplicate game saves and other data collisions. To solve this, each browser instance generates a unique session ID and sends it via `X-DB-Session` HTTP header on every request. The server's `DatabaseRegistry` lazily creates isolated SQLite databases per session (stored in `data/sessions/`), routed via `dbSessionMiddleware` using Dart's Zone system. Production traffic (no header) uses the single default database — zero behavior change for non-test usage.

**UI Automation Test Coverage (364 tests, one-test-per-process architecture):**
- Each test runs in its own `flutter drive` process for full isolate-level isolation
- **Sequential runner** (`run_ui_tests.bat`): One game at a time, ~620 minutes. Best for debugging.
- **Parallel runner** (`run_ui_tests_parallel.bat`): All 5 games simultaneously, ~174 minutes (~3.5x faster). Each game gets its own ChromeDriver (ports 4444-4448) and backend server (ports 9001-9005). Requires 16GB+ RAM.
- Per-session database isolation (`X-DB-Session` header) prevents cross-test data pollution
- Target Tag (69 tests): Menu settings, gameplay mechanics, visual validation, add player, results screen, save/resume
- Carnival Derby (40 tests): Menu, gameplay, bust mechanics, skip turn, edit score, results screen, save/resume
- Monster Mash (67 tests): Add player, menu settings, gameplay, buff effects, speed play, edit score, results screen, visual validation, save/resume
- Reef Royale (83 tests): Add player, menu settings, gameplay, coral claiming, edit score, results screen, visual validation, showcase, screenshot, save/resume
- Clockwork Quest (105 tests): Add player, menu settings, gameplay, gear progression, edit score, results screen, save/resume, screenshot
- Requires chromedriver setup - see [CLAUDE.md](CLAUDE.md) for complete UI testing guide

### Cross-Platform Compatibility

All features must work on:
- Web browsers (Chrome, Safari, Firefox, Edge)
- iOS tablets (iPad)
- Android tablets

Use platform-specific code only when necessary with proper conditional imports.

## Game Integration Requirements

Every game in Dart Games **must** integrate with:

1. **Global User Management** - Use `PlayerProvider` for player list and stats
2. **Global Announcement Queue** - Use `GameAnnouncementQueueService` with game-specific helper for all announcements
3. **User Win Tracking** - Call `updatePlayerStats()` for ALL players (winners AND losers) when games complete
4. **Game Timer** - Track duration from start to completion
5. **Victory Music** - Use `VictoryMusicService` for victory celebrations
6. **Save & Resume** - Use `SaveGameService`, `SaveGameModal`, and `ResumeGameModal` for game persistence

**IMPORTANT:** All games must use the global `GameAnnouncementQueueService` (not direct `DartAnnouncerService` calls). Create a game-specific announcement helper that wraps the global queue service.

See the [CLAUDE.md](CLAUDE.md) file for detailed integration requirements and code examples.

## Settings

### System Settings (Options Screen)

- **Announcer** - Configure voice engine, personality, and enabled state
- **Victory Music** - Upload and manage custom victory music files
- **User Management** - Create, edit, and delete player profiles
- **Admin** - Access dartboard emulator and system tools

### Dartboard Setup

The app supports two modes:
1. **Physical Dartboard** - Connect to Scolia 2 via API (requires API key)
2. **Emulator Mode** - Test games without hardware

## Contributing

This is a private project. Contributions and pull requests are not accepted at this time.

**For internal development:**
1. **Run all tests** before committing changes (`flutter test` and `cd server && dart test`)
2. **Maintain cross-platform compatibility** (web and tablet)
3. **Follow integration requirements** when adding games
4. **Update documentation** for new features
5. **Do not modify the dartboard emulator** without explicit approval

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

For questions or issues related to this project, please contact the project maintainer directly.

## Contact

For Scolia API key inquiries, visit [https://scolia.com](https://scolia.com)

## Acknowledgments

Built with Flutter and powered by the Scolia 2 dartboard system.
