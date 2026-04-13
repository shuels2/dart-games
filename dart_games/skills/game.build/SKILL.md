---
name: game.build
description: Automates the full game creation pipeline from a research spec file. Follows ALL project rules, enforces completion gates, and includes adversarial reviews. Input is the path to a game research spec MD file.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, TaskCreate, TaskUpdate, TaskList, TaskGet
---

You are building a complete new game for the Dart Games Flutter app from a research spec file. You must follow EVERY rule, EVERY step, and EVERY gate defined in the project documentation. Nothing may be skipped, deferred, or rationalized away.

## Input

The user provides a path to a game research spec MD file:
```
/game.build docs/research/games/tier1/candy-cascade.md
```

If no argument is provided, ask the user for the spec file path.

$ARGUMENTS

---

# PIPELINE: 10 Phases, 5 Hard Gates, 7 Adversarial Reviews

You MUST execute phases in order. You MUST NOT skip phases. You MUST NOT proceed past a gate until it passes. You MUST execute every adversarial review checkpoint and report the findings before continuing.

At the start of each phase, print:
```
=== Phase X/9: [Phase Name] ===
Gates passed: X/5 | ARs completed: X/7
```

---

## Phase 0: Initialization and Spec Analysis

**Goal:** Load the spec, extract all requirements, present the build plan, get user approval.

### Steps

1. Read the full spec file from the provided path.
2. Read `CLAUDE.md` to load all current project rules and test counts.
3. Read `docs/development/adding-games.md` for the 19-step checklist.
4. Read `docs/development/game-integration.md` for the integration checklist.
5. Read `docs/critical-rules/visual-validation.md` for the visual validation rules.
6. Read `docs/testing/spec-coverage-audit.md` for the audit procedure.
7. Extract from the spec:
   - **Section 1:** Game name, player count, player list pattern (Dual vs Team).
   - **Section 2:** Color palette, fonts, style.
   - **Section 4:** Full asset checklist (images, sounds, file paths).
   - **Section 7:** Options table — every option, default, values, and expected game screen effect.
   - **Section 9:** Announcement events table.
   - **Section 10:** Screen designs (Menu, Game, Results) — all widget keys, shared widgets, layout.
   - **Section 11:** New config factory methods needed.
   - **Section 12:** Testing plan — all non-UI tests, all UI tests, visual validation checklist.
   - **Section 13:** Agent team responsibilities.
   - **Section 14:** Definition of Done checklist (every item).
   - **Section 15:** Development workflow and branch strategy.
   - **Section 18:** Files summary — all new files and all existing files to modify.
8. Create tasks for each phase using TaskCreate.
9. Present the build plan to the user:
   - Game name and theme
   - Number of new files to create, existing files to modify
   - Number of assets expected
   - Number of non-UI and UI tests planned
   - Number of config factory methods needed
   - Branch name to use
10. Ask the user: "Shall I proceed? Confirm the spec file and branch name are correct."

### USER APPROVAL GATE

**STOP and wait for user confirmation before proceeding.** Do not begin Phase 1 until the user explicitly approves.

---

## Phase 1: Asset Setup

**Goal:** Verify all game assets are in place, update pubspec.yaml.

### Steps

1. Check whether the development branch already exists. If not, create it per the spec's Section 15 (e.g., `[game-name]-dev`).
2. Verify the asset folder structure exists: `assets/games/[game_name]/` with subdirectories for icons, images, characters, sounds per the spec's Section 4.
3. For each asset listed in Section 4, verify the file exists at the expected path.
4. If any assets are missing, report which ones to the user with their expected paths and **STOP**. The user must provide the assets before continuing.
5. Verify `pubspec.yaml` includes the game's asset directories. If not, add them.
6. Run `flutter pub get` to ensure assets are recognized.

### Adversarial Review AR-1: Asset Verification

After completing the steps above, execute this review before proceeding:

> "I will now verify my own work against spec Section 4. For every asset listed in the spec, I will re-read the file system and pubspec.yaml to confirm:
> (a) The file exists at the correct path with the correct filename
> (b) The pubspec.yaml includes the asset directory
> (c) No assets are in the wrong subdirectory (e.g., character images in sounds/)
> (d) No spec assets were overlooked
>
> I will list every discrepancy found."

