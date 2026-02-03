# Claude Development Guidelines for Dart Games

## App Architecture Overview

### Container App Structure

**Dart Games is a container app that provides core infrastructure for multiple games.**

The app architecture consists of:

1. **Core Container App** (Dart Games)
   - Handles dartboard connection (physical Scolia dartboard or emulator)
   - Manages global user/player system
   - Provides centralized settings (announcer, victory music, user management)
   - Ensures consistent experience across all games

2. **Individual Games** (e.g., Carnival Derby)
   - Built on top of the container app
   - Use shared dartboard connection
   - Integrate with global user management
   - Use centralized announcer and victory music systems
   - Follow consistent design language and UX patterns

### Project Structure

```
dart_games/
├── lib/
│   ├── main.dart                    # App entry point, theme, navigation
│   ├── models/                      # Data models (Player, GameHistoryEntry, etc.)
│   ├── providers/                   # State management (DartboardProvider, PlayerProvider, etc.)
│   ├── services/                    # Shared services (DartAnnouncerService, VictoryMusicService, etc.)
│   ├── widgets/                     # Reusable widgets (dartboard components, status indicators)
│   └── screens/
│       ├── splash_screen.dart       # Initial loading screen
│       ├── dartboard_setup_screen.dart  # Connect to dartboard or emulator
│       ├── home_screen.dart         # Game selection menu
│       ├── options_screen.dart      # System Settings (announcer, music, users, admin)
│       ├── test_dartboard_screen.dart   # Dartboard emulator (admin tool)
│       └── games/
│           └── carnival_horse_race/ # Carnival Derby game
│               ├── horse_race_menu_screen.dart     # Game setup
│               ├── horse_race_game_screen.dart     # Active gameplay
│               └── horse_race_results_screen.dart  # Winner announcement
├── test/                            # Test suite (180 tests)
└── assets/                          # Images, icons, fonts
```

### Key Shared Systems

**1. Dartboard Connection (`DartboardProvider`)**
- Manages connection to physical Scolia dartboard via API
- Provides emulator mode for testing without hardware
- Status tracking (connected, disconnected, connecting)
- Used by all games for dart input

**2. User Management (`PlayerProvider`)**
- Global player list shared across all games
- Player profiles with photos and statistics
- Game history tracking with duration
- Stats aggregation (total wins, play time, average duration)

**3. Announcer System (`DartAnnouncerService`)**
- Voice announcements for game events
- Supports multiple voice engines (Browser Voices, ResponsiveVoice)
- Customizable personality (Professional, Excited, Calm, Funny, Drill Sergeant)
- Used by all games for consistent audio feedback

**4. Victory Music (`VictoryMusicService`)**
- Custom music file management
- Random selection from user's music library
- Plays when a player wins any game
- Cross-platform support (web data URLs, native file paths)

### Design System

**Dart Games Container App Design:**

The design system below applies to the core dart games app screens (splash, home, dartboard setup, system settings, emulator). These screens provide a consistent container experience.

