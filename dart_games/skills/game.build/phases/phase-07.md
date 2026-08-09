<!-- game.build Phase 7 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 7: UI Automation Tests, Spec Coverage Audit, and Mandatory Coverage

**Goal:** Write all UI tests in the proper subdirectory layout (including mandatory navigation, results, and play-to-complete tests), synchronize the mirrored shared helpers, update all 4 batch files, run the spec coverage audit.

**Model:**
- **Shared helper sync + UI test files + screenshot test + batch file updates:** **Tier 3** (Sonnet).
- **After test authoring:** **[Playbook §10 — Test-smell reviewer]** (Tier 2) on the new UI test files.
- **Spec coverage audit:** **[Playbook §6 — Loop-until-dry]** — run coverage rounds on **Tier 0** (orchestrator) until K=2 consecutive dry rounds. Between rounds, delegate gap-close test authoring to Tier 3.
- **AR-6 spec coverage matrix:** **Tier 0** (orchestrator).
- **Gate 3:** **Tier 0** (orchestrator).

### Step 7A: Delegate UI test infrastructure to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 7 (UI Automation Tests) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — Testing Plan section (UI test list and screenshot test states)
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/testing/test-maintenance.md` — **CRITICAL: shared helper synchronization rules**
> - `docs/testing/shared-helpers-reference.md` — **authoritative reference for the mirrored shared helpers, the `_helpers.dart` delegate pattern for per-subdirectory game-specific helpers, and the decision tree for where new helper functions belong**
> - `docs/testing/ui-automation.md` — including the per-session DB isolation pattern (`X-DB-Session` header, `resetServerState()`) and the parallel runner port-assignment table
> - `docs/testing/continuous-animations.md` — `pumpAndSettle()` rules
> - `docs/development/adding-games.md` — **including mandatory navigation tests (4), mandatory results-screen tests (3), and mandatory play-to-complete tests, with rationales for each**
> - `docs/development/navigation-ui-tests-plan.md` — **canonical plan for the 4 mandatory navigation tests, with per-game settings to change, completion strategies, and verification text patterns**
> - `docs/development/game-integration.md` — `(route) => false` rule
> - `docs/development/dartboard-emulator.md` — Play-to-Complete strategy + tests
> - At least one existing game's UI tests for reference (use Clockwork Quest as the canonical example: `integration_test/clockwork_quest/`)
> - `test_driver/screenshot_test.dart` (the correct driver — DO NOT use `test_driver/integration_test.dart`)
>
> **Tasks:**
>
> **1. Update shared test helpers in BOTH locations (mandatory synchronization).**
>
> The mirrored set is **discovered dynamically**, not enumerated. The rule (Rule §26): every `*.dart` file present in BOTH `integration_test/shared/` and `test/shared/` MUST stay byte-identical between the two. Files present in only one directory are intentionally non-mirrored (e.g. `mock_api_helpers.dart`, `player_test_utils.dart`, and `sector_parser.dart` in `test/shared/` import non-UI testing packages and have no UI-test counterpart).
>
> When adding a method/function to a shared helper, apply the IDENTICAL change to BOTH copies in the same edit pass.
>
> When CREATING a new shared helper, decide first whether it can compile in both contexts:
> - **If yes:** create it in BOTH directories from the start. Mirror byte-identical.
> - **If no** (e.g. it imports `package:integration_test` and uses `IntegrationTestWidgetsFlutterBinding`): create it in ONLY the directory that can compile it. The other directory has no copy and the mirror rule does not apply.
> - **Caveat — `flutter drive` web compile cache:** brand-new files under `integration_test/shared/` are silently ignored by the web compile cache (commit `4d1377e`). When a UI test imports such a new file, compilation fails with `org-dartlang-app:/...File not found` even though `dart analyze` finds the file. Workaround: add the new functionality as a static method on an existing long-lived helper class (e.g. `UITestHelpers`) instead of creating a new shared file. See Rule §26 for the full pattern.
>
> **Verification (use this exact command — do NOT walk an enumerated list):**
> ```bash
> diff -rq integration_test/shared test/shared 2>&1 | grep "differ" || echo "OK: all mirrored helpers byte-identical"
> ```
> The `diff -rq` output emits one line per pair that differs (`Files X and Y differ`). The `grep "differ"` filter strips expected `Only in test/shared: <file>` lines for non-mirrored helpers. Anything the grep prints is a parity violation that must be fixed.
>
> **1.5. Create per-subdirectory `_helpers.dart` files** (delegate pattern from `docs/testing/shared-helpers-reference.md`):
>
> Every test subdirectory needs an `_helpers.dart` file. Follow the delegate pattern documented at lines 76-163 of `docs/testing/shared-helpers-reference.md`:
> - Import the relevant shared helpers from `../../shared/`
> - Expose **one-line delegate functions** that preserve the local function names test files already use (e.g., `Future<void> setupGame(...) => GameSetupHelpers.setupGame(...)`)
> - ONLY add genuinely game-specific logic that doesn't belong in shared helpers (e.g., a `completeGameToVictory()` that knows how to drive THIS game's win condition)
> - When unsure whether new logic belongs in `_helpers.dart` or in the shared helpers, follow the decision tree in `shared-helpers-reference.md` (used by ≥2 games → shared; used only by this game → `_helpers.dart`).
>
> **1.6. Iterative authoring workflow — DO NOT write all UI tests in one pass.**
>
> Past UI test rounds for Pirate's Grid took 7+ debugging cycles (rounds B, C, D, then 2/3/4/5/6 in commit titles) because the entire test pack was authored before any of it was run. Once one test failed, similar tests had similar failures, but you had to iterate one bug class at a time across many files. The user explicitly requested an iterative approach to compress this loop.
>
> **Order of authoring (easiest to hardest, one category at a time):**
>   1. **`visual_validation/[GAME_NAME_SNAKE]_screenshot_test.dart`** FIRST. The screenshot test is the cheapest and most informative end-to-end probe: it validates that all widget keys exist, that menu→game→results navigation works, that screen layouts don't overflow, and that backgrounds/characters render. ONE deliverable, one run, ten captured states. Use the result of this run as the foundation for everything else.
>   2. **`menu_and_settings/`** — pure menu interactions (sliders, dropdowns, toggles). No game lifecycle, no dartboard, no modals. Easiest UI surface.
>   3. **`add_player/`** — dialog-based, isolated. Easy second category.
>   4. **`navigation/`** — the 4 mandatory tests. Tests menu↔home + back-from-game + Change Settings round-trip. Validates the navigation pattern for all later tests.
>   5. **`gameplay/`** — core dart-throwing flows. Now you have menu setup proven and navigation proven; only the gameplay surface is new.
>   6. **`pause_modal/`** — disconnect/reconnect overlays. Builds on gameplay+navigation.
>   7. **`results_screen/`** — completing a game and verifying results. Builds on gameplay.
>   8. **`save_resume/`** — full save/resume cycles. Builds on results+navigation.
>   9. **`edit_score/`** — RemoveDartsModal + EditScoreDialog. Most complex modal stacking.
>   10. **`play_to_complete/`** — strategy-driven full game runs. Most fragile category (depends on the strategy + every game mechanic).
>
> **Per-category authoring loop:**
>   1. Author ONE test file in the category (the most representative — typically the "default settings happy path").
>   2. Run it through the parallel runner immediately. Inspect the failure log if any.
>   3. Fix the screen / provider / helpers / shared infrastructure based on what the failure reveals — every fix benefits the remaining tests in the category.
>   4. ONLY when the first test passes, author the rest of the category in one pass. They will share infrastructure with the first.
>   5. Run the entire category. Triage any remaining failures.
>   6. Move to the next category.
>
> The orchestrator MUST resist the temptation to delegate "write all 47 UI tests in parallel" to a sub-agent in a single batch. Past sessions tried this; the test author wrote 47 tests sharing the same bug class (e.g., missing ensureVisible, hardcoded grid targets, missing in-game save flow) and the user spent days debugging each instance instead of fixing the root once and replicating.
>
> **1.7. Every UI test must wrap its body in `UITestHelpers.runWithFailureScreenshot` DURING THE BUILD PHASE.**
>
> When a UI test fails the only artifact available for debugging in the standard log is text — no screen state, no DOM, no rendered pixels. The `UITestHelpers.runWithFailureScreenshot(tester, testName, body)` helper captures a PNG of the screen at the moment of failure and writes it to `temp_screenshots/failures/<testName>_<timestamp>.png` so the orchestrator can read the image with the Read tool and see what actually rendered.
>
> **The wrap is BUILD-PHASE ONLY.** It exists to compress the iterate-fix loop while a new game's tests are being authored. It is REMOVED at the Phase 9 Gate 4 transition (see "Failure-screenshot wrap removal" below). After removal, the new game's tests look identical to every other game's tests and run via the standard runner with no per-test screenshot overhead.
>
> Pattern during build (every test in the new game's pack):
> ```dart
> testWidgets('foo', (tester) async {
>   await UITestHelpers.runWithFailureScreenshot(
>     tester,
>     '[GAME_NAME_SNAKE]_<subdir>_<test_basename>',  // e.g. 'pirates_grid_save_resume_save_modal_save_button'
>     () async {
>       await UITestHelpers.resetServerState();
>       // ... existing test body ...
>     },
>   );
> });
> ```
>
> **Driver during build:** `flutter drive --driver=test_driver/screenshot_test.dart --target=integration_test/[GAME_NAME_SNAKE]/<category>/foo_test.dart -d chrome --dart-define=SERVER_PORT=<port> --browser-dimension=1366x768`. The screenshot test driver's `onScreenshot` callback writes PNG bytes to `temp_screenshots/<name>.png` — the helper passes `failures/<sanitized-test-name>_<ts>` as the name, so files land in `temp_screenshots/failures/`. Verified end-to-end via `integration_test/_smoke/failure_screenshot_smoke_test.dart` (kept in tree as a self-test artifact for use after Flutter SDK upgrades).
>
> **Production runner driver:** `test_driver/integration_test.dart` (the basic `integrationDriver()` with no `onScreenshot`). The runner scripts (`run_ui_tests.bat`, `run_ui_tests_parallel.bat`) use this driver. Since failure-screenshot wraps are removed at the Phase 9 transition, post-build tests have no dependency on screenshot capture in the runner.
>
> The `testName` argument is used as the filename prefix; embed `<game>_<subdir>_<test_basename>` so PNGs from parallel workers don't collide and reviewers can find the right image quickly. The helper sanitizes the name and appends a millisecond timestamp.
>
> **2. Create UI test files using the SUBDIRECTORY layout** (NOT flat files):
>
> **Reference layouts vary across the 5 existing games — follow Clockwork Quest as the canonical fully-subdivided example.** Layout differences:
> - **Clockwork Quest** (`integration_test/clockwork_quest/`) — fully subdivided; canonical reference. Note: its menu-back-to-home test is at `menu_and_settings/back_button_test.dart` (historical) rather than `navigation/menu_back_to_home_test.dart`. New games should put it in `navigation/` per the pattern in the other 4 games.
> - **Target Tag, Monster Mash, Reef Royale** — use `results_screen/` (3 of 5 games). Target Tag uses `menu_and_mechanics/` for historical reasons; new games should use `menu_and_settings/`.
> - **Carnival Derby** — legacy flat `ui/` directory; **do NOT use as a layout reference for new games**.
>
> Create the following subdirectories under `integration_test/[GAME_NAME_SNAKE]/`:
>
> - `add_player/` — Add Player Dialog tests (one or more `*_test.dart` files per spec scenarios)
> - `edit_score/` — Edit Score Dialog tests
> - `gameplay/` — Core gameplay tests
> - `menu_and_settings/` — Menu screen + settings tests
> - `results_screen/` — Results screen tests, INCLUDING the three mandatory tests below. **Use `results_screen/` (matches Target Tag, Monster Mash, Reef Royale — 3 of 5 games) unless your spec explicitly mandates `results/`.**
> - `save_resume/` — Save/Resume tests. **MANDATORY: 16 separate test files, one testWidget per file**, mirroring the canonical pack used by Target Tag, Monster Mash, Reef Royale, Clockwork Quest:
>   - `save_modal_save_button_test.dart`, `save_modal_dont_save_test.dart`, `save_modal_back_0_darts_test.dart`, `save_modal_back_after_darts_test.dart`
>   - `resume_button_disabled_no_saves_test.dart`, `resume_button_color_when_enabled_test.dart`, `resume_button_enabled_after_save_test.dart`, `resume_button_hidden_after_resume_test.dart`, `resume_button_shows_modal_test.dart`
>   - `resume_modal_shows_on_game_tap_test.dart`, `resume_modal_start_new_game_test.dart`, `resume_modal_delete_individual_test.dart`, `resume_modal_delete_all_test.dart`
>   - `resume_game_loads_screen_test.dart`, `resume_resave_overwrites_test.dart`, `resume_auto_deletes_on_completion_test.dart`
>   - **Reference:** mirror `integration_test/monster_mash/save_resume/*` 1-for-1. Past failure: Pirate's Grid and Lunar Lander shipped with 6 sub-tests in a single combined file — the 10 missing edge cases were never written. The 3 "real-flow" files (resume_game_loads_screen, resume_resave_overwrites, resume_auto_deletes_on_completion) MUST use the in-game save flow per Rule 17 — not `preSaveGame`.
> - **`navigation/`** — the 4 mandatory navigation tests (see below)
> - **`play_to_complete/`** — Play-to-Complete tests (see below)
> - `visual_validation/` — Screenshot test (Step 7 below)
> - **`pause_modal/`** — Dartboard pause modal tests. **MANDATORY: 20 testWidgets total across 3 files** matching the canonical pack used by Target Tag, Monster Mash, Reef Royale, Clockwork Quest, Lunar Lander:
>   - `menu_pause_test.dart` — **7 testWidgets**: pause appears on menu, blocks AppBar back, blocks start button, blocks settings controls, blocks add player button, dismiss-and-resume, post-reconnect back button works
>   - `gameplay_pause_test.dart` — **8 testWidgets**: pause appears during gameplay, blocks AppBar back, blocks dartboard emulator, pause over RemoveDartsModal, pause over SaveGameModal (save button blocked), EditScoreDialog auto-closes on disconnect, pause dismisses on reconnect, RemoveDartsModal still visible after reconnect
>   - `results_pause_test.dart` — **5 testWidgets**: pause appears on results, blocks Play Again, blocks Change Settings, blocks Back to Menu, dismiss-and-buttons-work
>   - **Reference:** mirror `integration_test/monster_mash/pause_modal/*` 1-for-1, replacing MM-specific finders with the new game's. Past failure: Pirate's Grid shipped with only 3 testWidgets (1 per file) — caught post-launch by a cross-game test-count audit. A skeleton "1 test per file" version is NOT acceptable — the modal-stacking edge cases (pause-over-RemoveDartsModal, EditScoreDialog auto-close) only exist in the full pack.
>
> **3. Mandatory navigation tests** (4 separate files in `integration_test/[GAME_NAME_SNAKE]/navigation/`, per `docs/development/game-integration.md` and `docs/development/navigation-ui-tests-plan.md`):
>
> - `menu_back_to_home_test.dart` — back arrow on menu returns to home with ≥3 game cards visible
> - `game_back_settings_persist_test.dart` — back from game returns to menu with previously-set settings preserved
> - `change_settings_back_to_home_test.dart` — Change Settings on results returns to menu, then back to home
> - `change_settings_preserves_settings_test.dart` — Change Settings preserves all menu settings (does NOT reset)
>
> **Settings-persistence tests must change *non-default* settings** so the test actually verifies persistence. Pick at least 2 non-default options from the spec's Options section; for reference, see how each existing game does it (`navigation-ui-tests-plan.md` lines 62-66 — e.g., Target Tag changes `shieldMax` from default 3 to 5; Carnival Derby changes `targetScore` to 180 and `perfectFinish` to Yes; Monster Mash changes `health` and `speedMode`). The orchestrator should pick 2 non-default options for THIS game from the spec and pass them in the sub-agent prompt.
>
> **4. Mandatory results-screen tests** (3 specific tests in `integration_test/[GAME_NAME_SNAKE]/results_screen/`, per `docs/development/adding-games.md` lines 451-464):
>
> - **Exit-button test** — assert **≥3 game cards visible** after pressing Back-to-Home, AND verify the implementation uses `Navigator.popUntil(context, (route) => route.isFirst)` (NOT `pushNamedAndRemoveUntil('/', (route) => false)`).
>   - **Rationale:** asserting only ≥1 card is a false positive — the home screen renders even when the route stack is broken. Asserting ≥3 cards proves the home screen actually loaded with its real content. Reference: `integration_test/clockwork_quest/results/leave_tower_test.dart`.
> - **`winner_stats_updated_test.dart`** — after game completes, use `ProviderHelpers.findPlayerByName` to assert `gamesPlayed == 1` and `gamesWon == 1` for the winner, and `gamesWon == 0` for losers. **Pump for at least 5 seconds** to allow the async `updatePlayerStats` API call to complete.
>   - **Rationale:** the Dart unit test for `updatePlayerStats` passes even when `_updatePlayerStats` is omitted from `initState()` on the results screen — only an end-to-end UI test catches that wiring error. Without enough pump time, the async call hasn't returned and the assertion fails spuriously.
> - **`victory_music_initialized_test.dart`** — call `await UITestHelpers.resetServerState()` first, then complete the game; after the results screen loads, assert `VictoryMusicService().isInitialized == true`.
>   - **Rationale:** `resetServerState()` resets the singleton's `_initialized` flag back to `false`. If the results screen fails to call `VictoryMusicService().initialize()`, the flag stays `false` — this is the only signal that proves the music init actually fires on results.
>
> **5. Mandatory play-to-complete tests** (in `integration_test/[GAME_NAME_SNAKE]/play_to_complete/`, per `docs/development/dartboard-emulator.md`):
>
> - `default_settings_test.dart` — runs the strategy with default settings; game completes; results screen reached
> - `mid_game_test.dart` — invokes Play-to-Complete from a mid-game state
> - One test file per game-critical setting (e.g., `tower_max_15_test.dart`, `quick_path_enabled_test.dart`) — every option whose setting changes the strategy's behavior gets its own test
>
> **5a. Mandatory player-count coverage tests** (in `integration_test/[GAME_NAME_SNAKE]/gameplay/`):
>
> - `min_player_count_test.dart` — start a game with the spec's minimum players (typically 2). Verify all players' UI elements render (tiles, tracks, panels — whichever the game uses). Complete one full turn cycle and verify each player's per-player state updates correctly.
> - `max_player_count_test.dart` — start a game with the spec's maximum players (typically 8). Verify all N players' UI elements render without overflow or layout errors. Verify the screen scales correctly (e.g., character sizing, list scrolling, no clipping).
> - **Rationale:** Layout regressions at max player count (overflow, characters too small, lists clipped, dynamic sizing broken) are invisible to default-player tests. Default tests typically use 2-3 players and never exercise the upper bound. Reference: Carnival Derby `game_eight_player_max_test.dart`, Clockwork Quest `four_player_turn_cycle_test.dart`.
>
> **5b. Mandatory multi-player UI visibility test** (in `integration_test/[GAME_NAME_SNAKE]/gameplay/`):
>
> - `opponent_display_test.dart` — in a 3+ player game, verify inactive (non-current) players are visually present (their tiles, tracks, panels, or whichever UI element represents them). After throwing darts as the current player and advancing turn, verify the previous player's per-player state (score, health, altitude, position, marks) is now visible and correct on their tile/track.
> - **Rationale:** Many games show only the current player prominently; without this test, regressions where opponent panels disappear, never update, or show stale state are caught only by manual testing. Reference: Clockwork Quest `opponent_tiles_visible_test.dart`, Reef Royale `opponent_summary_bar_updates_test.dart`.
>
> **5c. Mandatory per-option-value functional gameplay tests** (in `integration_test/[GAME_NAME_SNAKE]/gameplay/`):
>
> Every row in spec Section 7 (Game Options & Settings) requires **one functional gameplay UI test per VALUE** (not per option). A 3-value dropdown like Difficulty (Easy/Medium/Hard) needs 3 tests; an on/off toggle needs 2 (one per state); a numeric option with N defaults the spec calls out needs N. The functional test sets up a game with that option-value and asserts a behavioral outcome — not just that the dropdown's text changed.
>
> **Test naming convention** — one of:
>   - `<option>_<value>_<behavior>_test.dart` (e.g., `difficulty_hard_corner_triple_required_test.dart`)
>   - or `<behavior>_<option>_<value>_test.dart` (e.g., `plant_flag_hard_test.dart`)
>
> **Coverage table** — at the start of Phase 7, build this table from spec Section 7 and confirm every row has a planned test file:
>   | Option | Value | Spec Visual/Behavioral Effect | Functional Gameplay Test File |
>   |--------|-------|------------------------------|-------------------------------|
>
> **Past failure:** Pirate's Grid shipped with `plant_flag_easy_test.dart` and `plant_flag_medium_test.dart` but no Hard test, no Best Of 5 test, and no Speed Play timer-expires test — three Section 7 values had zero functional UI coverage. The screen-level non-UI tests covered them logically but the UI flow (which is where most regressions hit) had gaps. Caught only by post-launch audit.
>
> **Rationale:** Provider-level tests prove the option's logic works; UI tests prove the option is actually wired through the menu → screen path and renders the expected behavior under the real frame loop. The two test layers catch different classes of bugs.
>
> **5d. Mandatory per-option-value visual_validation tests** (in `integration_test/[GAME_NAME_SNAKE]/visual_validation/`):
>
> Every spec Section 7 option that has a *visible* effect on the game screen ALSO requires one visual_validation UI test per visible value. This is in addition to the functional gameplay test in 5c — the functional test asserts the BEHAVIOR; the visual_validation test asserts the VISUAL APPEARANCE (badge presence, color, glow, text content, icon).
>
> Examples (from Pirate's Grid):
>   - Difficulty: Easy → no D/T/Bull badges visible | Medium → "D" badge in Sea Foam Teal on every cell | Hard → corners "T" Blood Red, edges "D" Sea Foam Teal, center "Bull"
>   - Best Of 1 → no round tracker visible | Best Of 3/5 → round tracker text reads "Round X/Y" with player score colors
>   - Steal Mode ON → STEAL MODE badge visible (Blood Red pill) | OFF → badge absent
>   - Speed Play ON → countdown timer visible with color tier transitions (gold→bronze→red) | OFF → no timer
>
> Group by option, one file per option (3 testWidgets within a Difficulty file is fine), or split per value (separate files). Match the `dart_indicators_state_test.dart` style — RGB byte comparison for colors, `find.byKey` for widget keys, `find.descendant` for badge contents.
>
> **Past failure:** Pirate's Grid shipped without difficulty-badges visual test, cell-flag-colors visual test, winning-row-glow visual test, round-tracker-text visual test, speed-play-timer-colors visual test, or round-complete-overlay visual test — six visible spec elements with zero visual assertion. `conditional_ui_test.dart` checked widget *visibility* but not *appearance*.
>
> **5e. Mandatory per-dart win-evaluation regression test** (in `integration_test/[GAME_NAME_SNAKE]/gameplay/`):
>
> - `win_on_early_dart_test.dart` — set up a game state where the winning condition is met on dart 1 OR dart 2 of a turn (NOT dart 3), throw exactly that dart, and assert `hasWinner == true` IMMEDIATELY afterward without throwing additional darts. Then click DARTS REMOVED, pump for ~4 s, and assert the results screen renders.
>
> **Setup may span multiple turns.** What the test is guarding is that the *winning dart* is dart 1 or dart 2 of *its own turn* — not that the entire game is one turn long. If a game's rules require multiple turns to reach the win state (e.g., Target Tag's "must be at 0 shields BEFORE the killing dart" rule, or Clockwork Quest's 7-turn ladder), drive the prior turns naturally (3 darts + DARTS REMOVED each) until you reach the winning turn, then throw exactly the winning dart and assert `hasWinner` is true before throwing any more. Do NOT contort game rules to force a single-turn scenario, and do NOT skip the assertion just because setup took several turns.
>
> **Rationale:** every dart-game title evaluates win conditions per-dart inside `processDartThrow`, not at turn end. A regression that gates win detection on `dartsThrown >= maxDartsPerTurn` (e.g. by calling `_processTurnEnd` only when `dartsThrown >= 3`) is silent against tests that always throw 3 darts and check at the end — but breaks the game the moment a player legitimately wins on dart 1 or 2 (e.g. Gladiator Arena Double Finish on the opening D20). Past failure: Gladiator Arena shipped with `_processTurnEnd(... isLastDart: dartsThrown >= 3)` gating evaluation to dart 3 only — caught only when a user reported the game not ending on a dart-1 double finish, weeks after launch. The fix had to update the provider AND two existing provider tests that had baked in the wrong assumption. Second past failure: the initial Target Tag `win_on_early_dart_test` tried to eliminate an opponent with one attack dart, contradicting Target Tag's two-hit elimination rule — the test was rewritten to span two turns (P2 misses all 3 in turn 1, P1 wins on dart 1 of turn 2), per the multi-turn-setup allowance above.
>
> **Test pattern:**
> ```dart
> testWidgets('Gameplay: dart 1 win ends the game immediately', (tester) async {
>   await UITestHelpers.resetServerState();
>   await setupAndStartGame(tester, config, /* quick-win settings */);
>
>   // Throw the winning dart — dart 1 or dart 2 of the turn.
>   await throwDartViaMock(tester, X, multiplier: 'Y');
>
>   // Game must end without further darts.
>   expect(ProviderHelpers.[gameName]HasWinner(tester), isTrue,
>       reason: 'Winning dart must end the game on dart 1');
>
>   await clickDartsRemoved(tester);
>   await ResultsHelpers.pumpUntilResults(tester, config);
>   expect(config.getPlayAgainButton(), findsOneWidget);
> });
> ```
>
> `ResultsHelpers.pumpUntilResults` is the canonical post-victory wait — it polls in 300 ms slices for up to 90 s, breaking early when the Play Again button mounts. Fixed `pump(seconds: 4)` chains are forbidden here because victory navigation is now event-driven on `_audioQueue.whenIdle()` and has unbounded wall-clock latency under heavy parallel-runner load. See Accumulated Build Quality Rules § 69.
>
> Reference implementations across shipped games:
>   - `integration_test/gladiator_arena/gameplay/win_on_early_dart_test.dart` — Double Finish on/off, dart 1 + dart 2 (T20 with target=60; S20 + D20 with DF ON)
>   - `integration_test/lunar_lander/gameplay/win_on_early_dart_test.dart` — Hard Landing OFF overshoot touchdown on dart 2 (altitude=100, T20 + T20)
>   - `integration_test/target_tag/gameplay/win_on_early_dart_test.dart` — ShieldMax=1; turn 1 sets up the at-0-shields state, dart 1 of turn 2 eliminates the last opponent (multi-turn setup, single winning dart)
>   - `integration_test/pirates_grid/gameplay/win_on_early_dart_test.dart` — `setPiratesGridGameState` pre-claims two row cells; dart 1 plants the winning third flag
>   - `integration_test/carnival_derby/ui/game_single_player_quick_win_test.dart` — target=60, T20 wins on dart 1
>
> Games whose existing tests already qualify (dart 1 / dart 2 of the final turn explicitly asserts `hasWinner == true`):
>   - `integration_test/monster_mash/gameplay/game_won_last_monster_standing_test.dart` (single dart finishes opponent at 1 HP)
>   - `integration_test/reef_royale/gameplay/game_ends_all_7_targets_test.dart` (outer bull on dart 2 of turn 3 claims the 7th target)
>   - `integration_test/clockwork_quest/gameplay/full_game_p1_wins_test.dart` (target=20 dart wins as dart 2 of turn 7)
>
> Either pattern satisfies the requirement; new games SHOULD prefer the dedicated `win_on_early_dart_test.dart` filename so the audit grep is uniform.
>
> **6. Every UI test must call `await UITestHelpers.resetServerState()` at the start.** This is required for per-session DB isolation (Flutter Bug #67090 spawns a phantom 2nd browser; without per-session DBs the phantom contaminates results — see `docs/testing/ui-automation.md`).
>
> **6a. Edit Score test design rule (mandatory):** the Edit Score button lives INSIDE the RemoveDartsModal which only renders after 3 darts thrown OR after Skip Turn. Tests trying to open the Edit Score modal MUST throw 3 darts (or 2 misses + 1 scoring dart) BEFORE calling `openEditScore`. A test that throws only 1 dart and immediately calls `openEditScore` will fail to find the button — Edit Score is part of the turn-end takeout flow.
>
> Canonical pattern:
> ```dart
> await throwDartViaMock(tester, 10);   // dart 1
> await throwMissViaMock(tester);       // dart 2 (miss — score 0)
> await throwMissViaMock(tester);       // dart 3 (miss)
> // RemoveDartsModal now visible — Edit Score button accessible
> await openEditScore(tester);
> // Dialog shows: ['S10', 'Miss', 'Miss']
> // The 'Miss' segments have ring='Miss' so Save is enabled.
> await EditScoreHelpers.setDart1(tester, 'S5');  // change dart 1
> await updateScore(tester);  // tap Save — dialog closes, altitude updates
> ```
>
> **6b. Edit Score Miss pre-selection test (mandatory — add to every game's edit_score subdirectory):** after throwing a miss, opening the Edit Score modal must show that dart's dropdown pre-selected to "Miss" (NOT to "-"). Reference test name: `miss_dart_preselected_in_edit_test.dart`. Assertion shape:
> ```dart
> // Throw a miss in the middle (dart 2)
> await throwDartViaMock(tester, 10);   // dart 1: S10
> await throwMissViaMock(tester);       // dart 2: Miss
> await throwDartViaMock(tester, 5);    // dart 3: S5
> await openEditScore(tester);
> // Read the dart 2 dropdown widget and assert its current value text contains "Miss"
> final dart2Dropdown = ElementFinders.getEditScoreDart2Dropdown();
> expect(dart2Dropdown, findsOneWidget);
> expect(find.descendant(of: dart2Dropdown, matching: find.text('Miss')),
>     findsOneWidget,
>     reason: 'Dart 2 (a thrown miss) should be pre-selected as "Miss" in the Edit modal');
> ```
>
> **6c. Edit Score winner/stats toggle tests (mandatory — add to every game's edit_score subdirectory):** Two tests that verify edit score correctly toggles winner state and that player stats are updated (or not) accordingly.
>
> - `edit_creates_winner_stats_test.dart` — Position the game near the win condition (programmatically or via gameplay), throw 3 non-winning darts, open Edit Score and change darts to winning values. Verify `hasWinner == true`, call `clickDartsRemoved(tester)`, then wait for results screen navigation with `await ResultsHelpers.pumpUntilResults(tester, config);` followed by a 5-second settle to let `VictoryMusicService.initialize()` and the `_updatePlayerStats()` API call finish (see Accumulated Build Quality Rules § 69, § 70 — fixed-pump chains like `pump(seconds: 4)` are forbidden here because victory navigation is now event-driven on `_audioQueue.whenIdle()` and has unbounded wall-clock latency). Pattern:
> ```dart
> await clickDartsRemoved(tester);
> await ResultsHelpers.pumpUntilResults(tester, config);
> await tester.pump(const Duration(seconds: 5));
> await tester.pump();
> await tester.pump();
> ```
> Then verify: `VictoryMusicService().isInitialized == true`, winner `gamesPlayed == 1`, winner `gamesWon == 1`, winner `gameHistory.length == 1`, winner `gameHistory.first.gameName == '[GAME_NAME_DISPLAY]'`, loser `gamesPlayed == 1`, loser `gamesWon == 0`.
>
> - `edit_removes_winner_no_stats_test.dart` — Position the game near the win condition, throw 3 darts where the **winning dart is dart 3** (not dart 1 or 2), open Edit Score and change dart 3 to a non-winning value. Verify `hasWinner == false`, call `clickDartsRemoved(tester)` (game should continue, NOT navigate to results), verify game is still active (`provider.isGameActive == true`), verify both players: `gamesPlayed == 0`, `gamesWon == 0`, `gameHistory.isEmpty`.
>
>   **CRITICAL — winning dart MUST be dart 3:** When a dart triggers a win, the game screen's `_handleDartThrow` returns early for subsequent darts (`!provider.isGameActive`), so darts 2 and 3 are never processed. The Edit Score dialog opens with only 1 dart populated and `'-'` for the rest, which disables the Save button. Always structure the dart sequence so the win triggers on the LAST dart (dart 3), ensuring all 3 darts are processed and the dialog opens with valid data for all slots.
>
>   **Examples of correct dart ordering:**
>   - Lunar Lander (altitude=10): `S3 + S3 + S4` (wins on dart 3), edit dart 3 → `S1`
>   - Clockwork Quest (target=21): `Miss + Miss + Bull` (wins on dart 3), edit dart 3 → `S1`
>   - Target Tag (P2 at 0 shields): `Miss + Miss + S(target)` (wins on dart 3), edit dart 3 → `S1`
>   - Monster Mash (opponent at 1 HP): `Miss + Miss + S(target)` (wins on dart 3), edit dart 3 → `S1`
>   - Reef Royale (6/7 targets, need 3 marks on Bull): `Miss + 25 + Bull` (wins on dart 3), edit dart 3 → `S1`
>   - Carnival Derby (target=100): `T20 + T20 + S20` = 140 (wins on dart 3), edit all → `D5` (30 pts)
>
>   **Carnival Derby additional constraint:** CD's `scoreDisplayTransform` converts segments to point values in the score display box (e.g., `S5` → "5"). This means `find.text('5')` matches both the score display AND the number button within a dart section. Use Double or Triple values (e.g., `D5` → score display "10", number button "5") to avoid the duplicate text match.
>
> **6d. Diagnostic-first test authoring (mandatory — applies to every UI test).** Every navigation-dependent `findsOneWidget` (post-tap, post-pop, after `pushReplacement` / `pushAndRemoveUntil`) MUST embed an inline `[DIAG ...]` reason string built from already-imported `ElementFinders` methods. Headless `-d web-server` mode does not pipe app stdout into the per-test log, so without this diagnostic any failure is opaque ("Multiple exceptions (2)" with no detail) and forces a re-run with added logging. **Inline at the call site — never via a new shared helper** (new shared methods have repeatedly hit "Member not found" in headless compile and block the test from running). Format: `[DIAG <label> menuStart=N gameSkip=N resultsPlayAgain=N homeCarnival=N saveModal=N resumeModal=N ...]`. See Accumulated Build Quality Rules § 15 for the canonical pattern.
>
> **6e. Save/Resume real-flow rule (mandatory).** Tests that *only verify the resume modal appears in the saved-games list* may use `preSaveGame(GameSaveConfig.[gameName]())`. Any test that actually taps Resume MUST set up the saved game via the in-game Save flow (`setupAndStartGame` → `throwDartViaMock` → `tapGameScreenBackButton` → tap Save Modal Save → look up `savedId` via `SaveGameService().loadSavedGames('[GAME_NAME_SNAKE]')`). Reason: `preSaveGame` writes a placeholder `gameState = {'_marker': 'test'}` which crashes `[GameName]Game.fromJson` on restore, producing a "Multiple exceptions (2)" failure with no detail in the headless log. Plus, every test that taps Resume must call `UITestHelpers.selectSavedGameTile(tester, savedId)` first — the Resume button is disabled until a tile is selected. See Accumulated Build Quality Rules § 17, 18.
>
> **6f. ensureVisible before tap on scrollable-content buttons (mandatory).** In headless chromedriver mode, `tester.tap` only registers a click on widgets in the visible viewport. Buttons inside a `SingleChildScrollView` (results-screen action buttons, Save Modal Save, Resume Modal Resume) need `await tester.ensureVisible(button); await tester.pump();` before `await tester.tap(button)`. Apply this in BOTH `clickPlayAgain` / `clickChangeSettings` / `clickSelectDifferentGame` shared helpers AND inline test taps. See Accumulated Build Quality Rules § 16.
>
> **7. Visual validation tests** (in `integration_test/[GAME_NAME_SNAKE]/visual_validation/`):
>
> Two categories are required: a screenshot test AND programmatic visual state tests. Together these cover both broad visual regression (screenshots) and specific UI state assertions (programmatic).
>
> **7a. Screenshot test** — `[GAME_NAME_SNAKE]_screenshot_test.dart`:
> - Capture every state listed in the spec's Testing Plan visual checklist
> - **CRITICAL:** must be runnable via `test_driver/screenshot_test.dart` as the driver
> - **CRITICAL — keep each screenshot test file UNDER 600s (10 min) total runtime.** This is the ACTUAL failure mode that bit Tiki Golf — listed first because the three structural patterns below produce a visually identical symptom and you'll waste a day chasing them if you don't check duration first. The parallel UI worker (`run_ui_tests_parallel_worker.bat:253`) polls the per-test log for done patterns for up to 600 seconds, then kills Chrome. A still-running test at 600s → framework never emits "All tests passed" → log shows only "Debug service listening" → `SocketException` at `WebDriver.quit`. **Diagnostic check (do this FIRST):** look at `DURATION=` in `integration_test_output/parallel/<game>_results.txt`. If it's near 600s, the cause is total runtime, not test structure.
>
>   **Fix when over budget:** split the screenshot test across multiple files. Both filenames must contain `"screenshot"` so the worker auto-routes both through `test_driver/screenshot_test.dart` — each `flutter drive` invocation gets its own 600s budget. Suggested cut: `<game>_screenshot_test.dart` for menu + early gameplay scenarios, `<game>_screenshot_results_test.dart` for endgame + results-screen scenarios (the slowest captures, typically including full game completions). Apply the same inline-helper patterns to every file.
>
>   **Past failure (Tiki Golf timeout):** the full screenshot test ran 698 lines / 28 captures including 2 full 9-hole rapid-completion loops. Total runtime ~12 minutes — failed silently every parallel run. Three earlier "fix" rounds (consolidate `testWidgets`, remove `_helpers.dart`, inline helper bodies) all looked plausible because the symptom is identical — only the duration told us it was the timeout. Final fix: split into `tiki_golf_screenshot_test.dart` (PARTS 1-5) + `tiki_golf_screenshot_results_test.dart` (PARTS 6-10), each well under 600s.
>
> - **PATTERN — ONE `testWidgets` block per file.** All screenshot captures go inside a single continuous `testWidgets`. Every working game's screenshot test follows this. The `integration_test_driver_extended` protocol is documented as expecting one test per file (it uses a request/response loop). Originally written as "splitting causes SocketException at `WebDriver.quit` ~14s in under parallel `-d web-server`" — that attribution traces to Tiki Golf and turned out to be the runtime timeout, not multiple `testWidgets`. The pattern is still worth following (no upside to diverging from a known-working shape).
>
> - **PATTERN — Define ALL helpers AND helper BODIES inline in the screenshot test file.** Do NOT import a sibling `_helpers.dart`. Do NOT delegate to `shared/dart_throw_helpers.dart` or `shared/game_setup_helpers.dart` — talk to `package:dart_games/services/mock_scolia_api_service.dart` directly and write out the `mockApi.simulateDartThrow(...)` / `mockApi.simulateTakeoutFinished()` calls inline. The per-test `SettingsHelpers` / `UITestHelpers` / `PumpSequences` / `ProviderHelpers` shared files ARE fine. The "cache hazard" attribution from earlier docs (`cea7027` / `4d1377e`) was based on the same Tiki Golf failure, which turned out to be the runtime timeout — so we have no isolated test case proving these specific imports cause hangs. The pattern is still worth following — every working game's screenshot test does it. The template below mirrors `integration_test/pirates_grid/visual_validation/pirates_grid_screenshot_test.dart`.
>
>   **Template** (mirror `integration_test/pirates_grid/visual_validation/pirates_grid_screenshot_test.dart`):
>   ```dart
>   import 'package:flutter/material.dart';
>   import 'package:flutter_test/flutter_test.dart';
>   import 'package:integration_test/integration_test.dart';
>   import 'package:dart_games/services/mock_scolia_api_service.dart';
>   import 'package:dart_games/constants/test_keys.dart';
>
>   import '../../shared/ui_test_helpers.dart';
>   import '../../shared/pump_sequences.dart';
>   import '../../shared/settings_helpers.dart';
>   import '../../shared/game_ui_config.dart';
>   import '../../shared/provider_helpers.dart';
>   import '../../shared/element_finders.dart';
>   // NO _helpers.dart, NO dart_throw_helpers.dart, NO game_setup_helpers.dart
>
>   // Test-local helpers with FULL BODIES inlined:
>   MockScoliaApiService? getMockApi(WidgetTester tester) {
>     final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
>     return dartboardProvider.apiService;
>   }
>
>   Future<void> throwDartViaMock(WidgetTester tester, int n,
>       {String multiplier = 'single'}) async {
>     final mockApi = getMockApi(tester);
>     if (mockApi != null) {
>       mockApi.simulateDartThrow(
>         score: n * (multiplier == 'double' ? 2 : multiplier == 'triple' ? 3 : 1),
>         multiplier: multiplier, playerName: 'Player', baseScore: n,
>         widgetX: 125.0, widgetY: 125.0, widgetSize: 250.0,
>       );
>       await tester.pump();
>       await tester.pump(const Duration(milliseconds: 500));
>       await tester.pump(); await tester.pump(); await tester.pump();
>     }
>   }
>
>   Future<void> screenshot(IntegrationTestWidgetsFlutterBinding binding,
>       WidgetTester tester, String name) async {
>     await tester.pump(const Duration(seconds: 2));
>     await tester.pump(); await tester.pump(); await tester.pump();
>     print('SCREENSHOT: Taking screenshot: $name');
>     await binding.takeScreenshot(name);
>   }
>
>   // ... any other one-off helpers (simulateTakeout, setupAndStartGame,
>   // throwAllMissesToSplash, etc.) — write each body inline here too.
>
>   void main() {
>     final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
>     final config = GameUIConfig.[GAME_NAME_CAMEL]();
>
>     group('[GAME_NAME] - Screenshot Capture', () {
>       setUp(() async {
>         await UITestHelpers.resetServerState();
>       });
>
>       // Single continuous flow capturing all spec §12C visual states.
>       testWidgets('Full screenshot flow', (WidgetTester tester) async {
>         // === PART 1: MENU SCREEN STATES ===
>         await UITestHelpers.navigateToGameMenu(tester, config);
>         await screenshot(binding, tester, '01_menu_...');
>         // ... more menu captures, settings toggles, etc.
>
>         // === PART 2: GAME SCREEN STATES ===
>         // For scenarios needing fresh state (different players / option
>         // values that conflict with PART 1), call `resetServerState()`
>         // first so addPlayer doesn't hit "player already exists".
>         await UITestHelpers.resetServerState();
>         // Inline the setup-and-start sequence (do NOT call out to
>         // GameSetupHelpers — see CRITICAL note above):
>         await UITestHelpers.navigateToGameMenu(tester, config);
>         await UITestHelpers.addPlayer(tester, '...', config);
>         // ... more addPlayer calls + any SettingsHelpers.X toggles
>         await UITestHelpers.startGame(tester, config);
>         await screenshot(binding, tester, '05_game_...');
>         // ... more captures
>
>         // ... etc — every part inside this one testWidgets
>       });
>     });
>   }
>   ```
>
>   **Reference implementations** (all confirmed to pass in parallel mode):
>   `integration_test/gladiator_arena/visual_validation/gladiator_arena_screenshot_test.dart`,
>   `integration_test/pirates_grid/visual_validation/pirates_grid_screenshot_test.dart`,
>   `integration_test/tiki_golf/visual_validation/tiki_golf_screenshot_test.dart`.
>
> - **CRITICAL:** do NOT use `pumpAndSettle()` — splash screen `CircularProgressIndicator` prevents settling. Use manual `pump()` sequences from `pump_sequences.dart`.
> - **CRITICAL state-reset pattern between scenes:** when transitioning between screen scenarios within a single test (e.g., from "default game" to "Hard Landing ON game"), use the PROGRAMMATIC reset pattern instead of fragile back-from-game user-flow navigation:
>   ```dart
>   // 1. Capture the Navigator state from a still-mounted descendant
>   //    (e.g., the game screen's Skip Turn button) BEFORE state-clearing.
>   //    Capture as NavigatorState (not BuildContext) so the reference survives
>   //    after the widget tree rebuilds.
>   final navState = Navigator.of(
>       tester.element(find.byKey([GAME_NAME_PASCAL]GameKeys.skipTurnButton).first));
>   // 2. Clear the in-memory game state (this triggers a build that removes
>   //    the game-screen widgets — that's why we captured navState first).
>   ProviderHelpers.get[GAME_NAME_PASCAL]Provider(tester).clearGame();
>   await tester.pump();
>   await tester.pump();
>   // 3. Pop everything back to home.
>   navState.popUntil((route) => route.isFirst);
>   await PumpSequences.navigation(tester);
>   // 4. Re-enter the menu fresh by tapping the home-screen card.
>   await tester.tap(config.getGameCard());
>   await PumpSequences.navigation(tester);
>   await PumpSequences.asyncDataLoad(tester);
>   ```
>   Avoid the SaveGameModal "DON'T SAVE" flow for state reset — multiple overlays + DartboardEmulatorSection in the Stack make tap propagation fragile.
>
> **7b. Programmatic visual state tests** — at minimum 4 `*_test.dart` files in `visual_validation/` covering the mandatory concerns below. Use `find.byKey`, `find.byWidgetPredicate`, and `find.descendant` to assert specific UI state (NOT screenshots). Pick filenames to match what the game actually renders:
>
> - **Dart indicator state test** — verify the per-dart score indicators (D1/D2/D3 or game's equivalent) change color/state correctly: empty → hit → miss → bust. After throwing dart 1, verify slot 1 reflects the score and slots 2/3 stay empty. After 3 darts, verify all 3 slots show their respective states. Reference: Clockwork Quest `dart_indicators_update_test.dart`.
> - **Active player highlight test** — in a 2+ player game, verify the current player is visually distinct from inactive players (border, color, badge, glow, pill — whichever the game uses). After throwing 3 darts and advancing turn, verify the highlight moves to the new current player and is removed from the previous one. Reference: Target Tag `current_player_badge_tagged_in_test.dart`.
> - **Score/state display threshold test** — verify the primary game-state indicator (score, altitude, health, marks) updates correctly after each scoring action AND that its color/severity changes when state crosses critical thresholds (e.g., negative altitude → red, low health → red, win condition → green). Reference: Monster Mash `health_bar_color_gradient_thresholds_test.dart`.
> - **Conditional UI element test** — for any game element that conditionally appears based on settings or state (e.g., Hard Landing badge, buff banner, hint overlay, win flag), verify it appears when the trigger condition is met AND is absent when not. Reference: Reef Royale `buff_banner_displays_when_active_test.dart`, Reef Royale `hint_overlay_shows_when_enabled_test.dart`.
>
> **The 4 above are the floor, not the ceiling.** If the game's spec includes additional visual mechanics (gradients, animations, multi-state badges, dynamic sizing), add one programmatic test per concern.
>
> **7c. Mandatory per-spec-Section-10 visual element coverage.** In addition to the 4 mandatory categories above and the per-option-value visual tests from 5d, every distinct visual element described in spec Section 10 (Screen Designs) requires at least one programmatic visual_validation test that asserts its appearance under its trigger condition. Build this table at the start of Phase 7 and confirm every row has a planned test file:
>   | Spec Section 10 Element | Trigger Condition | Visual Assertion | Test File |
>   |-------------------------|-------------------|------------------|-----------|
>   | (e.g., Winning row gold pulsing glow) | 3-in-a-row achieved | Treasure Gold border on 3 cells | winning_row_glow_test.dart |
>   | (e.g., P1 cell flag border) | P1 claims a cell | Blood Red border glow | cell_flag_colors_test.dart |
>   | (e.g., Round complete overlay) | Round ends in Bo3/Bo5 | "Round X Complete!" text in Treasure Gold for ~3s | round_complete_overlay_test.dart |
>
> **Past failure:** Pirate's Grid spec Section 10B describes "Winning cells get Treasure Gold pulsing glow + sparkle overlay" — no test asserted this; only logical `state == finished` was checked. Cell flag border colors (P1 Blood Red glow / P2 Sea Foam Teal glow) were undocumented in tests. Round tracker text content (`"Round 1/3 — Alice: 0  Bob: 0"`) was tested for visibility but never for content/color. The gap was caught only post-launch.
>
> **Rule of thumb:** if the spec says "X is rendered as Y" and the only test you have asserts X *exists* (via `findsOneWidget`), you are missing the visual test. Add one that asserts Y (text content, RGB color, border, icon).
>
> **8. Update ALL FOUR batch files** with the new game:
> - `run_ui_tests.bat`
> - `run_ui_tests_stub.bat`
> - `run_ui_tests_parallel.bat` — TWO places to update:
>   1. The `GAMES` variable (top of file, ~line 15) — add `[GAME_NAME_SNAKE]`
>   2. The pre-run worktree cleanup `for %%G in (...)` loop (~line 283) — add `[GAME_NAME_SNAKE]` to the hardcoded list. Without this, stale worktrees from a previous failed run for the new game won't be auto-cleaned at startup, which can cause `git worktree add` to fail and abort the entire run. Grep `run_ui_tests_parallel.bat` for the existing list of game names; both occurrences must include the new game.
> - `run_ui_tests_parallel_stub.bat` — same dual-update if the stub variant has the same hardcoded cleanup list
>
> The `GAMES` variable is misleadingly named: it's really "every top-level subdirectory under `integration_test/` that holds tests." Today that includes per-game directories (`target_tag`, `carnival_derby`, ...) AND non-game test categories (`home_screen`, `pause_modal`). When introducing a NEW non-game category — e.g. an integration test for a shared widget that doesn't belong under any one game — add the directory's name here too, exactly like a game. Each entry gets its own port + isolated server + worker slot. Directories the runners intentionally skip: `_smoke/` (manual self-tests, run via direct `flutter drive`) and `shared/` (helper files, no `*_test.dart`).
>
> Also update the port-assignment table in `docs/testing/ui-automation.md` for the new game (Server = `9000 + N`, ChromeDriver = `4443 + N`, where N is the new index).
>
> **Report back:**
> - File paths created and modified, organized by subdirectory
> - Output of `diff -rq integration_test/shared test/shared 2>&1 | grep "differ"` — must be empty (any output is a parity violation)
> - Total count of UI tests added across all subdirectories
> - Confirmation that every UI test starts with `await UITestHelpers.resetServerState();`
> - Confirmation that the 4 navigation tests, 3 results tests, and play-to-complete tests are all present (cite filenames)
> - Count of screenshot states captured
> - The diff applied to all 4 batch files
> - The diff applied to `docs/testing/ui-automation.md` port table
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Use `pumpAndSettle()` in the screenshot test
> - Use `test_driver/integration_test.dart` as the screenshot driver
> - Use `(route) => false` in any test
> - Skip `resetServerState()` in any test
> - Modify any other game's UI tests
> - Run the UI tests yourself in this phase (orchestrator runs them in Phase 8)

After the sub-agent returns:
- Run `diff -rq integration_test/shared test/shared 2>&1 | grep "differ"` and confirm the output is empty (any line is a parity violation)
- `find integration_test/[GAME_NAME_SNAKE] -type d` to confirm subdirectory layout
- `grep -rL 'resetServerState' integration_test/[GAME_NAME_SNAKE]` (must return zero — every test file must contain a `resetServerState` call)
- Confirm the 4 batch files were updated

### Step 7B: Orchestrator runs the Spec Coverage Audit

Per `docs/testing/spec-coverage-audit.md`:

**CRITICAL — Ground the audit in the IMPLEMENTATION, not the spec aspiration.** The spec describes what the game *should* render; the screen code describes what the game *does* render. These can diverge: the spec may describe an element that was deliberately simplified out during build (e.g., LL spec describes a rocket icon with flame trail; the screen renders animal characters with a Flame Orange descent line — a deliberate design pivot). Writing tests for spec elements that don't exist in code produces noise, not coverage.

For every spec element, classify it as one of three states by reading the actual code:

| State | Definition | Action |
|---|---|---|
| **Implemented + Tested** | Spec describes X. Screen renders X. ≥1 test asserts X. | None — already covered. |
| **Implemented + Not tested** | Spec describes X. Screen renders X. No test asserts X. | **GENUINE TEST GAP** — write the missing test. |
| **Not implemented** | Spec describes X. Screen does NOT render X (deliberate simplification or oversight). | **NOT a test gap** — escalate to user as a separate "spec/code divergence" decision: either implement X or update the spec to reflect the simplified design. Do NOT write tests for non-existent features. |

**How to verify "implemented":**
- For visual elements: `grep -nE '<keyword from spec>' lib/screens/games/[GAME_NAME_SNAKE]/` — does the keyword/widget appear in the screen source?
- For provider behavior: `grep -nE '<method or field>' lib/providers/[GAME_NAME_SNAKE]_provider.dart` — does the code path exist?
- For widget keys: `grep -n '<KeyName>' lib/constants/test_keys.dart` — is the key defined?

If the audit produces a gap list mixing "test gaps" and "spec/code divergences", separate them in the report — do NOT delegate "write the missing test" to a sub-agent for elements in the third category, because the test will fail by definition (the feature isn't there).

**Audit workflow:**
1. **Extract** every option from the spec's Options section, every visual element from Screen Designs, every test requirement from Testing Plan.
2. **Verify implementation** — for each spec element, grep the screen/provider/keys to confirm it exists in code. Flag any "not implemented" rows separately.
3. **Map** every non-UI test and UI test (from the actual test files) to the implemented requirements.
4. **Build** the coverage matrix:
   | Requirement | Source (spec heading) | Implemented in code? | Non-UI test(s) | UI test(s) |
   |-------------|----------------------|----------------------|----------------|------------|
5. **Identify gaps** — separate into two lists:
   - **Test gaps** (Implemented=Yes, Tests=Missing) → dispatch a Sonnet sub-agent to write
   - **Spec/code divergences** (Implemented=No) → surface to user with both options (implement vs. update spec); do NOT auto-write tests
6. Repeat until both lists are empty (test gaps closed; divergences resolved).

### Adversarial Review AR-6: Spec Coverage Matrix

> "I will now act as the Tester Agent. I will:
>
> (a) Count every test I wrote vs. every test the spec's Testing Plan requires. List any spec-required test that is missing by name.
>
> (b) For each option in the Options section, verify there is at least one non-UI test AND one UI test that exercises it. Build the matrix:
> | Option | Non-UI Test | UI Test |
> |--------|-------------|---------|
>
> (c) **Verify all FOUR batch files include the new game:** `run_ui_tests.bat`, `run_ui_tests_stub.bat`, `run_ui_tests_parallel.bat`, `run_ui_tests_parallel_stub.bat`. For `run_ui_tests_parallel.bat` SPECIFICALLY: grep for the new game name and verify it appears in BOTH (1) the `GAMES` variable AND (2) the pre-run worktree cleanup `for %%G in (...)` loop near line 272. Past failure: Lunar Lander was added to GAMES but not to the cleanup loop, leaving stale worktrees uncleaned across runs. Also verify the port-assignment table in `docs/testing/ui-automation.md` was updated.
>
> (d) Verify mirrored shared helpers stay byte-identical between `test/shared/` and `integration_test/shared/` via the dynamic-discovery audit (Rule §26): run `diff -rq integration_test/shared test/shared 2>&1 | grep "differ"`. The command emits nothing on success; any line printed is a parity violation that must be reported and fixed. The `grep "differ"` filter automatically excludes `Only in <dir>: <file>` lines for intentionally non-mirrored helpers (e.g. `mock_api_helpers.dart`, `player_test_utils.dart`, `sector_parser.dart` in `test/shared/` only). The audit picks up new helpers added since the last build without any change to the rule.
>
> (e) **Verify the 4 mandatory navigation tests exist** in `integration_test/[GAME_NAME_SNAKE]/navigation/`: menu_back_to_home, game_back_settings_persist, change_settings_back_to_home, change_settings_preserves_settings.
>
> (f) **Verify the 3 mandatory results-screen tests exist** in `integration_test/[GAME_NAME_SNAKE]/results_screen/` (or `results/` if the new game follows Clockwork Quest's pattern): exit-button (popUntil + ≥3 cards assertion), winner_stats_updated, victory_music_initialized.
>
> (g) **Verify play-to-complete tests exist** in `integration_test/[GAME_NAME_SNAKE]/play_to_complete/`: default_settings, mid_game, plus one per game-critical setting.
>
> (h) **`(route) => false` is NOT used anywhere in the new game's code or tests** (grep `lib/screens/games/[GAME_NAME_SNAKE]/` and `integration_test/[GAME_NAME_SNAKE]/`).
>
> (i) **Verify min/max player-count tests exist** in `integration_test/[GAME_NAME_SNAKE]/gameplay/`: `min_player_count_test.dart` and `max_player_count_test.dart`. Verify they exercise the actual min and max from the spec (typically 2 and 8) and that the max test asserts UI elements render without overflow.
>
> (j) **Verify the opponent display test exists** at `integration_test/[GAME_NAME_SNAKE]/gameplay/opponent_display_test.dart` and asserts BOTH visibility of inactive players' UI elements AND per-opponent state updates after their turn.
>
> (k) **Verify `visual_validation/` contains the screenshot test PLUS at least 4 programmatic visual state tests** covering the mandatory concerns: (1) dart indicator state, (2) active player highlight, (3) score/state display threshold, (4) conditional UI element. List each programmatic test file by name and the concern it covers.
>
> (l) **Build a "Visual element" coverage matrix from spec Section 10** (Screen Designs) — list every distinct UI state (e.g., "Active player track is orange", "Altitude pill turns red when negative", "Hard Landing badge appears in AppBar", "Win flag shows on results"). For each visual state, **first verify it exists in `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart`** by grep — record one of three statuses: `implemented+tested`, `implemented+missing-test`, or `not-implemented`. The first is fine; the second is a real test gap to close; the **third is NOT a test gap** — it is a spec/code divergence that must be surfaced to the user as an implementation decision (build the feature OR update the spec to reflect the simplified design). Do NOT propose tests for non-existent features. Past failure: a Lunar Lander test-coverage audit produced 5 visual_validation test recommendations for spec elements (rocket icon, ORBIT/MOON markers, tick marks, turn summary text, CRASH overlay) that did not exist in `lunar_lander_game_screen.dart` — the screen rendered animal characters with a Flame Orange descent line instead. Writing those tests would have produced 5 failing tests, not 5 closed gaps.
>
> (m) **Pause modal canonical pack count.** Run `for f in integration_test/[GAME_NAME_SNAKE]/pause_modal/{menu,gameplay,results}_pause_test.dart; do grep -c 'testWidgets(' "$f"; done` — must report **7, 8, 5** in that order (total 20). Any deviation is a failure. Past failure: Pirate's Grid had 1, 1, 1.
>
> (n) **Save/resume canonical pack count.** Run `ls integration_test/[GAME_NAME_SNAKE]/save_resume/*_test.dart | wc -l` — must report **16**. Run `for f in integration_test/[GAME_NAME_SNAKE]/save_resume/*_test.dart; do n=$(grep -c 'testWidgets(' "$f"); [ "$n" -ne 1 ] && echo "FAIL: $f has $n testWidgets (expected 1)"; done` — must report nothing (every file is exactly 1 test). Past failure: Pirate's Grid had 1 file with 6 sub-tests; Lunar Lander had similar.
>
> (o) **Per-option-value functional gameplay test coverage.** For every row in spec Section 7, build the table:
>   | Option | Value | Functional Gameplay Test File | Visual Validation Test File |
>   |--------|-------|------------------------------|------------------------------|
>   Every value of every option that has a behavioral effect MUST have an entry in BOTH columns (or note when one column is N/A — e.g., a numeric option without a visible badge has no visual_validation test). Past failures (PG): no Hard difficulty functional test; no Best Of 5 test; no Speed Play timer-expires test; no difficulty-badges visual test; no cell-flag-colors visual test; no winning-row-glow visual test; no round-tracker-text visual test; no speed-play-timer-colors visual test; no round-complete-overlay visual test.
>
> (p) **Provider game-mechanics test file exists.** `flutter test test/providers/[GAME_NAME_SNAKE]_provider_game_test.dart` — must run and pass. `grep -c '^  test(\|^    test(' test/providers/[GAME_NAME_SNAKE]_provider_game_test.dart` — must report ≥ 40 tests. Past failure: Pirate's Grid and Lunar Lander shipped without this file.
>
> (q) **Per-dart win regression coverage exists** (rule 5e). Run `ls integration_test/[GAME_NAME_SNAKE]/gameplay/win_on_early_dart_test.dart` — if present, accept. Otherwise, identify any other gameplay or UI test that throws fewer than 3 darts in the winning turn and asserts `hasWinner == true` IMMEDIATELY (grep for `expect(.*HasWinner.*isTrue` and inspect the surrounding lines for the dart count in the final turn). If no such test exists, this is a gap — write `win_on_early_dart_test.dart` per the 5e pattern. Past failure: Gladiator Arena gated win evaluation to dart 3 only and shipped without this regression test; the bug surfaced in production weeks later when a user hit a winning Double Finish on dart 1.
>
> Spec coverage: X% (N/M requirements covered)
> Missing coverage: [list]"

Report AR-6 findings. Dispatch a corrective Sonnet sub-agent for any gaps, re-audit until 100%.

### GATE 3: Spec Coverage Audit Clean + Non-UI Tests Pass (Flutter + Server)

Orchestrator runs both via Bash:
```
Gate 3: Spec Coverage + Non-UI Tests
  Spec coverage:  X% — [PASS only if 100% / FAIL otherwise]
  Flutter tests:  X/Y passing — [PASS/FAIL]
  Server tests:   X/Y passing — [PASS/FAIL]
  OVERALL:        [PASS/FAIL]
```
Commands:
- `flutter test`
- `cd server && dart test`

If FAIL: dispatch sub-agents for missing tests / fixes, re-audit, re-run BOTH suites. Repeat until PASS.

---
