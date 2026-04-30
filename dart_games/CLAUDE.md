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
- [Shared Systems](docs/architecture/shared-systems.md) - 12 global systems (DartboardProvider, PlayerProvider, etc.)
- [Design System](docs/architecture/design-system.md) - Container app colors, typography, patterns

### 👨‍💻 Development Guides
- [Adding New Games](docs/development/adding-games.md) - Complete 19-step guide for creating games
- [Game Integration Requirements](docs/development/game-integration.md) - Required integrations checklist
- [Asset Organization](docs/development/asset-organization.md) - Asset folder structure and naming
- [Announcement System](docs/development/announcement-system.md) - Audio system integration guide
- [Dartboard Emulator](docs/development/dartboard-emulator.md) - Dartboard emulator components
- [Add Player Dialog](docs/development/add-player-dialog.md) - Shared Add Player dialog component
- [Edit Score Dialog](docs/development/edit-score-dialog.md) - Shared Edit Score dialog component
- [Dartboard Connection Info](docs/development/dartboard-connection-info.md) - Shared dartboard connection info component
- [Remove Darts Modal](docs/development/remove-darts-modal.md) - Shared remove darts modal component
- [Dartboard Paused Modal](docs/development/dartboard-paused-modal.md) - Shared dartboard paused modal component
- [Resume Game Button](docs/development/resume-game-button.md) - Shared resume game button component
- [Save & Resume Game](docs/development/save-resume-game.md) - Save and resume game feature
- [Player List Panel](docs/development/player-list-panel.md) - Shared player list panel component
- [Data Migrations](docs/development/data-migrations.md) - Server-side SQLite schema migration system
- [Widget Keys](docs/development/widget-keys.md) - Widget key requirements for testing

### 🧪 Testing (1721 tests total)
- [Test Overview](docs/testing/test-overview.md) - **1179 Flutter + 178 server + 364 UI tests**
- [Non-UI Tests](docs/testing/non-ui-tests.md) - 1357 non-UI tests (MANDATORY before builds)
- [UI Automation](docs/testing/ui-automation.md) - 366 UI tests (~507 minutes sequential / ~143 minutes parallel, optional)
- [Continuous Animations](docs/testing/continuous-animations.md) - Critical pumpAndSettle() rules
- [Test Maintenance](docs/testing/test-maintenance.md) - Updating tests when features change
- [Spec Coverage Audit](docs/testing/spec-coverage-audit.md) - Mandatory audit for 100% spec coverage

### 🚀 Deployment
- [Build Process](docs/deployment/build-process.md) - Mandatory testing requirements, build commands
- [Git Workflow](docs/deployment/git-workflow.md) - Push permissions, commit guidelines

### ⚠️ Critical Rules
- [Dartboard Protection](docs/critical-rules/dartboard-protection.md) - **NEVER modify dartboard without permission**
- [Test Failures](docs/critical-rules/test-failures.md) - **NEVER auto-update tests without user approval**
- [Cross-Platform](docs/critical-rules/cross-platform.md) - Must work on web + tablets
- [Visual Validation](docs/critical-rules/visual-validation.md) - **NEVER skip visual validation or completion gates**

### 🎮 Games
- [Game Template](docs/games/_GAME_TEMPLATE/) - Template for creating new games
- [Carnival Derby](docs/games/carnival-derby/) - Horse racing game (2-8 players)
- [Target Tag](docs/games/target-tag/) - Shield elimination game (2-10 players)
- [Monster Mash](docs/games/monster-mash/) - Monster battle game (2-8 players)
- [Reef Royale](docs/games/reef-royale/) - Coral claiming game (2-8 players)
- [Clockwork Quest](docs/games/clockwork-quest/) - Steampunk gear progression game (2-8 players)

## Quick Reference

### Run All Non-UI Tests (MANDATORY before builds)
```bash
# Flutter tests (1179 tests)
flutter test

# Server tests (178 tests)
cd server && dart test
```
**Required:** 100% pass rate (1357 tests total)

