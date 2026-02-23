# Dart Games

A Flutter-based container app for interactive dartboard games powered by the Scolia 2 dartboard system.

> **⚠️ Important:** This app requires a **Scolia 2 dartboard** and a valid **Scolia API key** to function. You must contact [Scolia](https://scolia.com) to obtain an API key before using this application.

## Overview

Dart Games is a cross-platform (web and tablet) application that provides a framework for building interactive dartboard games. The app handles dartboard connectivity, user management, and common game features, allowing developers to focus on creating unique game experiences.

### Current Games

- **Carnival Derby** - A horse race-style game where players advance by scoring points with darts
- **Monster Mash** - A monster-themed battle game where players attack opponents and heal themselves using target numbers
- **Target Tag** - A strategic elimination game where players build shields and tag opponents to win

## Features

### Core Infrastructure

- **Dartboard Integration** - Seamless connection to Scolia 2 physical dartboards via API
- **Emulator Mode** - Test games without physical hardware using the built-in dartboard emulator
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
- Custom music file management
- Random selection from user's music library
- Cross-platform support (web data URLs, native file paths)

```dart
// Access victory music service
final musicService = VictoryMusicService();

// Check if custom music is available
if (await musicService.hasCustomMusic()) {
  final musicSource = await musicService.getRandomMusicSource();
  // Play music using appropriate player
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

## Architecture

### Container App Structure

Dart Games uses a container app architecture:

```
dart_games/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   ├── providers/                   # State management
│   ├── services/                    # Shared services
│   ├── widgets/                     # Reusable widgets
│   └── screens/
│       ├── splash_screen.dart       # Initial loading
│       ├── dartboard_setup_screen.dart
│       ├── home_screen.dart         # Game selection
│       ├── options_screen.dart      # System settings
│       └── games/
│           ├── carnival_horse_race/ # Carnival Derby game
│           ├── monster_mash/        # Monster Mash game
│           └── target_tag/          # Target Tag game
├── test/                            # Non-UI test suite (352 tests)
├── integration_test/                # UI automation tests (128 tests)
└── assets/
    ├── common/                      # Shared assets (logo, app icon)
    │   ├── icons/
    │   └── images/
    └── games/                       # Game-specific assets
        ├── carnival_derby/          # Carnival Derby assets
        │   ├── icons/
        │   ├── images/
        │   └── sounds/
        ├── monster_mash/            # Monster Mash assets
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

See existing examples for Carnival Derby and Target Tag.

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
- Scolia 2 dartboard (for production use)
- Scolia API key (required)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/shuels2/dart-games.git
cd dart_games

# Install dependencies
flutter pub get

# Run non-UI tests (all 352 tests must pass)
flutter test

# Optional: Run UI automation tests (128 tests, ~86 minutes, requires chromedriver)
# See CLAUDE.md for complete UI testing guide

# Launch in Chrome (web)
flutter run -d chrome

# Launch on tablet
flutter run
```

### Testing Requirements

**All 352 non-UI tests must pass before any build or deployment.**

```bash
flutter test
```

**Non-UI Test Coverage (352 tests):**
- Model serialization (40 tests)
- Provider functionality (44 tests)
- Service integration (42 tests)
- Game integration - Carnival Derby (43 tests: 26 user management, 17 announcements)
- Game integration - Target Tag (68 tests: 54 announcements, 14 user management)
- Game integration - Monster Mash (65 tests: 47 game logic, 18 announcements)
- Shared test components (24 tests)
- Widget tests (23 tests)

**UI Automation Test Coverage (128 tests, ~86 minutes):**

| # | Test File | Tests | Duration |
|---|-----------|-------|----------|
| 1 | target_tag_menu_and_mechanics_test.dart | 24 | ~16 min |
| 2 | target_tag_visual_validation_test.dart | 4 | ~5 min |
| 3 | target_tag_gameplay_test.dart | 13 | ~9 min |
| 4 | target_tag_add_player_test.dart | 6 | ~3 min |
| 5 | target_tag_results_screen_test.dart | 6 | ~7 min |
| 6 | carnival_derby_ui_test.dart | 24 | ~14 min |
| 7 | monster_mash_add_player_test.dart | 6 | ~3 min |
| 8 | monster_mash_menu_and_settings_test.dart | 8 | ~4 min |
| 9 | monster_mash_gameplay_test.dart | 20 | ~11 min |
| 10 | monster_mash_edit_score_test.dart | 5 | ~4 min |
| 11 | monster_mash_results_screen_test.dart | 6 | ~5 min |
| 12 | monster_mash_visual_validation_test.dart | 6 | ~5 min |

- Target Tag (53 tests, ~40 min): Menu settings, gameplay mechanics, visual validation, add player, results screen
- Carnival Derby (24 tests, ~14 min): Menu, gameplay, bust mechanics, skip turn, edit score, results screen
- Monster Mash (51 tests, ~32 min): Add player, menu settings, gameplay, buff effects, speed play, edit score, results screen, visual validation
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
1. **Run all tests** before committing changes (`flutter test`)
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
