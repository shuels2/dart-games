<!-- game.build Phase 11 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 11: Documentation and Definition of Done

**Goal:** Create all game documentation, update project files, verify Definition of Done.

**Model:** **Tier 3** (Sonnet) for documentation authoring + CLAUDE.md / testing docs updates; **Tier 0** (orchestrator) for AR-8 + Gate 5. **Definition of Done tracking:** use the DoD schema from **[Playbook §8]** so every DoD item has an evidence file+line reference before Gate 5.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 11 (Documentation) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — every section (you'll cite specifics in the docs)
> - Section map from Phase 0: [PASTE]
> - `docs/games/_GAME_TEMPLATE/` — every file in this directory is a template you must fill out
> - At least one existing game's docs for tone/depth reference (e.g., `docs/games/target-tag/`)
> - `CLAUDE.md`, `docs/testing/test-overview.md`, `docs/testing/non-ui-tests.md`, `docs/testing/ui-automation.md`, `docs/DOCUMENTATION_STRUCTURE.md`
>
> **Naming reminders:**
> - The DOCS directory uses **hyphens**: `docs/games/[GAME_NAME_HYPHEN]/`
> - The CODE / asset / test directories use **underscores**: `lib/screens/games/[GAME_NAME_SNAKE]/`, `assets/games/[GAME_NAME_SNAKE]/`, `test/screens/games/[GAME_NAME_SNAKE]/`, `integration_test/[GAME_NAME_SNAKE]/`
> - Class names use **PascalCase**: `[GAME_NAME_PASCAL]`
> - Display name is human-readable: `[GAME_NAME_DISPLAY]`
> - **Do NOT mix conventions** — use the right one for each path/identifier.
>
> **Tasks:**
>
> **1. Capture real test counts BEFORE updating docs:**
> Run all three test commands and capture the exact counts:
> ```
> flutter test
> cd server && dart test
> ./run_ui_tests.bat [GAME_NAME_SNAKE]
> ```
> Record: total flutter non-UI count, total server count, this game's UI count broken down by subdirectory (add_player, edit_score, gameplay, menu_and_settings, navigation, play_to_complete, results, save_resume, visual_validation). For `visual_validation` further break out into `screenshot: 1` and `programmatic: N` so future audits can verify the programmatic-test floor (4 minimum). These are the real numbers — do NOT estimate.
>
> **2. Copy the template directory** (using PowerShell-compatible command since the project runs on Windows):
> ```
> Copy-Item -Recurse docs/games/_GAME_TEMPLATE/ docs/games/[GAME_NAME_HYPHEN]/
> ```
> (Or use the Bash tool's `cp -r` if running via Bash.)
>
> **3. Fill out all 8 template files in `docs/games/[GAME_NAME_HYPHEN]/`:**
> - `README.md` — overview, quick facts, player count, file locations, key features
> - `game-rules.md` — objective, setup, turn structure, scoring, win conditions, edge cases
> - `design-system.md` — color palette with hex codes, typography, screen styling, animations
> - `components.md` — fill in (a) every dartboard / dialog / modal config factory method with parameters, (b) **the "Play to Complete" section with the strategy class and `PlayToCompleteButtonConfig` factory** (this section is now mandatory in `_GAME_TEMPLATE/components.md` lines 173-213, not optional), and (c) the "Custom Components" section if the game introduces game-specific widgets (e.g., a custom button or panel)
> - `announcements.md` — every announcement event with priorities, sound effects, stacking rules
> - `testing.md` — REAL test counts from step 1 (broken down by subdirectory). **Fill in the new template sections** (`_GAME_TEMPLATE/testing.md` lines 219-285): the **"Play to Complete Tests"** section (per-game-critical-setting list with file names) and the **"Navigation Tests"** section (4 required files, helper file template, test name examples). Also document widget keys and test patterns.
> - `assets.md` — complete asset inventory with descriptions
> - `implementation-notes.md` — provider pattern, model design, algorithms, gotchas; **include the Play-to-Complete strategy** and any non-obvious save/resume detail
>
> Replace ALL placeholder markers (`{{PLACEHOLDER}}` or `[Placeholder]`) with actual values. Do NOT leave any unfilled.
>
> **4. Update `CLAUDE.md`:**
> - Add new game to the Games section in the Documentation Index (with link `docs/games/[GAME_NAME_HYPHEN]/` and one-line description)
> - Update total test counts (flutter + server + UI) in the "Current Test Counts" section using the REAL numbers from step 1
> - Add game-specific test run commands in "Run Game-Specific Tests" using `[GAME_NAME_SNAKE]`
> - Update the file structure section to add the new code directory
> - Update the "Last Updated" date
>
> **5. Update `docs/testing/test-overview.md`** with new test counts and breakdown.
>
> **6. Update `docs/testing/non-ui-tests.md`** with new test details.
>
> **7. Update `docs/testing/ui-automation.md`** with new UI test counts (per subdirectory) and the parallel-runner port assignment for the new game.
>
> **8. Update `docs/DOCUMENTATION_STRUCTURE.md`** with the new game docs directory.
>
> **Report back:**
> - File paths created and modified
> - The exact line(s) added to each updated file (so the orchestrator can verify)
> - Confirmation that no placeholder markers remain — run all of:
>   - `grep -rn '{{' docs/games/[GAME_NAME_HYPHEN]/`
>   - `grep -rn '\[Game Name\]\|\[GameName\]\|\[N\]\|\[Placeholder\]' docs/games/[GAME_NAME_HYPHEN]/`
>   (both must return zero matches)
> - The captured real test counts from step 1
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Modify any code files
> - Skip any of the 8 template files
> - Leave any placeholder markers unfilled
> - Estimate test counts — capture real numbers via running the tests

After the sub-agent returns:
- Run `grep -rn '{{' docs/games/[GAME_NAME_HYPHEN]/` yourself to confirm zero matches
- Run `grep -rn '\[Game Name\]\|\[GameName\]\|\[Placeholder\]' docs/games/[GAME_NAME_HYPHEN]/` to confirm zero matches
- Read at least the README and one rules file for quality

### Adversarial Review AR-8: Final Full Review (orchestrator)

> "I will now do a final adversarial review of the entire game implementation:
>
> (a) Re-read the spec's Options section. For every option listed, I will examine the game screen code and verify it has a VISIBLE effect. I will list each option and where its effect appears.
>
> (b) Re-read the spec's Definition of Done section (or the canonical checklist in `docs/development/adding-games.md` if the spec lacks a DoD section). For every item, I will verify it is GENUINELY complete — not assumed, not planned, but done. I will list each item with evidence.
>
> (c) Verify game characters are NOT used as player avatars (Rule 10). Grep for any code that assigns character images to player avatar slots:
>    `grep -rn 'characters/' lib/screens/games/[GAME_NAME_SNAKE]/` (filter to player tile / avatar widget contexts).
>
> (d) Verify the results screen calls `playerProvider.batchUpdatePlayerStats([...])` exactly once with one `PlayerStatsUpdate` per player (winners AND losers), all sharing the SAME `gameDuration`. Verify no `for (... in playerIds) await playerProvider.updatePlayerStats(...)` loop remains (per finding A1 in `docs/perf-audits/2026-05-05-full.md`).
>
> (e) Verify the correct PlayerListPanel pattern (Dual vs Team) matches the spec's Overview, AND that Team config lives in `team_player_list_panel_config.dart` (not `dual_player_list_panel_config.dart`).
>
> (f) Verify all 3 AppBars are styled consistently (back button + title + DartboardConnectionInfo, with ResumeGameButton to the LEFT of DartboardConnectionInfo on menu).
>
> (g) Verify **`announceRemoveDarts` is called UNCONDITIONALLY** in the game-screen takeout handler (not gated by precedence winner). Cite line.
>
> (h) Verify **`_deleteResumedSavedGame()` runs INDEPENDENTLY in `addPostFrameCallback`** on the results screen (not awaited inline after `_updatePlayerStats()`). Cite line.
>
> (i) Verify **`(route) => false` is NOT used** anywhere in the new game's code:
>    `grep -rn '(route) => false' lib/screens/games/[GAME_NAME_SNAKE]/ integration_test/[GAME_NAME_SNAKE]/`
>    Must return zero matches.
>
> (j) Verify **Play-to-Complete is fully wired**: strategy at `lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart`, `PlayToCompleteButtonConfig.[gameName]()` factory, runner field on game-screen state, runner disposed in `dispose()`, and play-to-complete tests in `integration_test/[GAME_NAME_SNAKE]/play_to_complete/`.
>
> (k) Verify **the home-screen card** uses `HomeKeys.[gameName]Card`, references the correct icon path, and routes to the correct named route.
>
> (l) Verify **all 4 navigation tests + 3 results tests** exist and were exercised by the most recent UI test run.
>
> (m) Grep for any TODO, FIXME, HACK, or stub code in ALL new game files:
>    `grep -rn 'TODO\|FIXME\|HACK\|stub' lib/screens/games/[GAME_NAME_SNAKE]/ lib/models/[GAME_NAME_SNAKE]* lib/providers/[GAME_NAME_SNAKE]* lib/services/[GAME_NAME_SNAKE]* lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart`
>
> (n) Verify no existing game code or tests were broken — only additive changes (other than adding entries to the shared config files, the home_screen, main.dart routes, and the 4 batch files). Check `git diff master...HEAD` for unexpected modifications.
>
> (o) Verify CLAUDE.md test counts were updated using REAL numbers (Phase 11 step 1) — not estimates. The flutter test count, server test count, and UI test count for this game must match the latest test run output.
>
> (p) Verify all 4 batch files include the new game and `docs/testing/ui-automation.md` port table was updated.
>
> Issues found: [list each with severity]"

Report AR-8 findings. Dispatch a corrective Sonnet sub-agent for any issues found.

### Adversarial Review AR-9: Cross-Game Consistency Review (orchestrator)

**Goal:** Hold the finished new game up next to two reference games and report any divergence in code shape, test patterns, visual style, or documentation depth. This catches "passes the spec, but doesn't look like the rest of the codebase" issues that no spec-driven AR would catch — house style, helper usage, widget tree shape, test naming conventions, visual density, doc structure.

**Reference games (read all three before producing the report):**
- `target_tag` — mature, canonical pattern (longest-lived game implementation)
- `clockwork_quest` — newest, most complete subdirectory layout in tests + docs

**Severity scale:**
- **High:** divergence likely indicates a bug or missing integration — must fix
- **Medium:** stylistic drift that future maintainers will trip over — should fix
- **Low:** intentional difference justified by spec — note the justification, no action needed

> "I will now compare the new [GAME_NAME_DISPLAY] game to the two reference games (`target_tag` + `clockwork_quest`) across five dimensions. For each dimension, I will read the actual files for ALL THREE games and produce a divergence report.
>
> **(a) Provider / model code shape**
> - List every public method on `[GAME_NAME_PASCAL]Provider` and compare to the method lists of `TargetTagProvider` and `ClockworkQuestProvider`. Flag any common method missing on the new provider, and any unique method on the new one not justified by the spec's mechanics.
> - Compare field naming conventions (e.g., `_currentPlayerIndex` vs. `_currentPlayerIdx` — does the new game match house style?)
> - Compare constructor signatures, `notifyListeners()` placement, `toJson` / `fromJson` patterns, and game-duration tracking.
> - Compare model field structures and serialization conventions.
> - Cite divergences with file:line references.
>
> **(b) Screen widget tree shape**
> - For each of the three screens (menu, game, results), compare the top-level Scaffold/Column/Row/Stack structure and the AppBar configuration to the reference games.
> - Check padding/spacing — does the new game use shared constants where the reference games do, or hard-coded numbers?
> - Check shared widget integration order and position (e.g., DartboardEmulator at bottom — same position? Same padding around it?)
> - Check button styling, font sizes, color application — same pattern as references?
> - Cite divergences.
>
> **(c) Test organization and helper usage**
> - Compare the subdirectory layout of `integration_test/[GAME_NAME_SNAKE]/` to `integration_test/target_tag/` and `integration_test/clockwork_quest/`. Are all the same subdirectories present? Same file naming?
> - For each shared helper (`ProviderHelpers`, `ElementFinders`, `PumpSequences`, `GameUiConfig`, `SettingsHelpers`, `ResultsHelpers`, `DartThrowHelpers`, `EditScoreHelpers`, `GameSetupHelpers`, `PlayToCompleteHelpers`, `UITestHelpers`), grep the new game's tests and the reference tests — does the new game USE the same helpers in the same proportions, or is it reinventing patterns inline?
> - Compare test file naming conventions and test-name strings (`test('player can ...', ...)` style) — same voice across games?
> - Compare non-UI test organization in `test/screens/games/[GAME_NAME_SNAKE]/` and `test/providers/`, `test/models/`.
> - Cite divergences with file:line references and grep counts.
>
> **(d) Visual consistency**
> - Read the new game's most recent screenshots from `temp_screenshots/` and compare against canonical screenshots of the reference games. If the reference games' screenshots are not currently captured, run them via `flutter drive --driver=test_driver/screenshot_test.dart --target=integration_test/target_tag/visual_validation/target_tag_screenshot_test.dart -d chrome` (and the equivalent for clockwork_quest) before comparing.
> - Check: typographic scale (heading/body size ratios), spacing density (does the new game look more cramped or more sparse than references?), color saturation level relative to its palette, button proportions, panel proportions, AppBar height, dartboard emulator section height.
> - Family-friendly visual scale and information density should be consistent with the reference games. A game that looks visibly busier or sparser than the others is a Medium issue minimum.
> - Cite divergences with screenshot file names.
>
> **(e) Documentation depth and structure**
> - For each of the 8 docs in `docs/games/[GAME_NAME_HYPHEN]/`, compare section count, section names (in order), and approximate depth/length to the corresponding files in `docs/games/target-tag/` and `docs/games/clockwork-quest/`.
> - Flag any new-game doc that has materially fewer sections, shallower content, or skipped optional sections that the reference games include (e.g., a missing 'Custom Components' section in `components.md` if both references have one).
> - Compare `implementation-notes.md` for parity — does the new game's notes file cover similar ground (provider pattern, save/resume, gotchas, Play-to-Complete strategy)?
> - Cite divergences with file references.
>
> **Divergence report:**
>
> | Dim | Item | Severity | Reference behavior | New game behavior | Justification (if Low) |
> |-----|------|----------|--------------------|--------------------|------------------------|
> | (a) | ...  | H/M/L    | ...                | ...                | ...                    |
> | (b) | ...  | H/M/L    | ...                | ...                | ...                    |
> | (c) | ...  | H/M/L    | ...                | ...                | ...                    |
> | (d) | ...  | H/M/L    | ...                | ...                | ...                    |
> | (e) | ...  | H/M/L    | ...                | ...                | ...                    |
>
> **Action:** for every High and Medium divergence, dispatch a corrective Sonnet sub-agent with the specific file/line and the fix needed (the sub-agent prompt must cite the reference game's pattern and explain why the new game should match). Re-run AR-9 after fixes to confirm zero High/Medium divergences remain. Low (intentional, justified) divergences pass.
>
> AR-9 result: [PASS / FAIL]
> - High divergences: [count]
> - Medium divergences: [count]
> - Low (justified) divergences: [count]"

Report AR-9 findings. Iterate (corrective sub-agent → re-run AR-9) until zero High/Medium divergences remain.

### GATE 5: Definition of Done

Verify EVERY item:

**Functional Completeness:**
- [ ] All Options-section options implemented with visible effects
- [ ] All shared widgets integrated
- [ ] All config factory methods created (including `PlayToCompleteButtonConfig`)
- [ ] All infrastructure integrated (PlayerProvider, announcer, victory music, dartboard)
- [ ] **Play-to-Complete strategy + button + runner wired**
- [ ] All assets present and referenced (with correct naming convention)
- [ ] Announcement helper with stacking prevention; `announceRemoveDarts` called unconditionally
- [ ] Game characters NOT used as player avatars
- [ ] No `(route) => false` in any Navigator call
- [ ] Home-screen card with `HomeKeys.[gameName]Card` and correct icon
- [ ] Menu screens, `team_player_list_panel.dart`, `dual_player_list_panel.dart`, and `options_screen.dart` guard every `await playerProvider.<method>()` with `if (!mounted) return;` before subsequent provider/setState/context use (Accumulated Build Quality Rules § 72)

**Testing:**
- [ ] Flutter non-UI tests pass (count: real)
- [ ] Server tests pass (count: real)
- [ ] UI test files in subdirectory layout (add_player/, edit_score/, gameplay/, menu_and_settings/, navigation/, play_to_complete/, results_screen/ [or results/], save_resume/, visual_validation/)
- [ ] **4 mandatory navigation tests present and passing**
- [ ] **3 mandatory results-screen tests present and passing**
- [ ] **2 mandatory edit score winner/stats tests present and passing** (`edit_creates_winner_stats_test.dart`, `edit_removes_winner_no_stats_test.dart`)
- [ ] **Play-to-complete tests present and passing**
- [ ] **2 mandatory player-count tests present and passing** (`min_player_count_test.dart`, `max_player_count_test.dart`)
- [ ] **Mandatory opponent display test present and passing** (`opponent_display_test.dart`)
- [ ] **Game-with-announcements integration test present and passing** (`[game]_game_with_announcements_test.dart`)
- [ ] **Pause modal tests present and passing** (3 files in `pause_modal/`: `menu_pause_test.dart`, `gameplay_pause_test.dart`, `results_pause_test.dart`)
- [ ] **Visual validation contains screenshot test PLUS at least 4 programmatic tests** (dart indicators, active player highlight, score/state threshold, conditional UI)
- [ ] All 4 batch files updated (run_ui_tests, run_ui_tests_stub, run_ui_tests_parallel, run_ui_tests_parallel_stub)
- [ ] All mirrored shared helpers synchronized (`diff -rq integration_test/shared test/shared 2>&1 | grep "differ"` returns empty)
- [ ] Every UI test calls `resetServerState()`
- [ ] `SettingsHelpers.resetServerState` PUTs `voice_enabled=false` after the test reset (Accumulated Build Quality Rules § 68)
- [ ] Every post-victory wait uses `ResultsHelpers.pumpUntilResults(tester, config)` — no fixed `pump(seconds: 4)`-style chains between game completion and a results-screen assertion (§ 69)
- [ ] `VictoryMusicService().isInitialized` / `gamesPlayed` / `gamesWon` assertions are preceded by `pumpUntilResults` + a 5 s settle + 2 bare pumps, in that order (§ 70)
- [ ] Screenshot / showcase tests use the inline 300-iteration poll loop with the game's Play Again finder as the break condition (§ 71)
- [ ] No intermediate-state assertions ("results screen not yet loaded", `gamesPlayed == 0` after `clickDartsRemoved`) — tests verify the FINAL state (§ 74)
- [ ] Every popup / dropdown / overlay-dismiss tap in tests is followed by `tester.pump(const Duration(milliseconds: 200))` + bare pump — never bare `pump(); pump();` chains around animations (§ 73)

**Visual Validation:**
- [ ] Screenshot test created and executed (with chromedriver sync + server start)
- [ ] Every screenshot evaluated against checklist
- [ ] All visual issues fixed and re-verified
- [ ] Zero visual issues remaining
- [ ] No Nunito or Flame Orange leakage

**Documentation:**
- [ ] CLAUDE.md updated with REAL test counts
- [ ] All 8 game doc files created (no placeholders remaining)
- [ ] Custom Components section filled in components.md (if applicable)
- [ ] Testing docs updated (test-overview, non-ui-tests, ui-automation, parallel port table)
- [ ] DOCUMENTATION_STRUCTURE.md updated

**Cross-Game Consistency (AR-9):**
- [ ] Provider/model code shape matches house style
- [ ] Screen widget tree shape consistent with references
- [ ] Victory announcement fires ONLY from `_handleGameWon()` (never from dart-throw handler)
- [ ] Winning dart still gets its per-dart announcement (not suppressed by hasWinner)
- [ ] Victory navigation uses `whenIdle()` + 250ms (no fixed 3000ms delay)
- [ ] Test organization and helper usage match references
- [ ] Visual consistency with reference games verified
- [ ] Documentation depth and structure parity with references
- [ ] Speed Play timer deferred until turn announcement finishes (if applicable)
- [ ] Zero High/Medium divergences (Low/justified divergences allowed)

Present the full Definition of Done checklist to the user with PASS/FAIL for each item.

---