### Run UI Automation Tests (Optional)
```bash
# Sequential runner (all infrastructure managed automatically)
./run_ui_tests.bat                          # All tests (~507 min, interactive Chrome)
./run_ui_tests.bat target_tag               # Specific game
./run_ui_tests.bat carnival
./run_ui_tests.bat monster_mash
./run_ui_tests.bat reef_royale
./run_ui_tests.bat clockwork_quest

# Parallel runner (~3.5x faster, 5 games simultaneously, ~143 min, fully headless)
./run_ui_tests_parallel.bat                          # All games
./run_ui_tests_parallel.bat target_tag monster_mash  # Specific games
./run_ui_tests_parallel.bat save_resume              # Filter by test type
./run_ui_tests_parallel.bat reef_royale/gameplay     # Game + subfolder
```

### Run Game-Specific Tests
```bash
flutter test test/screens/games/target_tag/
flutter test test/screens/games/carnival_horse_race/
flutter test test/screens/games/monster_mash/
flutter test test/screens/games/reef_royale/
flutter test test/screens/games/clockwork_quest/
```

## Current Test Counts

**Total: 1723 tests**
- **Flutter Non-UI Tests:** 1179 tests (100% pass rate MANDATORY)
  - API client tests: 49 (5 config + 38 client + 6 voice settings)
  - Model tests: 98 (40 core + 58 additional)
  - Model serialization tests: 74 (HorseRace 10 + TargetTag 13 + MonsterMash 13 + ReefRoyale 19 + ClockworkQuest 19)
  - Provider tests: 74 (PlayerProvider 44 + DartboardProvider 30)
  - Provider save/restore tests: 35 (5 games x 7)
  - Provider game mechanics tests: 233 (HorseRace 50 + ClockworkQuest 49 + MonsterMash 44 + ReefRoyale 45 + TargetTag 45)
  - Service tests: 91 (AppSettings 20 + VictoryMusicService 22 + StorageService 24 + ApiLoggerService 25)
  - Save game service tests: 13
  - Announcement queue model tests: 30
  - Integration tests: 163
  - Save/resume integration tests: 20
  - Shared component tests: 24
  - Utility tests: 34 (DartboardLayout)
  - Widget tests: 44 (23 dartboard + 8 save modal + 13 resume modal)
  - Monster Mash announcements: 18
  - Reef Royale game logic + announcements: ~154
  - Clockwork Quest game logic + announcements: 84 (66 game logic + 18 announcements)
  - Carnival Derby game logic: 8 (included in integration above)

- **Server Tests:** 178 tests (100% pass rate MANDATORY)
  - Database & helpers: 25
  - Database registry & middleware: 10
  - Model roundtrips: 32
  - Migration runner, V1 baseline & V2 failed_stats: 29
  - Settings routes: 9
  - Dartboard routes: 10
  - Player routes: 24
  - Saved game routes: 13
  - Victory music routes: 14
  - Failed stats routes: 6
  - Test routes: 6

- **UI Automation Tests:** 366 tests (optional, ask before running)
  - Target Tag: 69 tests (~101 minutes)
  - Carnival Derby: 40 tests (~56 minutes)
  - Monster Mash: 67 tests (~93 minutes)
  - Reef Royale: 83 tests (~114 minutes)
  - Clockwork Quest: 107 tests (~143 minutes) [91 functional + 16 save/resume]
  - **Sequential (`run_ui_tests.bat`): ~507 minutes (~8h 27m) — interactive Chrome sessions**
  - **Parallel (`run_ui_tests_parallel.bat`): ~143 minutes (~2h 23m) — fully headless, no visible Chrome**

## Critical Reminders

### Before Any Build
✅ Run `flutter test` - ALL 1179 Flutter non-UI tests MUST pass
✅ Run `cd server && dart test` - ALL 178 server tests MUST pass
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

### Test Helper Synchronization
❌ NEVER modify files in `test/shared/` or `integration_test/shared/` without updating BOTH locations
✅ When changing any shared test helper, apply the same changes to both folders
✅ Verify both non-UI tests (`flutter test`) and UI tests pass after changes
📖 See [Test Maintenance](docs/testing/test-maintenance.md) for synchronization rules