Report AR-1 findings. Fix any discrepancies before proceeding.

---

## Phase 2: Core Game Logic

**Goal:** Create the game model, provider, and core game logic with tests.

### Steps

1. Create the game model: `lib/models/[game_name]_game.dart`
   - All fields per the spec's rules and mechanics (Section 5/6).
   - `toJson()` and `fromJson()` for save/resume support.
   - Follow serialization rules: enums as `.name`, `Set<int>` as `List<int>`, `Map<int, int>` as `Map<String, int>`, totalDartsThrown/totalTurns as per-player maps.
2. Create the game provider: `lib/providers/[game_name]_provider.dart`
   - `startGame()`, `processDartThrow()`, `advanceTurn()`, `checkWinCondition()`.
   - All option effects from Section 7 implemented in the logic.
   - `saveGame()`, `restoreGame()`, `resumedSavedGameId`, `clearResumedSavedGameId()`.
   - Game duration tracking (`_gameStartTime`, `endGame()`).
3. Write core non-UI tests: `test/screens/games/[game_name]/[game_name]_game_test.dart`
   - Every test listed in the spec's Section 12A game logic section.
4. Run `flutter test test/screens/games/[game_name]/` to verify tests pass.

### Adversarial Review AR-2: Options Coverage

> "I will now cross-reference every option from spec Section 7 against the provider code and tests. I will list each option by name and verify:
> (a) The provider has logic that handles this option (cite the method/line)
> (b) There is at least one test that exercises this option (cite the test name)
>
> Coverage matrix:
> | Option | Provider Logic | Test Coverage |
> |--------|---------------|---------------|
> | [name] | [method]      | [test name]   |
>
> I will report any option that lacks either provider logic or test coverage."

Report AR-2 findings. Fix any gaps before proceeding.

### GATE 1: Core Logic Tests Pass

Run `flutter test test/screens/games/[game_name]/` and report:
```
Gate 1: Core Logic Tests
  Result: X/Y tests passing — [PASS/FAIL]
```
If FAIL: Fix failures, re-run, repeat until PASS. Do NOT proceed until this gate passes.

---

## Phase 3: Screens and UI

**Goal:** Create all three screens with full visual theming and shared component integration.

### Steps

1. Add widget keys to `lib/constants/test_keys.dart`:
   - `[GameName]MenuKeys` — all keys from spec Section 10A.
   - `[GameName]GameKeys` — all keys from spec Section 10B.
   - `[GameName]ResultsKeys` — all keys from spec Section 10C.

2. Create all config factory methods (spec Section 11) in their respective files:
   - `AddPlayerDialogConfig.[gameName]()` in `lib/widgets/add_player/add_player_dialog_config.dart`
   - `EditScoreDialogConfig.[gameName]()` in `lib/widgets/edit_score/edit_score_dialog_config.dart`
   - `DartboardSectionConfig.[gameName]()` in `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`
   - `DartboardFABConfig.[gameName]()` in `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`
   - `DualPlayerListPanelConfig.[gameName]()` or `TeamPlayerListPanelConfig.[gameName]()` in `lib/widgets/player_list_panel/dual_player_list_panel_config.dart` (per spec Section 1)
   - `RemoveDartsModalConfig.[gameName]()` in `lib/widgets/remove_darts_modal/remove_darts_modal_config.dart`
   - `DartboardConnectionInfoConfig.[gameName]()` in `lib/widgets/dartboard_connection_info/dartboard_connection_info_config.dart`
   - `DartboardPausedModalConfig.[gameName]()` in `lib/widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart`
   - `SaveGameModalConfig.[gameName]()` in `lib/widgets/save_game_modal/save_game_modal_config.dart`
   - `ResumeGameModalConfig.[gameName]()` in `lib/widgets/resume_game_modal/resume_game_modal_config.dart`

3. Create menu screen: `lib/screens/games/[game_name]/[game_name]_menu_screen.dart`
   - Use the correct PlayerListPanel per spec (Dual vs Team).
   - All settings from Section 7 with correct controls (toggles, dropdowns, sliders).
   - Add Player Dialog integration.
   - DartboardConnectionInfo in AppBar.
   - ResumeGameButton in AppBar.
   - ResumeGameModal overlay (Stack pattern).
   - Start button enable/disable logic (min players per Section 1).

