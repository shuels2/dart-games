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