### Dartboard Emulator Code
❌ NEVER modify without explicit user permission
❓ If bug suspected, ask user to verify first
✅ Only change after user approval

### New Game Completion Gates
❌ NEVER mark a game as complete or skip to documentation without completing ALL of the following:
1. **Spec coverage audit** — Cross-reference EVERY option from spec Section 7 and EVERY visual element from Section 10 against actual test files. For each option/element, verify there is at least one non-UI test AND one UI test that exercises it. List any gaps, write missing tests, and re-verify. See [Spec Coverage Audit](docs/testing/spec-coverage-audit.md) for the full procedure.
2. **Screenshot tests** — Run screenshot tests, evaluate EVERY screenshot against the spec's visual checklist, fix issues, re-run until zero issues
3. **UI automation tests** — Run ALL UI tests for the new game, fix failures, re-run until 100% pass
4. **Non-UI tests** — Run `flutter test`, fix any regressions, re-run until 100% pass
5. **Simultaneous pass** — ALL four (spec audit clean + screenshots clean + UI tests pass + non-UI tests pass) must be true AT THE SAME TIME before proceeding
6. **Spec Definition of Done** — Every item in the spec's Definition of Done checklist verified and reported to user

❌ NEVER rationalize skipping any gate (e.g., "it requires manual setup", "it seems like a visual-only step", "the tests were already written")
❌ NEVER move to documentation or mark phases complete until all gates pass simultaneously
❌ NEVER assume existing tests cover all spec options — always run the spec coverage audit
✅ If a gate cannot be run (e.g., chromedriver not available), STOP and ask the user — do NOT skip it

### Visual Validation Workflow (MANDATORY — Do Not Skip Any Step)
Capturing screenshots is NOT the same as validating them. A passing test only means screenshots were saved without errors. The actual validation is the evaluation. Follow this exact workflow every time:

**Step 1: Capture** — Run the screenshot test. Confirm all screenshots saved to `temp_screenshots/`.
**Step 2: Evaluate EVERY screenshot** — Read EVERY screenshot image with the Read tool. For EACH one, check EVERY item on the spec's visual evaluation checklist (Section 12C):
  - Layout & Spacing (no scrolling, no clipping, alignment, no overflow, screen utilization)
  - Typography & Consistency (font sizes match across screens, legibility, contrast)
  - Visual Quality (color harmony, completeness, option effects visible, family-friendly scale)
  - Correctness (characters vs avatars, usability, button sizes)
**Step 3: Report findings** — List every issue found with screenshot number, severity, and description. Present the full report to the user.
**Step 4: Fix** — Fix all issues identified in the evaluation.
**Step 5: Re-capture** — Run the screenshot test again to get fresh screenshots with fixes applied.
**Step 6: Re-evaluate ALL screenshots** — Read and evaluate EVERY screenshot again (not just the ones that were fixed — fixes can affect other screens). Repeat from Step 3 until zero issues remain.

❌ NEVER treat "screenshot test passed" as "visual validation complete" — passing only means captures succeeded
❌ NEVER skip the evaluation step after capturing or re-capturing screenshots
❌ NEVER evaluate only the screenshots you expect changed — evaluate ALL of them every time
❌ NEVER move on after fixing issues without re-capturing AND re-evaluating

### Screenshot Test Technical Rules
These rules prevent common debugging traps. Follow them EXACTLY:
- ✅ Use `test_driver/screenshot_test.dart` as the driver (has `onScreenshot` callback)
- ❌ NEVER use `test_driver/integration_test.dart` for screenshot tests (will hang silently on `takeScreenshot()`)
- ❌ NEVER use `--no-headless` flag — follow `run_ui_tests.bat` pattern
- ❌ NEVER use `pumpAndSettle()` in integration tests — splash screen `CircularProgressIndicator` prevents settling
- ❌ NEVER kill all `chrome.exe` processes — only kill `chromedriver.exe` (killing Chrome causes crash recovery state)
- ✅ Restart chromedriver before each test run
- ✅ Reference `run_ui_tests.bat` for the established launch pattern
- ✅ See [UI Automation](docs/testing/ui-automation.md) for full details

## New Game Development