**Theme & Colors:**
- Primary: Flame Orange (#FF6B35)
- Secondary: Tangerine Orange (#F7931E)
- Tertiary: Deep Ocean Blue (#004E89)
- Gradient AppBars: Red (#F44336) to Amber (#FFC107)

**Typography:**
- Font Family: Nunito (Google Fonts)
- Hero Headers: Black (900 weight), 32-40pt, negative letter spacing
- Screen Titles: Bold (700 weight), 24-28pt
- Live Scores: Semi-Bold (600 weight), 28pt+, tabular figures
- Body Text: Regular (400 weight), 16pt, 1.4x line height

**Individual Game Designs:**

Each game can and should have its own unique visual identity to create a distinct experience:
- **Custom color palettes** - Games can use any colors that fit their theme
- **Custom typography** - Games can use different fonts and text styles
- **Unique UI elements** - Games can have custom widgets, animations, and layouts
- **Theme consistency** - Games should maintain their own internal design consistency

**Example: Carnival Derby**
- Uses yellow/amber carnival theme colors
- Has carnival-specific visual elements
- Maintains distinct identity while integrating with shared systems (announcer, victory music, user management)

### Adding New Games

When adding a new game to the dart games app:

1. **Create game screens** in `lib/screens/games/[game_name]/`
2. **Design unique visual identity** - Each game should have its own color palette, typography, and theme to feel distinct
3. **Integrate with global systems** (see Game Integration Requirements section)
4. **Use shared services** (DartboardProvider, PlayerProvider, DartAnnouncerService, VictoryMusicService)
5. **Add game card** to `home_screen.dart` for navigation
6. **Create tests** following existing patterns
7. **Update CLAUDE.md** with new test counts and game-specific notes

## Critical Rules

### Dartboard Emulator Code Protection

**NEVER update the dartboard emulator code without explicit permission from the user.**

The dartboard emulator (`lib/widgets/interactive_dartboard.dart`) is working correctly and has been thoroughly tested. Any changes to this component must be explicitly requested and approved by the user before implementation.

Files that require explicit permission before modification:
- `lib/widgets/interactive_dartboard.dart` - Interactive dartboard widget
- Segment calculation logic
- Ring boundary detection
- Coordinate mapping and scaling

If a bug is suspected in the dartboard emulator, ask the user to verify the issue before making changes.

### Dartboard Emulator Integration in Games

**When integrating InteractiveDartboard widget into game screens, follow this exact structure pattern:**

The dartboard emulator must be structured correctly to ensure clickable areas align with visual elements. Based on successful implementations in Carnival Derby and Target Tag, use this pattern:

```dart
Widget _buildDartboardSection(bool disabled) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: YourGameBackgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      alignment: Alignment.center,  // CRITICAL: Centers dartboard and modal
      children: [
        // Dartboard with optional disable state
        AbsorbPointer(
          absorbing: disabled,
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: InteractiveDartboard(
              key: _dartboardKey,
              size: 250,  // MUST match widgetSize parameter
              onDartThrow: (score, multiplier, baseScore, position) {
                if (_mockApi != null) {
                  _mockApi!.simulateDartThrow(
                    score: score,
                    multiplier: multiplier,
                    playerName: 'Player',
                    baseScore: baseScore,
                    widgetX: position.dx,
                    widgetY: position.dy,
                    widgetSize: 250,  // MUST match size parameter
                  );
                }
              },
              onRemoveDarts: () {
                // Called when dartboard is cleared
              },
            ),
          ),
        ),
        // Modal overlay (if needed)
        if (disabled)
          Container(
            width: 250,  // MUST match dartboard size
            height: 250,
            decoration: BoxDecoration(
              color: YourGameColor.withOpacity(0.9),
              shape: BoxShape.circle,  // Circular overlay
              border: Border.all(
                color: YourGameBorderColor,
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Your modal content here
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
```

**Critical Requirements:**

1. **Stack Alignment** - MUST use `alignment: Alignment.center` on Stack
   - Without this, clickable areas will NOT align with visual dartboard
   - Symptoms: Clicks register wrong segments (e.g., clicking 20 registers as 5)

2. **Direct Stack Children** - Dartboard and modal are direct children of Stack
   - NO Positioned wrappers
   - NO nested Container/SizedBox wrappers
   - This ensures proper coordinate mapping

3. **Consistent Sizing** - All sizes MUST match exactly:
   - InteractiveDartboard `size` parameter
   - simulateDartThrow `widgetSize` parameter
   - Modal overlay width/height
   - All should be 250 (or same value if different)

4. **Simplified Structure** - Avoid over-nesting:
   - Container (padding + decoration) → Stack → Children
   - NO extra layers between Stack and dartboard
   - NO SizedBox wrappers that change dimensions

5. **Modal Shape** - If using circular modal overlay:
   - Use `BoxShape.circle` decoration
   - Match dartboard dimensions exactly (250x250)
   - Center content with Column + MainAxisAlignment.center

**Reference Implementations:**
- Carnival Derby: `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart` (lines 647-760)
- Target Tag: `lib/screens/games/target_tag/target_tag_game_screen.dart` (dartboard section)

**Common Mistakes to Avoid:**
- ❌ Wrapping Stack in SizedBox with different dimensions
- ❌ Using Positioned.fill for modal (breaks alignment)
- ❌ Forgetting `alignment: Alignment.center` on Stack
- ❌ Mismatched size values between dartboard and widgetSize
- ❌ Over-nesting with multiple Containers

### Mandatory Testing Before Any Build

**ALL TESTS MUST PASS BEFORE ANY BUILD OR DEPLOYMENT.**

Before any build, commit, or deployment:

```bash
cd dart_games
flutter test
```

**CRITICAL REQUIREMENTS:**
- All 180 tests must pass (100% pass rate required)
- If ANY test fails, DO NOT proceed with build
- Fix all failing tests first, then re-run test suite
- Only build after confirming all tests pass

**Target Tag Regression Testing:**

ALL 41 Target Tag tests MUST pass before any build to prevent regressions:

```bash
flutter test test/screens/games/target_tag/
```

These tests validate:
- **Game logic AND announcements** (32 tests in `target_tag_game_with_announcements_test.dart`)
  - Solo mode (Tests 1-8): Shield building, tagged-in status, successful tags, low shields, losing tagged-in, victory
  - Team mode (Tests 9-14): Team setup, team tagged-in, team elimination, last team standing
  - Hero bonus (Tests 15-17): Fill to max, attacks while tagged-in, team hero attacks
  - Turn management (Tests 18-19): Skip turns, multiple skips in sequence
  - Edit score (Tests 20-24): Add/remove shields, undo, team adjustments
  - Edge cases (Tests 25-32): Simultaneous events, regaining tagged-in, all bullseyes, 10 players, 5 teams, multiple hero attacks
- **User management integration** (9 tests in `target_tag_user_management_test.dart`)
  - Win tracking for both winners and losers with game duration
  - Stats persistence across app restarts
  - Total play time and average duration calculations

This is NON-NEGOTIABLE. Tests validate critical functionality including:
- User management system (39 tests - Player: 30, Carnival Derby: 8, Target Tag: 9)
- Victory music management (22 tests)
- Announcer settings (20 tests)
- Dartboard emulator accuracy (23 tests)
- Target Tag game logic, announcements, and user management (41 tests)
- Data persistence and serialization
- Cross-platform compatibility
- Game logic and scoring

### Handling Test Failures

**NEVER automatically update tests to make them pass without user approval.**

When tests fail after making code changes:

1. **STOP and analyze the failure**
   - Read the test failure messages carefully
   - Understand what functionality the test is validating
   - Determine if the test is catching a bug in the new code OR if the test is outdated

2. **Ask the user for direction**
   - Present the test failure details to the user
   - Ask: "The tests are failing. Would you like me to:
     - (A) Fix the application code to make the existing tests pass, OR
     - (B) Update the tests to match the new application behavior?"
   - Wait for explicit user choice before proceeding

3. **IMPORTANT: Do not assume tests need updating**
   - Tests often catch real bugs introduced by code changes
   - Automatically updating tests to pass could hide bugs in the application
   - The user knows the intended behavior - let them decide

4. **After user decision**
   - If (A): Fix the application code while preserving test requirements
   - If (B): Update tests AND update CLAUDE.md with new test count/descriptions
   - Re-run `flutter test` to verify 100% pass rate
   - Only then proceed with build/commit

**Example Workflow:**

```
Scenario: After updating player management, 3 tests fail

❌ WRONG approach:
- Automatically modify tests to pass
- Proceed with build

✅ CORRECT approach:
- Analyze the 3 failing tests
- Present to user: "Tests are failing because the new code changes how player names are validated.
  Would you like me to:
  (A) Revert the validation changes to match the test expectations, OR
  (B) Update the tests to accept the new validation logic?"
- Wait for user choice
- Implement the chosen solution
- Re-run tests to verify all pass
```

### Cross-Platform Compatibility

**All features must work on both web and tablet devices (iOS and Android).**

When implementing new features or modifying existing code:
- Ensure compatibility with web browsers (Chrome, Safari, Firefox, Edge)
- Ensure compatibility with iOS tablets (iPad)
- Ensure compatibility with Android tablets
- Use platform-specific code only when necessary, with proper conditional imports
- Test platform-specific features (like file picking, audio playback, storage) on all target platforms
- Use `kIsWeb` checks when web and native platforms require different implementations
- Avoid web-only APIs (like `dart:html`, `dart:js`) in shared code without conditional imports
- Avoid mobile-only APIs in web builds

Common cross-platform considerations:
- File storage: Use IndexedDB for web, file system for native
- Audio playback: Ensure audio formats are supported across all platforms
- File picking: Different APIs for web vs native
- Responsive layouts: Test on different screen sizes and orientations
- Touch vs mouse input: Both should work seamlessly

### Game Integration Requirements

**ALL games in the dart games app MUST integrate with the global systems.**

Every game (such as Target Tag, Carnival Derby, and any future games) must follow these integration requirements:

**IMPORTANT - Game Duration Tracking:**
- **ALL new games MUST track game duration for BOTH winners AND losers**
- This is the current standard pattern (as implemented in Target Tag)
- Older games like Carnival Derby only track winners' duration (legacy behavior)
- When implementing new games, follow the Target Tag pattern shown below

#### 1. Global User Management
- **Use the global user list** (`PlayerProvider`) for available players
- **Add new players to the global list** - when a player is created in any game, they are added to the shared player list
- Players created in one game are immediately available in all other games
- Use `PlayerProvider.savePlayer()` to add new players
- Use `PlayerProvider.allPlayers` to get the list of available players

#### 2. Announcer Integration
- **Use announcer settings from the global dart games announcer settings**
- Use `DartAnnouncerService` singleton for all game announcements
- Respect the user's voice engine selection (Browser Voices or ResponsiveVoice)
- Respect the user's selected announcer personality (Professional, Excited, Calm, Funny, Drill Sergeant)
- Respect the user's voice enabled/disabled setting
- Use `AppSettings` to retrieve and save announcer preferences

#### 3. User Win Tracking and Game Duration
- **Track user wins and game duration for ALL players**
- **CRITICAL**: ALL players (both winners AND losers) MUST receive game duration tracking
- Call `PlayerProvider.updatePlayerStats()` for EVERY player in the game:
  - **For winners:**
    - `playerId` - the ID of the winning player
    - `won: true` - to increment games won
    - `gameName` - the name of the game (e.g., "Target Tag", "Carnival Derby")
    - `gameDuration` - the full game duration from start to finish
  - **For losers:**
    - `playerId` - the ID of the losing player
    - `won: false` - increments games played only
    - `gameName` - the name of the game
    - `gameDuration` - the SAME full game duration as winners
- **Important**: Both winners and losers receive identical `gameDuration` values representing the complete game time
- This enables accurate play time tracking and statistics for all participants

#### 4. Game Timer
- **Every game MUST implement a game timer**
- Track the start time when the game begins (e.g., when "Start Game" button is pressed)
- Track the end time when the game completes (winner determined)
- Calculate duration: `DateTime.now().difference(startTime)`
- Pass the duration to `updatePlayerStats()` for win tracking

#### 5. Victory Music
- **Use the dart games victory music list for victory music**
- Use `VictoryMusicService` singleton to access custom victory music
- Call `VictoryMusicService.getRandomMusicSource()` to get a random music file
- If custom music is available (`hasCustomMusic()` returns true), play it
- Handle both web (data URLs) and native (file paths) music sources
- Provide fallback behavior if no custom music is configured

#### Implementation Example (Target Tag Pattern - REQUIRED for all new games)

```dart
class GameScreen extends StatefulWidget {
  // Game provider with timer
  final GameProvider gameProvider;
  final PlayerProvider playerProvider = PlayerProvider();
  final VictoryMusicService musicService = VictoryMusicService();

  void _startGame() {
    // Start game with timer
    gameProvider.startGame(selectedPlayers, targetScore);
    // gameProvider.currentGame.startedAt is set to DateTime.now()
  }

  void _onGameComplete() async {
    final game = gameProvider.currentGame!;
    final gameDuration = DateTime.now().difference(game.startedAt);

    // Get list of winners (may be multiple in team games)
    final winners = gameProvider.getWinners(playerProvider.allPlayers);
    final winnerIds = winners.map((p) => p.id).toSet();

    // CRITICAL: Update stats for ALL players (winners AND losers)
    // ALL players receive the same game duration
    for (final playerId in game.playerIds) {
      final isWinner = winnerIds.contains(playerId);
      await playerProvider.updatePlayerStats(
        playerId,
        won: isWinner,
        gameName: 'Your Game Name',
        gameDuration: gameDuration,  // ← SAME duration for winners AND losers
      );
    }

    // Play victory music
    if (await musicService.hasCustomMusic()) {
      final musicSource = await musicService.getRandomMusicSource();
      if (musicSource != null) {
        // Play music using appropriate player for web/native
      }
    }
  }
}
```

#### Required Dependencies

Games must import and use:
- `package:dart_games/providers/player_provider.dart` - Global user management
- `package:dart_games/services/dart_announcer_service.dart` - Announcer functionality
- `package:dart_games/services/victory_music_service.dart` - Victory music
- `package:dart_games/services/app_settings.dart` - Settings persistence

#### Testing Requirements

When adding a new game:
1. Create integration tests that verify global system integration
2. Test that players added in the game appear in the global player list
3. **Test that ALL players (winners AND losers) receive game duration tracking**
4. Test that winners have `gamesWon` incremented correctly
5. Test that losers have `gamesPlayed` incremented but `gamesWon` unchanged
6. Test that game timer calculates duration correctly
7. Test that all players in the same game receive identical duration values
8. Test that stats persist across app restarts (SharedPreferences)
9. Follow the pattern established in `test/screens/games/target_tag/target_tag_user_management_test.dart`

**Reference Implementation:**
- See `target_tag_user_management_test.dart` for the complete pattern (9 tests)
- Tests validate both solo and team modes
- Tests verify that losers receive game history with duration (not just winners)

## Testing Requirements

### Complete Test Suite (180 Tests)

The dart games app has a comprehensive test suite covering all critical functionality:

#### Model Tests (36 tests)
- `test/models/game_history_entry_test.dart` (8 tests)
  - Factory constructor creation
  - JSON serialization/deserialization
  - Round-trip serialization
  - Duration format handling
  - Timestamp validation

- `test/models/player_test.dart` (16 tests)
  - Player creation with/without photos
  - Game history serialization
  - Backward compatibility (missing gameHistory field)
  - copyWith() functionality
  - Equality operators and hashCode

- `test/models/victory_music_file_test.dart` (12 tests)
  - Instance creation and field validation
  - JSON serialization/deserialization
  - Round-trip serialization
  - File extensions and formats (mp3, wav, ogg, etc.)
  - Data URL sources (web) and file paths (native)
  - Special characters and long file names

#### Provider Tests (30 tests)
- `test/providers/player_provider_test.dart` (30 tests)
  - Player CRUD operations (save, update, delete)
  - Player selection (up to 8 players)
  - Game stats tracking (games played/won)
  - Game history methods (getPlayerHistory, getPlayerHistoryForGame, etc.)
  - Total play time and average duration calculations
  - Data persistence across provider instances

#### Service Tests (42 tests)
- `test/services/app_settings_test.dart` (20 tests)
  - Google API key storage and retrieval
  - Voice engine preference management
  - Google voice selection
  - Voice enabled state
  - Settings persistence and isolation

- `test/services/victory_music_service_test.dart` (22 tests)
  - Singleton pattern
  - Music file management
  - Random music selection
  - Backward compatibility (deprecated methods)
  - Error handling and data persistence
  - Cross-platform file handling

#### Integration Tests (49 tests)
- `test/screens/games/carnival_horse_race/carnival_derby_user_management_test.dart` (8 tests)
  - Winner recording with game duration
  - Multiple games accumulation
  - Duration calculation accuracy
  - Multi-player game stats (winner vs. losers)
  - Exact score mode duration tracking
  - Stats persistence across app restarts

- `test/screens/games/target_tag/target_tag_game_with_announcements_test.dart` (32 tests)
  - Solo mode game logic and announcements (Tests 1-8)
  - Team mode mechanics and announcements (Tests 9-14)
  - Hero bonus behavior and announcements (Tests 15-17)
  - Turn management and announcements (Tests 18-19)
  - Edit score functionality (Tests 20-24)
  - Edge cases and complex scenarios (Tests 25-32)
  - Validates BOTH game logic (shields, tagged-in status, eliminations) AND announcement text/timing
  - Covers 2-10 players and 2-5 teams

- `test/screens/games/target_tag/target_tag_user_management_test.dart` (9 tests)
  - Solo mode winner/loser stats with duration tracking (Tests 4-7)
  - Team mode stats for all players with duration (Test 8)
  - Mixed team compositions across games (Test 9)
  - 3-team game statistics (Test 10)
  - Total play time calculations (Test 11)
  - Average game duration by game name (Test 12)
  - Both winners AND losers receive game history entries with duration
  - Stats persistence and data integrity validation

#### Widget Tests (23 tests)
- `test/widgets/interactive_dartboard_test.dart` (23 tests)
  - Dartboard rendering and scaling
  - Bulls detection (50 and 25 points)
  - Ring detection (double, triple, single)
  - Segment scoring accuracy across the board
  - Dart position persistence across window resize
  - Dart management (add/remove functionality)

### Running Tests

Run all tests:
```bash
cd dart_games
flutter test
```

Run specific test suites:
```bash
# Model tests
flutter test test/models/

# Provider tests
flutter test test/providers/

# Integration tests
flutter test test/screens/games/carnival_horse_race/

# Widget tests
flutter test test/widgets/
```

### Test Expectations

- **100% pass rate required** - All 180 tests must pass
- Tests validate user management, victory music, announcer settings, dartboard accuracy, game logic, announcements, and data persistence
- No build or deployment without all tests passing
- Tests cover both web and native platform scenarios
- Backward compatibility is validated for data migrations
- Target Tag tests (41 tests total) validate game logic, announcement system integrity, and user management integration

### Maintaining Tests When Features Change

**CRITICAL: When updating features, tests MUST be updated to match.**

Whenever you update a feature of the dart games app or modify one of the games:

1. **Ask the user if they want to update the tests** to match the new functionality
   - Example: "I've updated the player selection feature. Would you like me to update the tests to cover the new functionality?"

2. **If the user says yes:**
   - Update existing tests that are affected by the changes
   - Add new tests to cover the new functionality
   - Ensure all tests pass with the updated code
   - Run `flutter test` to verify 100% pass rate

3. **Update CLAUDE.md with the new test count and requirements:**
   - Update the total test count in the "CRITICAL REQUIREMENTS" section (line 31)
   - Update the test breakdown in the "Complete Test Suite" section
   - Add documentation for any new test files created
   - Update the "Test Expectations" section with the new total

4. **Commit the test updates:**
   - Include test updates in the same commit as the feature changes, OR
   - Create a separate commit specifically for test updates
   - Update CLAUDE.md in the same commit or immediately after

**Important Notes:**
- Never leave tests broken or outdated after a feature update
- If tests need to be temporarily disabled, document why and create a task to fix them
- Test coverage should never decrease - only increase or stay the same
- Breaking changes to features MUST have corresponding test updates

**Example Workflow:**

```
User: "Update the player photo feature to support GIF files"
Claude:
1. Updates the code to support GIF files
2. Asks: "I've updated the player photo feature to support GIF files.
   Would you like me to update the PlayerProvider tests to cover GIF file handling?"
User: "yes"
Claude:
1. Adds tests for GIF file handling to test/providers/player_provider_test.dart
2. Runs flutter test - now 183 tests (was 180)
3. Updates CLAUDE.md:
   - Line 45: "Test suite (183 tests)"
   - Provider Tests section: "player_provider_test.dart (33 tests)" (was 30)
   - Test Expectations: "All 183 tests must pass"
4. Commits changes with updated CLAUDE.md
```

## Git Workflow

### Push Permission Required

**NEVER push to the master branch without explicit permission from the user.**

Before pushing any commits to the remote repository:
1. Ask the user for permission to push
2. Wait for explicit approval
3. Only push after receiving confirmation

This applies to all git operations that modify the remote repository, including:
- `git push origin master`
- `git push`
- Force pushes or any other push commands

## Development Workflow

### Standard Development Process

1. Make code changes (excluding protected dartboard emulator code)
2. **MANDATORY: Run full test suite**
   ```bash
   cd dart_games
   flutter test
   ```
3. **Verify ALL 180 tests pass (100% pass rate required)**
4. If ANY tests fail:
   - DO NOT proceed
   - Investigate and fix the failing tests
   - Re-run the test suite
   - Only continue after all tests pass
5. Commit changes locally (if appropriate)
6. **Ask user for permission before pushing to remote**
7. Wait for explicit user approval
8. Only then proceed with build/deployment

### Build Process

**NEVER build without running tests first.**

Before any `flutter run` or `flutter build` command:
1. Run `flutter test`
2. Confirm all 180 tests pass
3. Only then run the build command

### Quick Reference

✅ **Always run tests before:**
- Committing changes
- Building the app
- Deploying to production
- Creating pull requests
- Pushing to remote

❌ **Never:**
- Build without running tests
- Commit with failing tests
- Push to remote without user permission
- Modify dartboard emulator without permission

## Notes

- The dartboard emulator has been validated to work correctly
- Test results are documented in `TEST_RESULTS.md`
- Any dartboard-related issues should be reported to the user for approval before fixing
