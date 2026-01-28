# Claude Development Guidelines for Dart Games

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

### Mandatory Testing Before Any Build

**ALL TESTS MUST PASS BEFORE ANY BUILD OR DEPLOYMENT.**

Before any build, commit, or deployment:

```bash
cd dart_games
flutter test
```

**CRITICAL REQUIREMENTS:**
- All 139 tests must pass (100% pass rate required)
- If ANY test fails, DO NOT proceed with build
- Fix all failing tests first, then re-run test suite
- Only build after confirming all tests pass

This is NON-NEGOTIABLE. Tests validate critical functionality including:
- User management system (62 tests)
- Victory music management (46 tests)
- Announcer settings (20 tests)
- Dartboard emulator accuracy (23 tests)
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

Every game (such as Carnival Derby and any future games) must follow these integration requirements:

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

#### 3. User Win Tracking
- **Track user wins to the global user management system**
- When a player wins a game, call `PlayerProvider.updatePlayerStats()` with:
  - `playerId` - the ID of the winning player
  - `won: true` - to increment games won
  - `gameName` - the name of the game (e.g., "Carnival Derby")
  - `gameDuration` - the duration of the game
- Losers should also have stats updated with `won: false` (increments games played only)

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

#### Implementation Example (Carnival Derby Pattern)

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

    // Update stats for all players
    for (final playerId in game.playerIds) {
      final isWinner = playerId == game.winnerId;
      await playerProvider.updatePlayerStats(
        playerId,
        won: isWinner,
        gameName: 'Your Game Name',
        gameDuration: isWinner ? gameDuration : null,
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
3. Test that wins are tracked with duration to the global system
4. Test that game timer calculates duration correctly
5. Follow the pattern established in `test/screens/games/carnival_horse_race/carnival_derby_user_management_test.dart`

## Testing Requirements

### Complete Test Suite (139 Tests)

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

#### Integration Tests (8 tests)
- `test/screens/games/carnival_horse_race/carnival_derby_user_management_test.dart` (8 tests)
  - Winner recording with game duration
  - Multiple games accumulation
  - Duration calculation accuracy
  - Multi-player game stats (winner vs. losers)
  - Exact score mode duration tracking
  - Stats persistence across app restarts

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

- **100% pass rate required** - All 139 tests must pass
- Tests validate user management, victory music, announcer settings, dartboard accuracy, game logic, and data persistence
- No build or deployment without all tests passing
- Tests cover both web and native platform scenarios
- Backward compatibility is validated for data migrations

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
2. Runs flutter test - now 142 tests (was 139)
3. Updates CLAUDE.md:
   - Line 31: "All 142 tests must pass"
   - Provider Tests section: "player_provider_test.dart (33 tests)" (was 30)
   - Test Expectations: "All 142 tests must pass"
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
3. **Verify ALL 139 tests pass (100% pass rate required)**
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
2. Confirm all 85 tests pass
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
