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
- [Adding New Games](docs/development/adding-games.md) - Complete 18-step guide for creating games
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
- [Widget Keys](docs/development/widget-keys.md) - Widget key requirements for testing

### 🧪 Testing (878 tests total)
- [Test Overview](docs/testing/test-overview.md) - **643 non-UI + 235 UI tests**
- [Non-UI Tests](docs/testing/non-ui-tests.md) - 643 non-UI tests (MANDATORY before builds)
- [UI Automation](docs/testing/ui-automation.md) - 235 UI tests (~167 minutes, optional)
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

## Quick Reference

### Run All Non-UI Tests (MANDATORY before builds)
```bash
flutter test
```
**Required:** 100% pass rate (637 tests)

### Run UI Automation Tests (Optional)
```bash
# Terminal 1: Start chromedriver
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2: Run all UI tests (231 tests, ~163 minutes)
./run_ui_tests.bat

# Or run specific game
./run_ui_tests.bat target_tag
./run_ui_tests.bat carnival
./run_ui_tests.bat monster_mash
./run_ui_tests.bat reef_royale
```

### Run Game-Specific Tests
```bash
flutter test test/screens/games/target_tag/
flutter test test/screens/games/carnival_horse_race/
flutter test test/screens/games/monster_mash/
flutter test test/screens/games/reef_royale/
```

## Current Test Counts

**Total: 868 tests**
- **Non-UI Tests:** 643 tests (100% pass rate MANDATORY)
  - Model tests: 40
  - Model serialization tests: 55
  - Provider tests: 44
  - Provider save/restore tests: 28
  - Service tests: 42
  - Save game service tests: 13
  - Integration tests: 163
  - Save/resume integration tests: 20
  - Shared component tests: 24
  - Widget tests: 23
  - Save game modal tests: 8
  - Resume game modal tests: 13
  - Monster Mash announcements: 18
  - Reef Royale game logic + announcements: ~154
  - Carnival Derby game logic: 8 (included in integration above)

- **UI Automation Tests:** 225 tests (optional, ask before running)
  - Target Tag: 62 tests (~48 minutes)
  - Carnival Derby: 33 tests (~22 minutes)
  - Monster Mash: 60 tests (~40 minutes)
  - Reef Royale: 70 tests (~37 minutes)

## Critical Reminders

### Before Any Build
✅ Run `flutter test` - ALL 643 non-UI tests MUST pass
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
├── lib/                             # Source code
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── services/
│   ├── widgets/
│   └── screens/
│       └── games/
│           ├── carnival_horse_race/
│           ├── target_tag/
│           ├── monster_mash/
│           └── reef_royale/
├── test/                            # Non-UI tests (637 tests)
├── integration_test/                # UI automation tests (195 tests)
│   ├── shared/                     # Shared test helpers
│   ├── target_tag/                 # Target Tag UI tests (5 files)
│   ├── carnival_derby/             # Carnival Derby UI tests (1 file)
│   ├── monster_mash/               # Monster Mash UI tests (6 files)
│   └── reef_royale/                # Reef Royale UI tests (8 files)
└── assets/                          # Game assets
    ├── common/
    └── games/
        ├── carnival_derby/
        ├── target_tag/
        ├── monster_mash/
        └── reef_royale/
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

- Original CLAUDE.md (2800 lines) has been reorganized into 65+ focused documentation files
- Each topic has its own file for better maintainability and navigation
- Game-specific documentation lives in `docs/games/[game_name]/`
- Shared documentation lives in topic-based folders (architecture, development, testing, etc.)

---

**Last Updated:** 2026-03-04
**Documentation Version:** 3.1 (Save & Resume)
**Total Documentation Files:** 69
