<!-- game.build Phase 3 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 3: Core Game Logic

**Goal:** Create the game model, provider, and core game logic with tests.

**Model:** **Tier 3** (Sonnet) for model + provider + tests; **Tier 0** (orchestrator) for AR-3 + Gate 1 verification. **After test authoring:** run **[Playbook §10 — Test-smell reviewer]** (Tier 2, Sonnet) on the new test files to catch `pumpAndSettle`-and-pass patterns before they land.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 3 (Core Game Logic) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on the "Rules & Mechanics" section, the "Game Options & Settings" section (every option must be implemented in the provider), and the "Testing Plan" section (game-logic test list).
> - Section map: [PASTE SECTION MAP TABLE]
> - At least one existing game's model + provider + tests for reference patterns:
>   - `lib/models/target_tag_game.dart`
>   - `lib/providers/target_tag_provider.dart`
>   - `test/screens/games/target_tag/target_tag_game_test.dart`
> - `docs/development/save-resume-game.md` for serialization conventions.
> - `docs/development/data-migrations.md` — note: when `updatePlayerStats` throws, the failure is auto-logged via `/api/v1/stats/failed` (handled in `PlayerProvider`); do NOT swallow exceptions silently.
>
> **Files to create:**
> 1. `lib/models/[GAME_NAME_SNAKE]_game.dart`
>    - All fields per the spec's mechanics
>    - `toJson()` and `fromJson()` for save/resume
>    - Serialization rules: enums as `.name`, `Set<int>` as `List<int>`, `Map<int, int>` as `Map<String, int>`, `totalDartsThrown` and `totalTurns` as per-player maps
> 2. `lib/providers/[GAME_NAME_SNAKE]_provider.dart`
>    - `startGame()`, `processDartThrow()`, `advanceTurn()`, `checkWinCondition()`
>    - Every option from the spec's Options section must have a code path that consumes it. Add a comment near the code citing the option name.
>    - `saveGame()`, `restoreGame()`, `resumedSavedGameId`, `clearResumedSavedGameId()`
>    - Game duration tracking via `_gameStartTime` and `endGame()`
>    - **Standard turn increment rule (mandatory — applies to every game):** `totalTurns[playerId]` is incremented EXACTLY ONCE per turn — at the moment the player throws their FIRST dart of that turn. It is NEVER incremented elsewhere (not on the last dart, not in `advanceToNextPlayer`, not on takeout). Canonical pattern (in `processDartThrow`, after computing the dart but before applying it):
>      ```dart
>      if (game.dartsThrown[playerId] == 1) {
>        game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
>      }
>      ```
>      Reference: `target_tag_game.dart:347-352` (`_incrementTurnIfFirst`). The model MUST NOT also increment `totalTurns` in `advanceToNextPlayer` — that double-counts and breaks the "Landed in X turns" / "Won in N turns" displays.
>    - **Asset path source of truth:** the model's `assetPath` getter for any character / variant enum MUST read paths from the Phase 1 manifest at `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md`, NOT from the spec's original asset paths. The spec may have used pre-rename names (e.g., `space_dog.png`) that no longer exist on disk after Phase 1's renaming pass. Always cross-reference the manifest.
> 3. `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_test.dart`
>    - Every test listed in the spec's Testing Plan game-logic section
>    - At least one test per Options-section option exercising its effect
> 4. `test/providers/[GAME_NAME_SNAKE]_provider_game_test.dart` (**MANDATORY** — every other game has one; missing it is a coverage hole)
>    - Pure-provider game-mechanics tests (no widget pumping). Construct provider directly, call methods, assert state.
>    - **Minimum 40 tests** (canonical games range 44–50: HorseRace 50, ClockworkQuest 49, MonsterMash 44, ReefRoyale 45, TargetTag 45). The screen-level `_game_test.dart` is NOT a substitute — that file tests via the screen wrapper; this file isolates provider logic so regressions surface clearly when the screen changes.
>    - Required groups (one or more `group(...)` blocks):
>      - **Initial state** — `isGameActive` before/after `startGame`, randomized layout invariants (if applicable), default-state assertions
>      - **`processDartThrow` per difficulty/option** — for each option-value combination from spec Section 7 that affects the dart-processing path, a group with hit/miss/edge cases. (Pirate's Grid example: Easy / Medium / Hard groups, each with hit-claims-cell and miss-no-claim cases.)
>      - **Turn advancement** — advances after 3 darts, `skipTurn` forfeits + advances, dart counter resets per turn, `processDartThrow` no-ops when `state == finished`
>      - **Win detection** — every win path the game supports (rows, columns, diagonals, score thresholds, elimination, etc.); plus draw/no-winner end conditions
>      - **Per-option side-effects** — for each on/off toggle and dropdown value from spec Section 7, one or more tests asserting the provider state change (e.g., Steal Mode replaces opponent flag; Hard Landing reduces altitude differently; Speed Mode advances turn on time)
>      - **Round / match transitions** (best-of, multi-round games) — round increment, alternating starting player, match-end on threshold
>      - **`_resetTurnForPlayer` / edit-score replay** — undoes ALL win side-effects including match-level (`matchWinnerId`, `isMatchDraw`, `state`, `gameEndTime`, round counters); see Accumulated Build Quality Rules § 20
>      - **Randomized targets / shuffled state** (if applicable) — invariants on the randomized state across new games
>      - **`endGame` and resumed save id tracking** — `endGame` clears active flag; `resumedSavedGameId` tracks the source save id
>
> **Verification:**
> - Run `flutter test test/screens/games/[GAME_NAME_SNAKE]/ test/providers/[GAME_NAME_SNAKE]_provider_game_test.dart`
> - Confirm 100% pass rate on BOTH
>
> **Report back:**
> - File paths created
> - Number of tests written
> - Test results (X/Y passing)
> - A coverage table mapping each Options-section option to (a) the provider method that consumes it and (b) the test that exercises it
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Modify any files outside the four created above
> - Modify any existing game's code
> - Create the screens (those come in Phase 4)
> - Skip running the tests
> - Swallow exceptions in `updatePlayerStats` calls (the platform auto-logs failures via `/api/v1/stats/failed`)
> - **Skip authoring `[GAME_NAME_SNAKE]_provider_game_test.dart`** — Lunar Lander and Pirate's Grid both shipped without it (only realized post-launch via the test-count gap audit). Every game needs this file; treat it as a Phase 3 hard requirement, not optional.

After the sub-agent returns, read `lib/providers/[GAME_NAME_SNAKE]_provider.dart` yourself and verify Options-section coverage independently before AR-3.

### Adversarial Review AR-3: Options Coverage

> "I will now cross-reference every option from the spec's Options section against the provider code and tests. For each option I will list it by name and verify:
> (a) The provider has logic that handles this option (cite the method/line)
> (b) There is at least one test that exercises this option (cite the test name)
> (c) **Turn increment rule:** `grep -n 'totalTurns' lib/models/[GAME_NAME_SNAKE]_game.dart lib/providers/[GAME_NAME_SNAKE]_provider.dart` — the increment (`totalTurns[...] = ... + 1`) MUST appear in EXACTLY ONE place: the provider's `processDartThrow` guarded by `if (game.dartsThrown[playerId] == 1)`. Any increment in `advanceToNextPlayer` or anywhere else is a double-count bug.
> (d) **Asset paths in model match Phase 1 manifest:** for every enum value in the model with an `assetPath` getter, the returned path MUST exist on disk. Run `flutter test test/screens/games/[GAME_NAME_SNAKE]/` — if any character image fails to load, the unit tests still pass (they don't load images). The check is: read the model file and grep each `return 'assets/...'` path, then confirm the file exists.
> (e) **`test/providers/[GAME_NAME_SNAKE]_provider_game_test.dart` exists with ≥ 40 tests.** This is the dedicated provider-game-mechanics test file (separate from screen-level `_game_test.dart`). Run `grep -c '^  test(\|^    test(' test/providers/[GAME_NAME_SNAKE]_provider_game_test.dart` — must report ≥ 40. The file MUST cover every option-value combination from spec Section 7 that affects dart-processing in its own group, plus the standard groups listed in Phase 3 file #4 (initial state, turn advancement, win detection, round transitions, `_resetTurnForPlayer` undo, `endGame`). Past failure: Lunar Lander and Pirate's Grid both shipped without this file; the gap was caught only by a manual cross-game test-count audit weeks later.
>
> Coverage matrix:
> | Option | Provider Logic | Screen-level Test | Provider-level Test |
> |--------|---------------|-------------------|---------------------|
> | [name] | [method]      | [test name]       | [test name]         |
>
> Every row must have BOTH a screen-level test AND a provider-level test. I will report any option that lacks either, plus any turn-increment double-count, any model assetPath that doesn't exist on disk, or absence of `[GAME_NAME_SNAKE]_provider_game_test.dart`."

Report AR-3 findings. Dispatch a corrective Sonnet sub-agent for any gaps before proceeding.

### GATE 1: Core Logic Tests Pass

Run `flutter test test/screens/games/[GAME_NAME_SNAKE]/` directly via Bash (orchestrator) and report:
```
Gate 1: Core Logic Tests
  Result: X/Y tests passing — [PASS/FAIL]
```
If FAIL: present failures to the user per `docs/critical-rules/test-failures.md`, get the user's choice (fix code vs. update tests), dispatch a Sonnet sub-agent with the specific fix, re-run. Do NOT proceed until this gate passes.

---