4. Create game screen: `lib/screens/games/[game_name]/[game_name]_game_screen.dart`
   - Game board/play area per Section 10B layout.
   - DartboardEmulatorSection at BOTTOM of the screen.
   - DartboardEmulatorFAB.
   - RemoveDartsModal overlay (with Edit Score button).
   - DartboardPausedModal overlay.
   - SaveGameModal (back button + PopScope pattern).
   - Skip turn button.
   - DartboardConnectionInfo in AppBar.
   - All option effects visible per Section 7.

5. Create results screen: `lib/screens/games/[game_name]/[game_name]_results_screen.dart`
   - Winner display and rankings.
   - Victory music integration via VictoryMusicService.
   - Player stats update for ALL players (winners AND losers) with game duration.
   - Auto-delete saved game on completion.
   - Play Again, Change Settings, Back to Menu buttons.
   - DartboardConnectionInfo in AppBar.

6. Add game card to `lib/screens/home_screen.dart`.
7. Register the provider in `lib/main.dart` MultiProvider.
8. Add routes to `lib/main.dart`.
9. Run `flutter test` to verify no regressions.

### Adversarial Review AR-3: Integration Audit

> "I will now act as the Integration Agent. For each item below, I will verify it is actually present in the code — not just planned, but imported AND instantiated:
>
> (a) PlayerProvider used for user management (grep for PlayerProvider in game screens)
> (b) GameAnnouncementQueueService used (NOT DartAnnouncerService directly)
> (c) VictoryMusicService called on results screen
> (d) DartboardProvider used for dart input
> (e) updatePlayerStats called for ALL players (winners AND losers) with gameDuration
> (f) Every shared widget from spec Section 14 functional completeness list is instantiated in a screen
> (g) All 3 AppBars have: back button + title + DartboardConnectionInfo
> (h) No custom 'remove darts' button exists outside RemoveDartsModal
> (i) Correct PlayerListPanel pattern used (Dual vs Team per spec Section 1)
> (j) SaveGameModal uses PopScope + Stack pattern on game screen
> (k) ResumeGameModal uses Stack pattern on menu screen
> (l) ResumeGameButton appears in menu screen AppBar
>
> For each item I will cite the file and line number, or report MISSING.
> I will list every gap found."

Report AR-3 findings. Fix any gaps before proceeding.

---

## Phase 4: Announcement and Sound System

**Goal:** Implement the full announcement system with stacking prevention.

### Steps

1. Create sound effects service: `lib/services/[game_name]_sound_effects.dart`
   - All sounds from spec Section 4 and Section 9 with correct start/end times.
2. Create announcement helper: `lib/services/[game_name]_announcement_helper.dart`
   - All announcement events from spec Section 9.
   - Correct priority levels per event.
   - Sound effect associations.
3. Integrate announcement helper into the game screen.
4. Implement announcement stacking prevention:
   - Identify worst-case per-dart announcement count.
   - Implement "gather facts, pick winner" pattern.
   - Enforce max 2 announcements per dart (1 moment + Remove Darts).
   - "Remove your darts" must ALWAYS play.
5. Create mock audio queue service: `test/mocks/mock_[game_name]_audio_queue_service.dart`
6. Write announcement tests: `test/screens/games/[game_name]/[game_name]_announcement_test.dart`
   - All tests from spec Section 12A announcement section.
   - Max 2 announcements per event enforcement test.
   - "Remove your darts" always plays test.
7. Run `flutter test` to verify all tests pass.

### Adversarial Review AR-4: Announcement Stacking Analysis

> "I will now analyze announcement stacking by identifying the worst-case dart throw scenario — the single dart that triggers the most simultaneous events. I will:
>
> (a) List all events that this worst-case dart could trigger simultaneously
> (b) Trace through the announcement helper code to verify the precedence chain correctly suppresses lower-priority events
> (c) Count how many announcements would actually fire for this worst case
> (d) Verify the count does not exceed 2 (1 moment + Remove Darts)
> (e) Verify 'Remove your darts' is NEVER suppressed regardless of what else triggers
> (f) Verify there is a test that covers this worst-case scenario
>
> Worst-case scenario: [describe]
> Events triggered: [list]
> Announcements that fire: [count] — [PASS if <=2 / FAIL if >2]
> 'Remove your darts' suppressed: [YES/NO — must be NO]"

