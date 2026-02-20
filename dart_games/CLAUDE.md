# Claude Development Guidelines for Dart Games

## Project Overview

**Dart Games is a container app that provides core infrastructure for multiple games.**

The app consists of:
1. **Core Container App** - Handles dartboard connection, global user management, centralized settings
2. **Individual Games** - Built on top of the container (Carnival Derby, Target Tag, etc.)
3. **Shared Systems** - Common services used by all games

Each game has its own unique visual identity while integrating with global systems for user management, announcements, victory music, and dartboard connection.

## Documentation Index

### 📖 Getting Started
- [Documentation Structure](docs/DOCUMENTATION_STRUCTURE.md) - How documentation is organized

### 🏗️ Architecture
- [Container App Structure](docs/architecture/container-app.md) - App structure, project layout, navigation
- [Shared Systems](docs/architecture/shared-systems.md) - 8 global systems (DartboardProvider, PlayerProvider, etc.)
- [Design System](docs/architecture/design-system.md) - Container app colors, typography, patterns

### 👨‍💻 Development Guides
- [Adding New Games](docs/development/adding-games.md) - Complete 18-step guide for creating games
- [Game Integration Requirements](docs/development/game-integration.md) - Required integrations checklist
- [Asset Organization](docs/development/asset-organization.md) - Asset folder structure and naming
- [Announcement System](docs/development/announcement-system.md) - Audio system integration guide
- [Dartboard Emulator](docs/development/dartboard-emulator.md) - Dartboard emulator components
- [Add Player Dialog](docs/development/add-player-dialog.md) - Shared Add Player dialog component
- [Edit Score Dialog](docs/development/edit-score-dialog.md) - Shared Edit Score dialog component
- [Widget Keys](docs/development/widget-keys.md) - Widget key requirements for testing

### 🧪 Testing (349 tests total)
- [Test Overview](docs/testing/test-overview.md) - **272 non-UI + 77 UI tests**
- [Non-UI Tests](docs/testing/non-ui-tests.md) - 272 non-UI tests (MANDATORY before builds)
- [UI Automation](docs/testing/ui-automation.md) - 77 UI tests (~51 minutes, optional)
- [Continuous Animations](docs/testing/continuous-animations.md) - Critical pumpAndSettle() rules
- [Test Maintenance](docs/testing/test-maintenance.md) - Updating tests when features change

### 🚀 Deployment
- [Build Process](docs/deployment/build-process.md) - Mandatory testing requirements, build commands
- [Git Workflow](docs/deployment/git-workflow.md) - Push permissions, commit guidelines

### ⚠️ Critical Rules
- [Dartboard Protection](docs/critical-rules/dartboard-protection.md) - **NEVER modify dartboard without permission**
- [Test Failures](docs/critical-rules/test-failures.md) - **NEVER auto-update tests without user approval**
- [Cross-Platform](docs/critical-rules/cross-platform.md) - Must work on web + tablets

### 🎮 Games
- [Game Template](docs/games/_GAME_TEMPLATE/) - Template for creating new games
- [Carnival Derby](docs/games/carnival-derby/) - Horse racing game (2-8 players)
- [Target Tag](docs/games/target-tag/) - Shield elimination game (2-10 players)

## Quick Reference

### Run All Non-UI Tests (MANDATORY before builds)
```bash
flutter test
```
**Required:** 100% pass rate (272 tests)

### Run UI Automation Tests (Optional)
```bash
# Terminal 1: Start chromedriver
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2: Run all UI tests (77 tests, ~51 minutes)
./run_ui_tests.bat

# Or run specific game
./run_ui_tests.bat target_tag
./run_ui_tests.bat carnival
```

### Run Game-Specific Tests
```bash
flutter test test/screens/games/target_tag/
flutter test test/screens/games/carnival_horse_race/
```

## Current Test Counts

**Total: 349 tests**
- **Non-UI Tests:** 272 tests (100% pass rate MANDATORY)
  - Model tests: 40
  - Provider tests: 44
  - Service tests: 42
  - Integration tests: 83
  - Shared component tests: 24
  - Widget tests: 23

- **UI Automation Tests:** 77 tests (optional, ask before running)
  - Target Tag: 53 tests (~31.5 minutes)
  - Carnival Derby: 24 tests (~12 minutes)

## Critical Reminders

### Before Any Build
✅ Run `flutter test` - ALL 272 non-UI tests MUST pass
✅ Ask user: "Would you like me to run UI automation tests?"
✅ Only proceed with build after tests pass

### Before Pushing to Remote
✅ Ask user for explicit permission
✅ Wait for user approval
✅ Only push after receiving confirmation

### When Tests Fail
❌ NEVER automatically update tests to make them pass
❓ Ask user: Fix application code (A) or update tests (B)?
✅ Wait for user decision before proceeding

### Dartboard Emulator Code
❌ NEVER modify without explicit user permission
❓ If bug suspected, ask user to verify first
✅ Only change after user approval

## Project File Structure

```
dart_games/
├── CLAUDE.md                        # This file - navigation hub
├── docs/                            # All documentation
│   ├── DOCUMENTATION_STRUCTURE.md  # Documentation organization guide
│   ├── architecture/                # Container app architecture (3 files)
│   ├── development/                 # Development guides (8 files)
│   ├── testing/                     # Testing documentation (5 files)
│   ├── deployment/                  # Build and git workflow (2 files)
│   ├── critical-rules/              # Critical rules (3 files)
│   └── games/                       # Game-specific docs
│       ├── _GAME_TEMPLATE/          # Template for new games (8 files)
│       ├── carnival-derby/          # Carnival Derby docs (8 files)
│       └── target-tag/              # Target Tag docs (8 files)
├── lib/                             # Source code
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── services/
│   ├── widgets/
│   └── screens/
│       └── games/
│           ├── carnival_horse_race/
│           └── target_tag/
├── test/                            # Non-UI tests (272 tests)
├── integration_test/                # UI automation tests (77 tests)
└── assets/                          # Game assets
    ├── common/
    └── games/
        ├── carnival_derby/
        └── target_tag/
```

## Platform Support

Dart Games supports:
- ✅ Web browsers (Chrome, Safari, Firefox, Edge)
- ✅ iOS tablets (iPad)
- ✅ Android tablets

All features must work on all platforms. See [Cross-Platform](docs/critical-rules/cross-platform.md).

## Development Tools

### Flutter Commands
```bash
flutter run -d chrome          # Run on web
flutter test                    # Run all non-UI tests
flutter build web               # Build for web
flutter doctor                  # Check Flutter setup
```

### Git Commands
```bash
git status                      # Check status
git add <files>                 # Stage changes
git commit -m "message"         # Commit (with permission)
git push origin <branch>        # Push (with permission)
```

## Getting Help

- **Documentation Structure:** See [DOCUMENTATION_STRUCTURE.md](docs/DOCUMENTATION_STRUCTURE.md)
- **Adding Games:** See [Adding New Games](docs/development/adding-games.md)
- **Testing:** See [Test Overview](docs/testing/test-overview.md)
- **Critical Rules:** See [docs/critical-rules/](docs/critical-rules/)

## Notes

- Original CLAUDE.md (2800 lines) has been reorganized into 46 focused documentation files
- Each topic has its own file for better maintainability and navigation
- Game-specific documentation lives in `docs/games/[game_name]/`
- Shared documentation lives in topic-based folders (architecture, development, testing, etc.)

---

**Last Updated:** 2026-02-20
**Documentation Version:** 2.0 (Topic-Based Structure)
**Total Documentation Files:** 46
