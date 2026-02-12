# Dart Games

A Flutter-based container app for multiple dartboard games with global user management, announcer system, and victory music.

## Overview

Dart Games is a modular gaming platform that provides core infrastructure for dartboard-based games. It connects to physical Scolia dartboards or uses emulator mode for offline development and testing (displays a clickable dartboard in games when not connected to physical hardware).

### Current Games

- **Carnival Derby** - Race to the target score in this classic dart scoring game
- **Target Tag** - Strategic elimination game with shields and tagged-in mechanics

## Key Features

### Global Systems

- **Dartboard Connection** - Connect to physical Scolia dartboards via API or use emulator mode for offline development/testing
  - Real mode: Receives dart input from physical Scolia dartboard
  - Emulator mode: Displays visual dartboard in games for manual dart input (testing without hardware)
- **User Management** - Global player profiles shared across all games with statistics tracking
- **Announcer System** - Customizable voice announcements with multiple personalities and sound effects
- **Victory Music** - Custom music library that plays when any player wins
- **Game History** - Track wins, games played, and total play time for all players

### Shared Components

#### In-Game Dartboard Emulator Components

**Purpose:** The in-game dartboard emulator allows offline development and testing when a physical Scolia dartboard is NOT connected.

**When It Appears:**
- ONLY shown when `dartboardProvider.isConnected` is `false` (emulator mode)
- Automatically hidden when connected to a real Scolia dartboard
- Allows developers to test game logic without physical hardware

All games use shared, reusable dartboard emulator UI components located in `lib/widgets/dartboard_emulator/`:

- **DartboardEmulatorController** - Manages show/hide state using Flutter's ChangeNotifier pattern
- **DartboardEmulatorSection** - Dartboard container widget with disabled overlay for "Remove Your Darts" prompts
- **DartboardEmulatorFAB** - Floating action button for toggling dartboard visibility (only visible in emulator mode)
- **Configuration Classes** - Game-specific styling via factory methods

**Benefits:**
- Ensures consistent dartboard behavior across all games during offline testing
- Reduces code duplication (~200 lines eliminated per game)
- Allows game-specific visual styling (colors, fonts, backgrounds)
- Bug fixes in shared component benefit all games automatically
- New games only need to provide configuration objects
- Seamlessly hidden when playing with real dartboard

**Implementation Example:**

```dart
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';

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
        isConnected: dartboardProvider.isConnected, // Auto-hides when connected
        config: DartboardFABConfig.yourGame(),
      ),
      body: Column(
        children: [
          // Your game UI

          // Dartboard emulator only appears when NOT connected to real dartboard
          DartboardEmulatorSection(
            controller: _dartboardEmulatorController,
            isConnected: dartboardProvider.isConnected, // Auto-hides when connected
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

**Customization:**

Add factory methods to `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`:

```dart
factory DartboardSectionConfig.yourGame() {
  return DartboardSectionConfig(
    backgroundColor: YourGameColors.background,
    disabledOverlayBorderColor: YourGameColors.accent,
    removeButtonBackgroundColor: YourGameColors.button,
    removeButtonTextStyle: GoogleFonts.yourFont(fontSize: 16),
  );
}

factory DartboardFABConfig.yourGame() {
  return DartboardFABConfig(
    backgroundColor: YourGameColors.primary,
    textStyle: GoogleFonts.yourFont(fontWeight: FontWeight.bold),
  );
}
```

For complete details, see `CLAUDE.md` - Dartboard Emulator Component Integration section.

## Testing

### Non-UI Tests (219 tests)

Required to pass before every build:

```bash
cd dart_games
flutter test
```

**Test Coverage:**
- Model tests (36 tests) - Player, GameHistoryEntry, VictoryMusicFile
- Provider tests (30 tests) - Player management, CRUD operations, statistics
- Service tests (42 tests) - App settings, victory music management
- Integration tests (75 tests) - Carnival Derby and Target Tag game logic with announcements
- Widget tests (36 tests) - InteractiveDartboard accuracy and behavior

**Execution Time:** ~7 seconds

### UI Automation Tests (76 tests)

Optional for builds - comprehensive end-to-end testing in Chrome browser:

**Prerequisites:**
1. ChromeDriver installed at `dart_games/chromedriver/chromedriver-win64/chromedriver.exe`
2. ChromeDriver running on port 4444

**Running UI Tests:**

```bash
# Terminal 1: Start ChromeDriver
cd dart_games/chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2: Run UI automation tests
cd dart_games