Report AR-4 findings. Fix any issues before proceeding.

---

## Phase 5: Save/Resume and Data Migration

**Goal:** Ensure save/resume is fully wired and check for migration needs.

### Steps

1. Verify `toJson()`/`fromJson()` in game model (should exist from Phase 2).
2. Verify `saveGame()`, `restoreGame()`, `resumedSavedGameId`, `clearResumedSavedGameId()` in provider (should exist from Phase 2).
3. Verify config factory methods exist for `SaveGameModalConfig` and `ResumeGameModalConfig` (should exist from Phase 3).
4. Verify SaveGameModal is integrated into game screen with PopScope + Stack (should exist from Phase 3).
5. Verify ResumeGameModal is integrated into menu screen with Stack (should exist from Phase 3).
6. Verify auto-delete logic in results screen's player stats update (should exist from Phase 3).
7. Write serialization tests if not done in Phase 2: `test/models/[game_name]_serialization_test.dart`
8. Write provider save/restore tests: `test/providers/[game_name]_save_restore_test.dart`
9. Check for data migration needs per `docs/development/data-migrations.md`:
   - If the new game only adds new SharedPreferences keys and optional fields with `??` defaults: no migration needed.
   - If any existing keys or field shapes change: create a migration.
   - Document the decision in the output.
10. Run `flutter test` (the FULL suite, not just the new game).

### GATE 2: Full Non-UI Test Suite Passes

Run `flutter test` (ALL non-UI tests across all games) and report:
```
Gate 2: Full Non-UI Test Suite
  Result: X/Y total tests passing — [PASS/FAIL]
```
If FAIL:
- Analyze failures per `docs/critical-rules/test-failures.md`.
- Present to user: "Tests failed. (A) Fix application code, or (B) Update tests?"
- Wait for user decision. Do NOT auto-fix tests.
- Fix per user choice, re-run, repeat until PASS.

---

## Phase 6: UI Automation Tests and Spec Coverage Audit

**Goal:** Write all UI tests, synchronize shared helpers, run the mandatory spec coverage audit.

### Steps

1. Update shared test helpers in BOTH locations (mandatory synchronization per `docs/testing/test-maintenance.md`):
   - `test/shared/element_finders.dart` — add game-specific finders
   - `test/shared/game_ui_config.dart` — add game config
   - `test/shared/provider_helpers.dart` — add provider helpers
   - `test/shared/settings_helpers.dart` — add settings helpers
   - `test/shared/ui_test_helpers.dart` — add UI helpers
   - `integration_test/shared/element_finders.dart` — SAME changes
   - `integration_test/shared/game_ui_config.dart` — SAME changes
   - `integration_test/shared/provider_helpers.dart` — SAME changes
   - `integration_test/shared/settings_helpers.dart` — SAME changes
   - `integration_test/shared/ui_test_helpers.dart` — SAME changes
   - **CRITICAL:** Changes in `test/shared/` MUST be mirrored in `integration_test/shared/` and vice versa.

2. Create all UI test files from spec Section 12B:
   - `integration_test/[game_name]/[game_name]_add_player_test.dart`
   - `integration_test/[game_name]/[game_name]_menu_and_settings_test.dart`
   - `integration_test/[game_name]/[game_name]_gameplay_test.dart`
   - `integration_test/[game_name]/[game_name]_edit_score_test.dart`
   - `integration_test/[game_name]/[game_name]_results_test.dart`
   - `integration_test/[game_name]/[game_name]_save_resume_test.dart`

3. Create screenshot test: `integration_test/[game_name]/[game_name]_screenshot_test.dart`
   - Capture all states listed in spec Section 12C.
   - MUST use `test_driver/screenshot_test.dart` as driver.
   - MUST NOT use `pumpAndSettle()` — use manual `pump()` sequences.

4. Update `run_ui_tests.bat` AND `run_ui_tests_stub.bat` with new game entries.