When implementing any game from `docs/research/games/`, the game's spec file is the source of truth. Before starting: read the full spec, especially Sections 7 (Options), 10 (Screen Designs), and 13 (Agent Team). After each development phase: cross-reference what was built against the spec's Section 7 options table — every option listed must have a visible, working effect on the game screen. Before marking complete: verify every item in the spec's Definition of Done checklist and report the results to the user.

**MANDATORY: Spec coverage audit, visual validation, and UI test verification are NON-NEGOTIABLE steps.** They MUST be actually executed — not skipped, not deferred, not marked as done without running. See "New Game Completion Gates" above. A game is NOT done until the spec coverage audit shows 100% coverage, screenshots have been captured and evaluated, UI tests have been run and pass, and non-UI tests pass — all simultaneously.

## Project File Structure

```
dart_games/
├── CLAUDE.md                        # This file - navigation hub
├── docs/                            # All documentation
│   ├── DOCUMENTATION_STRUCTURE.md  # Documentation organization guide
│   ├── architecture/                # Container app architecture (3 files)
│   ├── development/                 # Development guides (12 files)
│   ├── testing/                     # Testing documentation (6 files)
│   ├── deployment/                  # Build and git workflow (2 files)
│   ├── critical-rules/              # Critical rules (3 files)
│   └── games/                       # Game-specific docs
│       ├── _GAME_TEMPLATE/          # Template for new games (8 files)
│       ├── carnival-derby/          # Carnival Derby docs (8 files)
│       ├── target-tag/              # Target Tag docs (8 files)
│       ├── monster-mash/            # Monster Mash docs (8 files)
│       └── reef-royale/            # Reef Royale docs (8 files)
├── server/                          # Dart Shelf backend server
│   ├── bin/server.dart             # Entry point
│   ├── lib/
│   │   ├── database/               # SQLite database layer, migrations, per-session DB registry
│   │   ├── models/                 # Server-side models
│   │   ├── routes/                 # REST API route handlers
│   │   └── middleware/             # CORS and logging middleware
│   └── test/                       # Server tests (178 tests)
│       └── routes/                 # Route-level tests
├── lib/                             # Flutter source code
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── services/
│   │   └── api/                    # API client layer (ApiClient, ApiConfig)
│   ├── widgets/
│   └── screens/
│       └── games/
│           ├── carnival_horse_race/
│           ├── target_tag/
│           ├── monster_mash/
│           ├── reef_royale/
│           └── clockwork_quest/
├── test/                            # Flutter non-UI tests (1179 tests)
│   ├── shared/                     # Shared test helpers (MockApiServer, etc.)
│   ├── services/api/               # API client tests
│   └── ...
├── integration_test/                # UI automation tests (364 tests)
│   ├── shared/                     # Shared test helpers
│   ├── target_tag/                 # Target Tag UI tests
│   ├── carnival_derby/             # Carnival Derby UI tests
│   ├── monster_mash/               # Monster Mash UI tests
│   ├── reef_royale/                # Reef Royale UI tests
│   └── clockwork_quest/            # Clockwork Quest UI tests
└── assets/                          # Game assets
    ├── common/
    └── games/
        ├── carnival_derby/
        ├── target_tag/
        ├── monster_mash/
        ├── reef_royale/
        └── clockwork_quest/
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
flutter test                    # Run all Flutter non-UI tests
flutter build web               # Build for web
flutter doctor                  # Check Flutter setup
```

### Server Commands
```bash
cd server && dart run bin/server.dart  # Start server (default port 8080)
cd server && dart test                  # Run all server tests
cd server && dart run bin/server.dart --port 9090  # Custom port
cd server && dart run bin/server.dart --data-dir /path/to/data  # Custom data dir
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

- Original CLAUDE.md (2800 lines) has been reorganized into 65+ focused documentation files
- Each topic has its own file for better maintainability and navigation
- Game-specific documentation lives in `docs/games/[game_name]/`
- Shared documentation lives in topic-based folders (architecture, development, testing, etc.)

---

**Last Updated:** 2026-04-15
**Documentation Version:** 4.2 (Server-Side Migrations)
**Total Documentation Files:** 77