# Target Tag tests (52 tests, ~31.5 minutes)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_menu_and_mechanics_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_visual_validation_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_gameplay_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_add_player_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_results_screen_test.dart -d chrome

# Carnival Derby tests (24 tests, ~12 minutes)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/carnival_derby_ui_test.dart -d chrome
```

**UI Test Coverage:**
- **Target Tag** (52 tests)
  - Menu settings and validations
  - Team mode (max 5 teams)
  - Visual validation (player tiles, badges, borders, glow effects)
  - Gameplay mechanics (hero bonus, opponent targeting)
  - Edit score and skip turn functionality
  - Results screen behavior

- **Carnival Derby** (24 tests)
  - Player selection and target score settings
  - Normal and Perfect Finish game modes
  - Bust mechanics and scoring
  - Skip turn and edit score functionality
  - Multi-player races and edge cases
  - Results screen verification

**Total UI Test Execution Time:** ~43 minutes

**Important Notes:**
- UI tests use `flutter drive` (not `flutter test`)
- Tests interact with the actual running app in Chrome
- Must avoid `pumpAndSettle()` on screens with continuous animations
- See `CLAUDE.md` - UI Automation Testing Guidelines for detailed patterns

## Development

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK
- Chrome browser (for web testing)
- ChromeDriver (for UI automation tests)

### Project Structure

```
dart_games/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   ├── providers/                   # State management
│   ├── services/                    # Shared services
│   ├── widgets/
│   │   ├── dartboard_emulator/      # Shared dartboard emulator components
│   │   ├── interactive_dartboard.dart  # Core dartboard widget
│   │   └── ...                      # Other reusable widgets
│   └── screens/
│       ├── splash_screen.dart
│       ├── home_screen.dart
│       ├── options_screen.dart
│       └── games/
│           ├── carnival_horse_race/
│           └── target_tag/
├── test/                            # Non-UI test suite (219 tests)
├── integration_test/                # UI automation tests (76 tests)
└── assets/                          # Images, icons, sounds
```

### Running the App

```bash
# Run on web
flutter run -d chrome

# Run on iOS (requires macOS)
flutter run -d ios

# Run on Android
flutter run -d android
```

### Building

```bash
# Web build
flutter build web

# iOS build
flutter build ios

# Android build
flutter build apk
```

### Adding a New Game

1. Create game screens in `lib/screens/games/[game_name]/`
2. Design unique visual identity (colors, fonts, theme)
3. Integrate with global systems:
   - `DartboardProvider` for dartboard connection
   - `PlayerProvider` for user management
   - `GameAnnouncementQueueService` for announcements
   - `VictoryMusicService` for victory music
   - Use shared `DartboardEmulator` components
4. Add game card to `home_screen.dart`
5. Create configuration factories in `dartboard_emulator_config.dart`
6. Create tests following existing patterns
7. Update `CLAUDE.md` with new test counts

See `CLAUDE.md` for complete integration requirements and patterns.

## Documentation

- **CLAUDE.md** - Comprehensive developer guidelines, architecture, testing requirements
- **test/README.md** - Dartboard widget test documentation
- Integration test documentation embedded in test files

## Platform Support

- Web (Chrome, Safari, Firefox, Edge)
- iOS tablets (iPad)
- Android tablets

## License

Copyright © 2024-2025 Sue Huelsmann. All rights reserved.

This software and associated documentation files (the "Software") are proprietary and confidential.

**Restrictions:**
- No copying, modification, distribution, or use without explicit written permission
- Commercial use prohibited without license agreement
- Educational use limited to personal learning purposes
- Contributions and pull requests are not accepted

For licensing inquiries, contact the copyright holder.

## Contributing

This is a private project. Contributions and pull requests are not accepted at this time.

## Support

For questions or issues related to this project, please contact the project maintainer directly.