5. **Run Spec Coverage Audit** (per `docs/testing/spec-coverage-audit.md`):
   - Step 1: Extract every option from Section 7, every visual element from Section 10, every test requirement from Section 12.
   - Step 2: Map every non-UI test and UI test to these requirements.
   - Step 3: Build the coverage matrix.
   - Step 4: Report any gaps.
   - Step 5: Write missing tests for any gaps found.
   - Step 6: Re-audit until 100% coverage.

### Adversarial Review AR-5: Spec Coverage Matrix

> "I will now act as the Tester Agent from spec Section 13. I will:
>
> (a) Count every test I wrote vs. every test the spec Section 12 requires. List any spec-required test that is missing by name.
>
> (b) For each option in Section 7, verify there is at least one non-UI test AND one UI test that exercises it. Build the matrix:
> | Option | Non-UI Test | UI Test |
> |--------|-------------|---------|
> | [name] | [test file:name or MISSING] | [test file:name or MISSING] |
>
> (c) Check that both `run_ui_tests.bat` and `run_ui_tests_stub.bat` include the new game.
>
> (d) Check that all shared helpers in `test/shared/` and `integration_test/shared/` are synchronized — diff each pair and report any mismatches.
>
> Spec coverage: X% (N/M requirements covered)
> Missing coverage: [list]"

Report AR-5 findings. Fix any gaps, re-audit until 100%.

### GATE 3: Spec Coverage Audit Clean + Non-UI Tests Pass

```
Gate 3: Spec Coverage + Non-UI Tests
  Spec coverage:  X% — [PASS only if 100% / FAIL otherwise]
  Non-UI tests:   X/Y passing — [PASS/FAIL]
  OVERALL:        [PASS/FAIL]
```
If FAIL: Write missing tests, fix failures, re-audit, re-run. Repeat until PASS.

---

## Phase 7: Visual Validation

**Goal:** Execute the FULL iterative validation cycle from `docs/critical-rules/visual-validation.md`. This phase contains the complete visual + UI + non-UI verification loop.

**CRITICAL UNDERSTANDING:** "Screenshot test passed" does NOT mean "visual validation complete." A passing test only means screenshots were captured without runtime errors. The actual validation is reading and evaluating every screenshot against the checklist. These are two completely separate steps — NEVER conflate them.

### The Iterative Validation Cycle

Execute this cycle exactly as written. Do not skip steps. Do not shortcut.

```
STEP 1 → STEP 2 → STEP 3 → STEP 4 decision
                                ↓ issues found → fix → back to STEP 1
                                ↓ no issues → STEP 5
STEP 5 → STEP 6 decision
            ↓ UI tests fail → fix → back to STEP 1
            ↓ UI tests pass → STEP 7
STEP 7 → STEP 8 decision
            ↓ non-UI fail → fix → back to STEP 1
            ↓ non-UI pass → STEP 9 (all pass simultaneously → done)
```

---

### STEP 1: CAPTURE

1. Kill any running `chromedriver.exe` processes (NEVER kill `chrome.exe`).
2. Start chromedriver: `cd chromedriver/chromedriver-win64 && ./chromedriver.exe --port=4444`
3. Wait 5 seconds for chromedriver to initialize.
4. Run the screenshot test:
   ```bash
   flutter drive --driver=test_driver/screenshot_test.dart \
     --target=integration_test/[game_name]/[game_name]_screenshot_test.dart -d chrome
   ```
   **CRITICAL:** Use `test_driver/screenshot_test.dart` — NEVER `test_driver/integration_test.dart` (will hang silently on `takeScreenshot()`).
   **CRITICAL:** Do NOT use `--no-headless` flag.
5. Confirm all screenshots saved to `temp_screenshots/`.
6. List all screenshot files found.

If the screenshot test fails to run, STOP and ask the user. Do NOT skip.

---

### STEP 2: EVALUATE every screenshot

For EACH screenshot image in `temp_screenshots/`:
1. Read the screenshot image file using the Read tool.
2. Check EVERY item on this checklist:

**Layout & Spacing:**
- [ ] No scrolling required on this screen
- [ ] No image clipping or overflow
- [ ] Proper alignment of all UI elements
- [ ] No text overflow or truncation
- [ ] Good screen space utilization

**Typography & Consistency:**
- [ ] Font sizes are correct for the game's design system
- [ ] Fonts match the spec's Section 2 typography
- [ ] Adequate text contrast and readability
- [ ] Consistent styling across similar elements

**Visual Quality:**
- [ ] Colors match the game's palette from spec Section 2
- [ ] Visual appeal appropriate for the game's theme
- [ ] Family-friendly scale and content
- [ ] Option effects are visible where applicable

**Correctness:**
- [ ] Game characters render correctly (not used as player avatars)
- [ ] All interactive elements clearly identifiable
- [ ] All game states display correct information
- [ ] Button sizes are tappable (touch-friendly)

Also check any game-specific visual items from spec Section 12C.

**You MUST read and evaluate EVERY screenshot. You MUST check EVERY item. Do not evaluate a subset.**

---

### STEP 3: REPORT findings

Create a findings report:
```
Visual Validation Report — Cycle N
Screenshots evaluated: X/X

Issues found:
1. [screenshot_name.png] SEVERITY: [High/Medium/Low]
   Description: [what's wrong]
2. ...

Total issues: N
```

Present the full report to the user.

---

### STEP 4: Visual issues found?

**YES (issues > 0):**
- Fix all identified issues in the application code.
- **Go back to STEP 1.** You MUST re-capture AND re-evaluate ALL screenshots — not just the ones you fixed. Fixes can have unintended effects on other screens.

**NO (issues = 0):**
- Continue to STEP 5.

---

### STEP 5: Run UI automation tests

Run the UI automation tests for the new game:
```bash
./run_ui_tests.bat [game_name]
```

If chromedriver is not available or tests cannot run:
- **STOP immediately.**
- Tell the user which tests cannot run and why.
- Ask the user how to proceed.
- Do NOT skip. Do NOT proceed without running them.

---

### STEP 6: UI tests fail?

**YES (any failures):**
- Analyze failures. Present to user per `docs/critical-rules/test-failures.md`:
  "Tests failed. (A) Fix application code, or (B) Update tests?"
- Wait for user decision. Do NOT auto-fix tests.
- Fix per user choice.
- **Go back to STEP 1.** Screenshots may have changed due to fixes.

**NO (all pass):**
- Continue to STEP 7.

---

### STEP 7: Run flutter test (ALL non-UI tests)

```bash
flutter test
```

This runs ALL non-UI tests across ALL games, not just the new one.

---

### STEP 8: Non-UI tests fail?

**YES (any failures):**
- Analyze failures. Present to user per `docs/critical-rules/test-failures.md`.
- Wait for user decision. Fix per user choice.
- **Go back to STEP 1.** Start the entire cycle over.

**NO (all pass):**
- Continue to STEP 9.

---

### STEP 9: All pass simultaneously

All three conditions are now true at the same time:
- Visual validation: zero issues
- UI automation tests: 100% pass
- Non-UI tests: 100% pass

Proceed to the adversarial review.

---

### Adversarial Review AR-6: Validation Completeness

**Before leaving Phase 7, answer every question honestly. If any answer is "no", go back and complete the missing step.**

> "(a) Did I actually RUN the screenshot test? (not just write it)
> (b) Did I actually READ every screenshot image with the Read tool? (not just assume they were fine)
> (c) For each screenshot, did I check EVERY item on the full checklist? (not a subset)
> (d) After EVERY fix, did I go back to Step 1 and re-capture AND re-evaluate ALL screenshots? (not just the changed ones)
> (e) Did I run the UI automation tests with run_ui_tests.bat? (not just the non-UI tests)
> (f) Did I run `flutter test` after the UI tests passed?
> (g) Are ALL three (visual clean + UI pass + non-UI pass) true RIGHT NOW, simultaneously?
>
> Answers: (a) [Y/N] (b) [Y/N] (c) [Y/N] (d) [Y/N] (e) [Y/N] (f) [Y/N] (g) [Y/N]
>
> If any answer is NO, I will go back and complete the missing step before proceeding."

---

## Phase 8: Simultaneous Pass Verification

**Goal:** Confirm all four completion conditions are true at the same time, including the spec coverage audit.

### Steps

1. Confirm spec coverage audit is still clean (from Phase 6). If any code changed during Phase 7 (likely from visual/test fixes), re-run the spec coverage audit to verify it's still 100%.
2. Confirm visual validation completed with zero issues (from Phase 7).
3. Confirm UI automation tests passed in the most recent cycle (from Phase 7).
4. Confirm non-UI tests passed in the most recent cycle (from Phase 7).

### GATE 4: Simultaneous Pass (NON-NEGOTIABLE)

```
Gate 4: Simultaneous Pass Verification
  Spec coverage audit:  [PASS/FAIL] — X%
  Visual validation:    [PASS/FAIL] — X screenshots, zero issues
  UI automation tests:  [PASS/FAIL] — X/Y passing
  Non-UI tests:         [PASS/FAIL] — X/Y passing
  OVERALL:              [PASS/FAIL]
```

If ANY component fails:
- Fix the failing component.
- Re-run ALL FOUR checks (not just the fixed one — a fix can break others).
- Repeat until all four pass simultaneously.

If a check CANNOT be run:
- **STOP immediately.**
- Tell the user which check cannot be run and why.
- Ask the user how to proceed.
- **Do NOT skip the check. Do NOT proceed without it.**

---

## Phase 9: Documentation and Definition of Done

**Goal:** Create all game documentation, update project files, verify Definition of Done.

### Steps

1. Copy game template directory:
   ```
   docs/games/_GAME_TEMPLATE/ → docs/games/[game-name]/
   ```

2. Fill out all 8 template files:
   - `README.md` — overview, quick facts, player count, file locations, key features
   - `game-rules.md` — objective, setup, turn structure, scoring, win conditions, edge cases
   - `design-system.md` — color palette with hex codes, typography, screen styling, animations
   - `components.md` — all config factory methods documented with parameters
   - `announcements.md` — all announcement events, priorities, sound effects, stacking rules
   - `testing.md` — test counts, test files, widget keys, test patterns
   - `assets.md` — complete asset inventory with descriptions
   - `implementation-notes.md` — provider pattern, model design, algorithms, gotchas

3. Update `CLAUDE.md`:
   - Add new game to Games section with link and description
   - Update total test counts (non-UI + UI)
   - Add game-specific test run commands
   - Update file structure section if needed

4. Update `docs/testing/test-overview.md` with new test counts and breakdown.
5. Update `docs/testing/non-ui-tests.md` with new test details.
6. Update `docs/testing/ui-automation.md` with new UI test counts.
7. Update `docs/DOCUMENTATION_STRUCTURE.md` with new game docs.

8. Verify EVERY item in spec Section 14 (Definition of Done):

   **Functional Completeness:**
   - [ ] All options from Section 7 implemented with visible effects
   - [ ] All shared widgets integrated (list each one)
   - [ ] All config factory methods created (list each one)
   - [ ] All infrastructure integrated (PlayerProvider, announcer, victory music, dartboard)
   - [ ] All assets present and referenced
   - [ ] Announcement helper with stacking prevention
   - [ ] Game characters NOT used as player avatars

   **Testing:**
   - [ ] Non-UI tests pass (count)
   - [ ] UI test files created (count)
   - [ ] Batch files updated (run_ui_tests.bat AND run_ui_tests_stub.bat)
   - [ ] Shared helpers synchronized (test/shared/ matches integration_test/shared/)

   **Visual Validation:**
   - [ ] Screenshot test created and executed
   - [ ] Every screenshot evaluated against checklist
   - [ ] All visual issues fixed and re-verified
   - [ ] Zero visual issues remaining

   **Documentation:**
   - [ ] CLAUDE.md updated
   - [ ] All 8 game doc files created
   - [ ] Testing docs updated with counts

### Adversarial Review AR-7: Final Full Review

> "I will now do a final adversarial review of the entire game implementation:
>
> (a) Re-read spec Section 7. For every option listed, I will examine the game screen code and verify it has a VISIBLE effect. I will list each option and where its effect appears.
>
> (b) Re-read spec Section 14 Definition of Done. For every item, I will verify it is GENUINELY complete — not assumed, not planned, but done. I will list each item with evidence.
>
> (c) Verify game characters are NOT used as player avatars (spec Rule 10). Grep for any code that assigns character images to player avatar slots.
>
> (d) Verify `updatePlayerStats` is called for ALL players (winners AND losers) with the SAME `gameDuration` value.
>
> (e) Verify the correct PlayerListPanel pattern (Dual vs Team) matches spec Section 1.
>
> (f) Verify all 3 AppBars are styled consistently per spec Section 2 (back button + title + DartboardConnectionInfo).
>
> (g) Grep for any TODO, FIXME, HACK, or stub code in ALL new game files:
>    `grep -r 'TODO\|FIXME\|HACK\|stub' lib/screens/games/[game_name]/ lib/models/[game_name]* lib/providers/[game_name]* lib/services/[game_name]*`
>
> (h) Verify no existing game code or tests were broken — only additive changes per spec Section 16. Check `git diff` for modifications to files outside the new game's directories.
>
> Issues found: [list each with severity]"

Report AR-7 findings. Fix any issues found.

### GATE 5: Definition of Done

Present the full Definition of Done checklist to the user with PASS/FAIL for each item:

```
Gate 5: Definition of Done
  Functional Completeness:
    All Section 7 options implemented:     [PASS/FAIL]
    All shared widgets integrated:         [PASS/FAIL]
    All config factory methods:            [PASS/FAIL]
    All infrastructure integrated:         [PASS/FAIL]
    All assets present:                    [PASS/FAIL]
    Announcement system:                   [PASS/FAIL]
    Character/avatar rule:                 [PASS/FAIL]
  Testing:
    Non-UI tests:                          [PASS/FAIL] (X tests)
    UI test files:                         [PASS/FAIL] (X files)
    Batch files updated:                   [PASS/FAIL]
    Shared helpers synced:                 [PASS/FAIL]
  Visual Validation:
    Screenshots captured + evaluated:      [PASS/FAIL]
    Zero visual issues:                    [PASS/FAIL]
  Documentation:
    CLAUDE.md updated:                     [PASS/FAIL]
    Game docs (8 files):                   [PASS/FAIL]
    Testing docs updated:                  [PASS/FAIL]
  OVERALL:                                 [PASS/FAIL]
```

---

## Final Summary

After Gate 5 passes, print:

```
=== Game Build Complete ===
Game:              [Game Name]
Branch:            [branch-name]
Files created:     X new files
Files modified:    Y existing files
Non-UI tests:      X (all passing)
UI tests:          Y (all passing)
Screenshots:       Z (all evaluated, zero issues)
Spec coverage:     100%
Definition of Done: X/X verified
Gates passed:      5/5
ARs completed:     7/7

Ready for commit and PR.
```

Ask the user: "Would you like me to commit and create a PR?"

---

## Error Handling Rules

These rules apply throughout ALL phases:

### When Tests Fail
Per `docs/critical-rules/test-failures.md`:
1. STOP and analyze the failure.
2. Present to user: "(A) Fix application code, or (B) Update tests?"
3. Wait for user decision. NEVER auto-fix tests.
4. Implement the chosen approach.
5. Re-run all tests.

### When a Gate Cannot Be Run
1. STOP immediately.
2. Tell the user which gate cannot be run and why.
3. Ask the user how to proceed.
4. Do NOT skip. Do NOT proceed without it. There is NO valid reason to skip a gate.

### When Dartboard Emulator Code Needs Changes
Per `docs/critical-rules/dartboard-protection.md`:
1. Do NOT modify. Ask user for permission first.
2. If the user approves, make minimal changes and test thoroughly.

### When Shared Test Helpers Need Changes
Per `docs/testing/test-maintenance.md`:
1. Update BOTH `test/shared/` AND `integration_test/shared/`.
2. Verify synchronization by diffing corresponding files.
3. Run both test suites to verify.

### When Cross-Platform Issues Arise
Per `docs/critical-rules/cross-platform.md`:
1. All features must work on web + tablets.
2. Test responsive layouts.
3. Use platform-agnostic APIs.

### Prohibited Actions
- NEVER skip a phase or gate for any reason.
- NEVER rationalize skipping ("it requires manual setup", "tests were already written", "seems visual-only").
- NEVER mark a gate as complete without actually executing it.
- NEVER move to documentation while any gate is incomplete.
- NEVER treat "screenshot test passed" as "visual validation complete."
- NEVER evaluate only a subset of screenshots.
- NEVER auto-update tests to make them pass without user approval.
- NEVER modify dartboard emulator code without user permission.
