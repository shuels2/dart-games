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

# PIPELINE: 11 Phases, 7 Gates (5 Hard + 2 Approval), 8 Adversarial Reviews

You MUST execute phases in order. You MUST NOT skip phases. You MUST NOT proceed past a gate until it passes. You MUST execute every adversarial review checkpoint and report the findings before continuing.

At the start of each phase, print:
```
=== Phase X of 10: [Phase Name] ===
Gates passed: X/5 (+ X/2 approvals) | ARs completed: X/8
```

---

## Model Strategy (Two-Model Architecture)

This skill runs as an **orchestrator** on the parent model (intended to be Opus) and **delegates implementation work to Sonnet sub-agents** via the Agent tool. The orchestrator handles all reasoning, judgment, critique, and gate decisions; sub-agents handle bulk coding and mechanical execution.

**Orchestrator (this thread — Opus) handles directly:**
- All phase orchestration, gate decisions, and "fix code or update tests?" questions
- Phase 0 spec analysis and build plan
- All 8 adversarial reviews (AR-1 through AR-8)
- Phase 5 announcement stacking analysis (the *design* of precedence, before implementation)
- Phase 6 data migration decision
- Phase 7 spec coverage audit
- Phase 8 Step 2 screenshot evaluation against the visual checklist
- Phase 9 simultaneous-pass verification
- Test failure root-cause analysis

**Sonnet sub-agents (spawned via Agent tool) handle:**
- Phase 1 asset verification + pubspec updates
- Phase 2 HTML/CSS wireframe authoring
- Phase 3 game model + provider + core tests
- Phase 4 screens + config factory methods + widget keys + main.dart wiring
- Phase 5 sound effects service + announcement helper code (with stacking rules from orchestrator as input)
- Phase 6 serialization + save/restore tests
- Phase 7 UI test files + screenshot test + shared helper sync + batch file updates
- Phase 8 Step 1 (chromedriver lifecycle + screenshot test execution), Step 4 fixes, Steps 5/7 (running UI + non-UI tests)
- Phase 10 documentation files + CLAUDE.md and testing docs updates

### Delegation Pattern

When delegating to a Sonnet sub-agent, invoke the Agent tool with:

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: 3–5 word task summary
- `prompt`: a **self-contained** prompt — the sub-agent has none of this conversation's context

Every delegation prompt MUST include:
1. The exact spec file path and the specific spec sections to read (cite section numbers)
2. The project rule files to read (cite paths under `docs/`)
3. Every file to create or modify, with full absolute paths
4. The acceptance criteria (what "done" looks like)
5. What to report back (the orchestrator needs concrete evidence, not vague summaries)
6. Hard limits ("do NOT modify files outside this list", "do NOT skip running `flutter pub get`")

Each phase below contains a **Sub-agent prompt template** — fill in the placeholders (`[spec_path]`, `[game_name]`, `[branch_name]`, etc.) before invoking.

### Verify Sub-Agent Work

After a Sonnet sub-agent returns, **do not trust its summary**. Before proceeding:
- Read the actual files it claims to have created or modified.
- Run `git status` and `git diff` to see the real changes.
- Spot-check at least one file to confirm the content matches the prompt's acceptance criteria.

If the sub-agent's actual output diverges from what was requested, send the sub-agent a follow-up message (via the Agent tool's resume mechanism, or by spawning a corrective sub-agent) with the specific gap.

### Adversarial Reviews Stay on the Orchestrator

ARs are independent critiques of the implementer's work. Run them on the orchestrator (Opus) using the prompt blocks already in each phase. Do NOT delegate ARs to a sub-agent — losing the conversation context (the build plan, prior findings) weakens the critique. If a particular AR needs deeper independence, you may spawn a *fresh Opus sub-agent* with `model: "opus"` and a self-contained briefing, but this is optional.

---

## Phase 0: Initialization and Spec Analysis

**Goal:** Load the spec, extract all requirements, present the build plan, get user approval.

**Model:** Orchestrator (Opus) handles all of Phase 0 directly — this is the highest-stakes analysis in the pipeline.

### Steps

1. Read the full spec file from the provided path.
2. Read `CLAUDE.md` to load all current project rules and test counts.
3. Read `docs/development/adding-games.md` for the 19-step checklist.
4. Read `docs/development/game-integration.md` for the integration checklist.
5. Read `docs/critical-rules/visual-validation.md` for the visual validation rules.
6. Read `docs/testing/spec-coverage-audit.md` for the audit procedure.
7. Extract from the spec and **retain in context for later sub-agent prompts**:
   - **Section 1:** Game name, player count, player list pattern (Dual vs Team).
   - **Section 2:** Color palette (exact hex codes), fonts (Google Fonts names), style.
   - **Section 4:** Full asset checklist (images, sounds, file paths).
   - **Section 5/6:** Game rules and mechanics.
   - **Section 7:** Options table — every option, default, values, and expected game screen effect.
   - **Section 9:** Announcement events table.
   - **Section 10:** Screen designs (Menu, Game, Results) — all widget keys, shared widgets, layout.
   - **Section 11:** New config factory methods needed.
   - **Section 12:** Testing plan — all non-UI tests, all UI tests, visual validation checklist.
   - **Section 13:** Agent team responsibilities.
   - **Section 14:** Definition of Done checklist (every item).
   - **Section 15:** Development workflow and branch strategy.
   - **Section 18:** Files summary — all new files and all existing files to modify.
8. Create one task per phase using TaskCreate. Mark Phase 0 in_progress.
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

**Goal:** Verify all game assets are in place, update pubspec.yaml, ensure the dev branch exists.

**Model:** Sonnet sub-agent for verification + pubspec changes; orchestrator (Opus) for AR-1.

### Delegate to Sonnet sub-agent

Invoke `Agent` with `subagent_type: "general-purpose"`, `model: "sonnet"`, `description: "Phase 1 asset setup"`, and the prompt template below — fill in the placeholders.

**Sub-agent prompt template:**

> You are completing Phase 1 (Asset Setup) for the **[GAME_NAME]** game build in the Dart Games Flutter project.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on Section 4 (Asset Checklist) and Section 15 (branch strategy).
> - `docs/development/asset-organization.md`
>
> **Tasks (in order):**
> 1. Run `git branch --show-current`. If the current branch is not `[BRANCH_NAME]`, run `git checkout -b [BRANCH_NAME]` (only if it doesn't already exist; otherwise `git checkout [BRANCH_NAME]`).
> 2. Verify the asset folder structure exists under `assets/games/[GAME_NAME]/` with the subdirectories required by spec Section 4 (typically `icons/`, `images/`, `characters/`, `sounds/`).
> 3. For every asset listed in spec Section 4, verify the file exists at the expected path. Build a table:
>    | Asset (spec) | Expected path | PRESENT / MISSING |
> 4. If ANY asset is MISSING, do NOT continue. Stop and report the missing list.
> 5. Read `pubspec.yaml`. If the game's asset directories are not listed under `flutter.assets`, add them in alphabetical order with the existing games.
> 6. Run `flutter pub get` and confirm exit code 0.
>
> **Report back:**
> - The asset present/missing table from step 3
> - The diff applied to `pubspec.yaml` (or "no changes needed")
> - The output of `flutter pub get`
> - The active git branch
>
> **Do NOT:**
> - Modify any files outside `pubspec.yaml`
> - Create any placeholder asset files
> - Skip `flutter pub get`

After the sub-agent returns, run `git status` and read the modified `pubspec.yaml` yourself to confirm.

### Adversarial Review AR-1: Asset Verification

Run this on the orchestrator before proceeding:

> "I will now verify the sub-agent's work against spec Section 4. For every asset listed in the spec, I will re-read the file system and pubspec.yaml to confirm:
> (a) The file exists at the correct path with the correct filename
> (b) The pubspec.yaml includes the asset directory
> (c) No assets are in the wrong subdirectory (e.g., character images in sounds/)
> (d) No spec assets were overlooked
>
> I will list every discrepancy found."

Report AR-1 findings. If discrepancies exist, dispatch a corrective Sonnet sub-agent with the specific gaps before proceeding.

---

## Phase 2: Wireframe Mockups

**Goal:** Create HTML/CSS wireframe mockups of all game screens so the user can review the visual design and layout BEFORE any game code is written. This catches layout problems, UX issues, and misunderstandings of the spec early — when changes are free.

**Model:** Sonnet sub-agent for HTML/CSS authoring; orchestrator (Opus) for AR-2 + WIREFRAME APPROVAL GATE.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 2 (Wireframe Mockups) for the **[GAME_NAME]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on Section 1 (player count + Dual/Team pattern), Section 2 (color palette and fonts — use exact hex codes and Google Fonts names), Section 7 (options table), Section 10 (screen designs), Section 11 (shared components).
>
> **Output directory:** `temp_wireframes/[GAME_NAME]/`
>
> **Files to create:** Each screen must be shown at multiple player counts to validate scaling. For a game supporting min M / max N players, create wireframes at min, max, and at least one count in between.
>
> Required wireframes:
> - `menu_Xp.html` for each player count variant (M, mid, N)
> - `game_early_Xp.html` for each player count variant
> - `game_midgame_Xp.html` for each player count variant
> - `game_modals.html` (one file is sufficient — shows Remove Darts modal + Edit Score button + Dartboard Paused modal + Save Game modal)
> - `results_Xp.html` for each player count variant
> - `index.html` linking to all wireframes with brief descriptions
>
> **Each Menu wireframe must show:**
> - AppBar with back button, game title, DartboardConnectionInfo placeholder, ResumeGameButton
> - Player list panel (Dual or Team per spec Section 1) populated with the appropriate number of sample player entries for that variant
> - All settings controls from Section 7 (toggles, dropdowns, sliders) with labels and default values
> - Start Game button with enable/disable state
> - Layout proportions matching the container app pattern
>
> **Each Game-Early wireframe must show:**
> - AppBar with back button, game title, DartboardConnectionInfo placeholder
> - Game board / play area with all visual elements from Section 10B
> - Player indicators showing the appropriate number of players at early game state
> - Score / progress displays
> - Skip Turn button
> - Dartboard emulator section at BOTTOM of screen
> - Visual representation of every option's effect from Section 7
>
> **Each Game-Midgame wireframe must show:**
> - Same layout as early game but with mid-game state
> - Show progression (scores advanced, game elements changed)
>
> **Game-modals wireframe must show:**
> - Game screen with Remove Darts modal overlay (including Edit Score button inside the modal)
> - Dartboard Paused modal state
> - Save Game modal (back-button triggered)
>
> **Each Results wireframe must show:**
> - Winner display with character/avatar
> - Full player rankings with stats for all players at that count
> - Play Again, Change Settings, Back to Menu buttons
> - AppBar with game title, DartboardConnectionInfo placeholder
>
> **Hard rules for every HTML file:**
> - Use the game's actual color palette from spec Section 2 (exact hex codes — no "approximate" colors)
> - Use Google Fonts links for the game's typography from spec Section 2
> - Self-contained: inline CSS, no external dependencies beyond Google Fonts
> - Responsive: use flexbox/grid, look correct at 1280x800 (primary target)
> - Realistic placeholder content (player names, scores, etc.)
> - Label shared components clearly (e.g., "DartboardEmulatorSection", "RemoveDartsModal")
> - Show every option from Section 7 and where its visual effect appears on the game screen
>
> **Report back:**
> - The full list of files created (file paths)
> - A coverage table mapping each spec Section 7 option to (a) where its menu control appears and (b) where its game-screen effect is shown
> - Any spec ambiguities you had to resolve and how

After the sub-agent returns, list the files yourself and spot-check at least the menu wireframe at one player count and the game-early wireframe at one player count.

### Adversarial Review AR-2: Wireframe Completeness

> "I will now verify the wireframes against the spec before presenting them to the user:
>
> (a) Every screen from spec Section 10 has a wireframe (Menu, Game, Results)
> (b) Every option from Section 7 has a visible control on the menu wireframe AND a visible effect on the game wireframe
> (c) Every shared component from Section 11 is labeled and positioned on the correct screen
> (d) The color palette matches spec Section 2 exactly (hex codes match)
> (e) The typography matches spec Section 2 (correct Google Fonts loaded)
> (f) The player list panel type (Dual vs Team) matches spec Section 1
> (g) The game wireframe shows at least two game states (early and mid/late) to demonstrate progression
> (h) Modal overlays are shown (Remove Darts, Save Game, Dartboard Paused)
> (i) Every screen type (Menu, Game Early, Game Mid/Late, Results) has wireframes at the minimum player count, maximum player count, AND at least one count in between
>
> Wireframe coverage:
> | Screen/State | Wireframe File | Section 10 Match | Player Counts Shown |
> |-------------|----------------|------------------|---------------------|
> | [screen]    | [file]         | [YES/MISSING]    | [e.g., 2, 5, 8]    |
>
> Missing elements: [list any gaps]"

Report AR-2 findings. Dispatch a corrective Sonnet sub-agent for any gaps before presenting to the user.

### WIREFRAME APPROVAL GATE

Present the wireframes to the user:
- List all wireframe files created
- Tell the user to open `temp_wireframes/[game_name]/index.html` in their browser
- Ask the user to review each screen and provide feedback

**STOP and wait for user feedback on the wireframes.**

The user may:
- **Approve** — proceed to Phase 3
- **Request changes** — dispatch a corrective Sonnet sub-agent with the specific feedback, present again, wait for approval
- **Request major redesign** — dispatch a Sonnet sub-agent with the redesign brief, present again

Do NOT proceed to Phase 3 until the user explicitly approves the wireframe designs. This is the cheapest place to catch design issues — before any code is written.

---

## Phase 3: Core Game Logic

**Goal:** Create the game model, provider, and core game logic with tests.

**Model:** Sonnet sub-agent for model + provider + tests; orchestrator (Opus) for AR-3 + Gate 1 verification.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 3 (Core Game Logic) for the **[GAME_NAME]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on Section 5/6 (rules and mechanics), Section 7 (options table — every option must be implemented in the provider), Section 12A (game logic test list).
> - At least one existing game's model + provider + tests for reference patterns:
>   - `lib/models/target_tag_game.dart`
>   - `lib/providers/target_tag_provider.dart`
>   - `test/screens/games/target_tag/target_tag_game_test.dart`
> - `docs/development/save-resume-game.md` for serialization conventions.
>
> **Files to create:**
> 1. `lib/models/[GAME_NAME]_game.dart`
>    - All fields per spec Section 5/6 mechanics
>    - `toJson()` and `fromJson()` for save/resume
>    - Serialization rules: enums as `.name`, `Set<int>` as `List<int>`, `Map<int, int>` as `Map<String, int>`, `totalDartsThrown` and `totalTurns` as per-player maps
> 2. `lib/providers/[GAME_NAME]_provider.dart`
>    - `startGame()`, `processDartThrow()`, `advanceTurn()`, `checkWinCondition()`
>    - Every option from spec Section 7 must have a code path that consumes it (cite the option name in a comment near the code that uses it)
>    - `saveGame()`, `restoreGame()`, `resumedSavedGameId`, `clearResumedSavedGameId()`
>    - Game duration tracking via `_gameStartTime` and `endGame()`
> 3. `test/screens/games/[GAME_NAME]/[GAME_NAME]_game_test.dart`
>    - Every test listed in spec Section 12A game-logic section
>    - At least one test per Section 7 option exercising its effect
>
> **Verification:**
> - Run `flutter test test/screens/games/[GAME_NAME]/`
> - Confirm 100% pass rate
>
> **Report back:**
> - File paths created
> - Number of tests written
> - Test results (X/Y passing)
> - A coverage table mapping each Section 7 option to (a) the provider method that consumes it and (b) the test that exercises it
>
> **Do NOT:**
> - Modify any files outside the three created above
> - Modify any existing game's code
> - Create the screens (those come in Phase 4)
> - Skip running the tests

After the sub-agent returns, read `lib/providers/[GAME_NAME]_provider.dart` yourself and verify Section 7 option coverage independently before AR-3.

### Adversarial Review AR-3: Options Coverage

> "I will now cross-reference every option from spec Section 7 against the provider code and tests. For each option I will list it by name and verify:
> (a) The provider has logic that handles this option (cite the method/line)
> (b) There is at least one test that exercises this option (cite the test name)
>
> Coverage matrix:
> | Option | Provider Logic | Test Coverage |
> |--------|---------------|---------------|
> | [name] | [method]      | [test name]   |
>
> I will report any option that lacks either provider logic or test coverage."

Report AR-3 findings. Dispatch a corrective Sonnet sub-agent for any gaps before proceeding.

### GATE 1: Core Logic Tests Pass

Run `flutter test test/screens/games/[game_name]/` directly via Bash (orchestrator) and report:
```
Gate 1: Core Logic Tests
  Result: X/Y tests passing — [PASS/FAIL]
```
If FAIL: present failures to the user per `docs/critical-rules/test-failures.md`, get the user's choice (fix code vs. update tests), dispatch a Sonnet sub-agent with the specific fix, re-run. Do NOT proceed until this gate passes.

---

## Phase 4: Screens and UI

**Goal:** Create all three screens with full visual theming and shared component integration.

**Model:** Sonnet sub-agent for screens + config factories + key registration + main.dart wiring; orchestrator (Opus) for AR-4.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 4 (Screens and UI) for the **[GAME_NAME]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on Section 1 (Dual vs Team panel), Section 2 (colors + fonts), Section 7 (option controls and effects), Section 10 (screen designs A/B/C with widget keys), Section 11 (config factory methods).
> - `docs/architecture/shared-systems.md`
> - `docs/development/game-integration.md`
> - `docs/development/widget-keys.md`
> - At least one existing game's screens for reference (e.g., `lib/screens/games/target_tag/`)
> - The wireframes you produced in Phase 2: `temp_wireframes/[GAME_NAME]/`
>
> **Tasks:**
>
> **1. Add widget keys to `lib/constants/test_keys.dart`:**
> - `[GameName]MenuKeys` — every key from spec Section 10A
> - `[GameName]GameKeys` — every key from spec Section 10B
> - `[GameName]ResultsKeys` — every key from spec Section 10C
>
> **2. Create config factory methods (one per file — these are existing files, ADD to them):**
> - `AddPlayerDialogConfig.[gameName]()` in `lib/widgets/add_player/add_player_dialog_config.dart`
> - `EditScoreDialogConfig.[gameName]()` in `lib/widgets/edit_score/edit_score_dialog_config.dart`
> - `DartboardSectionConfig.[gameName]()` and `DartboardFABConfig.[gameName]()` in `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`
> - `DualPlayerListPanelConfig.[gameName]()` OR `TeamPlayerListPanelConfig.[gameName]()` in `lib/widgets/player_list_panel/dual_player_list_panel_config.dart` (per spec Section 1)
> - `RemoveDartsModalConfig.[gameName]()` in `lib/widgets/remove_darts_modal/remove_darts_modal_config.dart`
> - `DartboardConnectionInfoConfig.[gameName]()` in `lib/widgets/dartboard_connection_info/dartboard_connection_info_config.dart`
> - `DartboardPausedModalConfig.[gameName]()` in `lib/widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart`
> - `SaveGameModalConfig.[gameName]()` in `lib/widgets/save_game_modal/save_game_modal_config.dart`
> - `ResumeGameModalConfig.[gameName]()` in `lib/widgets/resume_game_modal/resume_game_modal_config.dart`
>
> **3. Create `lib/screens/games/[GAME_NAME]/[GAME_NAME]_menu_screen.dart`:**
> - Use the correct PlayerListPanel per spec (Dual vs Team)
> - All settings from Section 7 with correct controls (toggles, dropdowns, sliders) bound to provider state
> - Add Player Dialog integration
> - DartboardConnectionInfo in AppBar
> - ResumeGameButton in AppBar
> - ResumeGameModal overlay (Stack pattern)
> - Start button enable/disable logic (min players per Section 1)
>
> **4. Create `lib/screens/games/[GAME_NAME]/[GAME_NAME]_game_screen.dart`:**
> - Game board / play area per Section 10B layout
> - DartboardEmulatorSection at BOTTOM of the screen
> - DartboardEmulatorFAB
> - RemoveDartsModal overlay (including Edit Score button inside the modal — do NOT add a custom remove-darts button outside the modal)
> - DartboardPausedModal overlay
> - SaveGameModal (back button + PopScope pattern)
> - Skip turn button
> - DartboardConnectionInfo in AppBar
> - All option effects visible per Section 7 (use Section 7's "expected game screen effect" column to verify each one renders)
>
> **5. Create `lib/screens/games/[GAME_NAME]/[GAME_NAME]_results_screen.dart`:**
> - Winner display + rankings
> - Victory music integration via VictoryMusicService
> - Player stats update (`updatePlayerStats`) for ALL players (winners AND losers) with the SAME `gameDuration` value
> - Auto-delete saved game on completion
> - Play Again, Change Settings, Back to Menu buttons
> - DartboardConnectionInfo in AppBar
>
> **6. Add the game card to `lib/screens/home_screen.dart`.**
>
> **7. Register the provider in `lib/main.dart` MultiProvider, and add routes for the three new screens.**
>
> **8. Run `flutter test` to verify no regressions across the full suite.**
>
> **Report back:**
> - File paths created and modified
> - The full text of each new factory method (for orchestrator review)
> - Test results from `flutter test` (X/Y passing)
> - Confirmation that game characters are NOT used as player avatars (per spec Rule 10)
>
> **Do NOT:**
> - Modify the dartboard emulator code (`lib/widgets/dartboard_emulator/dartboard_emulator.dart` core logic) — only add config entries
> - Modify any other game's screens or providers
> - Add a custom "remove darts" button outside RemoveDartsModal
> - Use game characters as player avatars
> - Skip running `flutter test`

After the sub-agent returns, run `git diff lib/main.dart` and read each new screen file yourself before AR-4.

### Adversarial Review AR-4: Integration Audit

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

Report AR-4 findings. Dispatch a corrective Sonnet sub-agent for any gaps before proceeding.

---

## Phase 5: Announcement and Sound System

**Goal:** Implement the full announcement system with stacking prevention.

**Model:** Orchestrator (Opus) designs the stacking precedence; Sonnet sub-agent implements the helper, sounds, and tests; orchestrator (Opus) runs AR-5 to verify the implementation matches the design.

### Step 5A: Orchestrator designs stacking precedence (BEFORE delegation)

Before invoking the sub-agent, work through the worst-case stacking analysis on the orchestrator. This is the design that the implementer will follow:

1. List every announcement event in spec Section 9.
2. Identify the worst-case dart throw — the single dart that could trigger the most simultaneous events.
3. Define the precedence order: which event wins when multiple fire on the same dart.
4. Confirm the rule: max 2 announcements per dart (1 moment + Remove Darts), and "Remove your darts" is NEVER suppressed.
5. Document the precedence chain as numbered rules — this becomes input to the sub-agent prompt.

### Step 5B: Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 5 (Announcement and Sound System) for the **[GAME_NAME]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on Section 4 (sound files with start/end times) and Section 9 (announcement events table).
> - `docs/development/announcement-system.md`
> - At least one existing game's announcement helper for reference (e.g., `lib/services/target_tag_announcement_helper.dart`)
>
> **Stacking precedence rules (from orchestrator design — IMPLEMENT EXACTLY):**
>
> [PASTE NUMBERED PRECEDENCE RULES FROM STEP 5A]
>
> Hard rules:
> - Max 2 announcements fire per dart event (1 moment announcement + Remove Darts)
> - "Remove your darts" is NEVER suppressed regardless of what else triggers
> - Use the "gather facts, pick winner" pattern: collect every event the dart triggered, then select one moment announcement based on the precedence chain
>
> **Files to create:**
> 1. `lib/services/[GAME_NAME]_sound_effects.dart` — every sound file from spec Section 4 + Section 9 with correct start/end times
> 2. `lib/services/[GAME_NAME]_announcement_helper.dart` — every announcement event from spec Section 9 with correct priority levels and sound effect associations, implementing the stacking precedence rules above
> 3. `test/mocks/mock_[GAME_NAME]_audio_queue_service.dart`
> 4. `test/screens/games/[GAME_NAME]/[GAME_NAME]_announcement_test.dart`
>    - Every test from spec Section 12A announcement section
>    - A test verifying max 2 announcements fire on the worst-case dart
>    - A test verifying "Remove your darts" always plays (cannot be suppressed)
>
> **Files to modify:**
> - `lib/screens/games/[GAME_NAME]/[GAME_NAME]_game_screen.dart` — wire the announcement helper into dart processing
>
> **Verification:**
> - Run `flutter test test/screens/games/[GAME_NAME]/`
> - Confirm 100% pass rate
>
> **Report back:**
> - File paths created and modified
> - The full text of the precedence selection method in the announcement helper
> - The test name(s) covering the worst-case stacking scenario
> - Test results (X/Y passing)

After the sub-agent returns, read `lib/services/[GAME_NAME]_announcement_helper.dart` yourself and trace the precedence implementation against your Step 5A design.

### Adversarial Review AR-5: Announcement Stacking Analysis

> "I will now verify the implementation matches the precedence design. I will:
>
> (a) Re-state the worst-case dart scenario from Step 5A
> (b) List all events that this worst-case dart could trigger simultaneously
> (c) Trace through the announcement helper code (the actual Dart code, not memory) to verify the precedence chain correctly suppresses lower-priority events
> (d) Count how many announcements would actually fire for this worst case
> (e) Verify the count does not exceed 2 (1 moment + Remove Darts)
> (f) Verify 'Remove your darts' is NEVER suppressed regardless of what else triggers
> (g) Verify there is a test that covers this worst-case scenario, and that the test asserts both the count limit and Remove-Darts presence
>
> Worst-case scenario: [describe]
> Events triggered: [list]
> Announcements that fire: [count] — [PASS if <=2 / FAIL if >2]
> 'Remove your darts' suppressed: [YES/NO — must be NO]"

Report AR-5 findings. Dispatch a corrective Sonnet sub-agent for any issues before proceeding.

---

## Phase 6: Save/Resume and Data Migration

**Goal:** Verify save/resume is fully wired, decide on migration needs, write the remaining serialization tests.

**Model:** Orchestrator (Opus) for migration decision and verification of existing wiring; Sonnet sub-agent for serialization + save/restore test authoring; orchestrator runs Gate 2.

### Step 6A: Orchestrator verifies wiring and decides on migration

Verify on the orchestrator (read the actual files):
1. `toJson()` / `fromJson()` exist in the game model (from Phase 3).
2. `saveGame()`, `restoreGame()`, `resumedSavedGameId`, `clearResumedSavedGameId()` exist in the provider (from Phase 3).
3. `SaveGameModalConfig` and `ResumeGameModalConfig` factory methods exist (from Phase 4).
4. SaveGameModal is integrated into the game screen with PopScope + Stack (from Phase 4).
5. ResumeGameModal is integrated into the menu screen with Stack (from Phase 4).
6. Auto-delete logic in the results screen's player stats update (from Phase 4).

Read `docs/development/data-migrations.md` and decide:
- If the new game only adds new tables/columns and optional fields with defaults → **no migration needed**.
- If any existing columns or table shapes change → **migration required**. (For a new game following the standard pattern, this is rare — the game lives in its own model.)

Document the migration decision (with reasoning) before continuing.

### Step 6B: Delegate test authoring to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 6 (Save/Resume Tests) for the **[GAME_NAME]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — Section 12A serialization + save/restore tests
> - `lib/models/[GAME_NAME]_game.dart`
> - `lib/providers/[GAME_NAME]_provider.dart`
> - At least one existing game's serialization tests for reference (e.g., `test/models/target_tag_game_serialization_test.dart`)
>
> **Migration decision from orchestrator:** [PASTE DECISION + REASONING]
> [If migration required: include the migration spec the sub-agent should implement.]
>
> **Files to create:**
> 1. `test/models/[GAME_NAME]_serialization_test.dart` — round-trip toJson/fromJson tests covering every field including the tricky ones (enums, Sets, Maps with int keys, per-player maps)
> 2. `test/providers/[GAME_NAME]_save_restore_test.dart` — provider save/restore lifecycle tests
>
> **Verification:**
> - Run `flutter test test/models/[GAME_NAME]_serialization_test.dart test/providers/[GAME_NAME]_save_restore_test.dart`
> - Confirm 100% pass rate
> - Then run the full `flutter test` suite to verify no regressions
>
> **Report back:**
> - File paths created
> - Number of serialization round-trip tests
> - Number of save/restore tests
> - Full `flutter test` results (X/Y passing across the entire suite)

### GATE 2: Full Non-UI Test Suite Passes

Run `flutter test` (ALL non-UI tests across all games) directly via Bash on the orchestrator and report:
```
Gate 2: Full Non-UI Test Suite
  Result: X/Y total tests passing — [PASS/FAIL]
```
If FAIL:
- Analyze failures per `docs/critical-rules/test-failures.md` on the orchestrator (root-cause reasoning is Opus work).
- Present to user: "Tests failed. (A) Fix application code, or (B) Update tests?"
- Wait for user decision. Do NOT auto-fix tests.
- Dispatch a Sonnet sub-agent with the specific fix per user choice, re-run. Repeat until PASS.

---

## Phase 7: UI Automation Tests and Spec Coverage Audit

**Goal:** Write all UI tests, synchronize shared helpers, run the mandatory spec coverage audit.

**Model:** Sonnet sub-agent for shared helper sync + UI test files + screenshot test + batch file updates; orchestrator (Opus) for the spec coverage audit + AR-6 + Gate 3.

### Step 7A: Delegate UI test infrastructure to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 7 (UI Automation Tests) for the **[GAME_NAME]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — Section 12B (UI test list) and Section 12C (screenshot test states)
> - `docs/testing/test-maintenance.md` — **CRITICAL: shared helper synchronization rules**
> - `docs/testing/ui-automation.md`
> - `docs/testing/continuous-animations.md` — `pumpAndSettle()` rules
> - At least one existing game's UI tests for reference (e.g., `integration_test/target_tag/`)
> - `test_driver/screenshot_test.dart` (the correct driver — DO NOT use `test_driver/integration_test.dart`)
>
> **Tasks:**
>
> **1. Update shared test helpers in BOTH locations (mandatory synchronization):**
>
> Update these files in `test/shared/`:
> - `element_finders.dart` — add game-specific finders
> - `game_ui_config.dart` — add game config
> - `provider_helpers.dart` — add provider helpers
> - `settings_helpers.dart` — add settings helpers
> - `ui_test_helpers.dart` — add UI helpers
>
> Apply IDENTICAL changes to `integration_test/shared/`:
> - `element_finders.dart`
> - `game_ui_config.dart`
> - `provider_helpers.dart`
> - `settings_helpers.dart`
> - `ui_test_helpers.dart`
>
> After editing, run `diff` between each pair to verify they are byte-identical (apart from the path, the contents must match).
>
> **2. Create UI test files in `integration_test/[GAME_NAME]/`:**
> - `[GAME_NAME]_add_player_test.dart`
> - `[GAME_NAME]_menu_and_settings_test.dart`
> - `[GAME_NAME]_gameplay_test.dart`
> - `[GAME_NAME]_edit_score_test.dart`
> - `[GAME_NAME]_results_test.dart`
> - `[GAME_NAME]_save_resume_test.dart`
>
> Every test from spec Section 12B must be implemented. Use widget keys from `lib/constants/test_keys.dart` (added in Phase 4).
>
> **3. Create `integration_test/[GAME_NAME]/[GAME_NAME]_screenshot_test.dart`:**
> - Capture every state listed in spec Section 12C
> - **CRITICAL:** must be runnable via `test_driver/screenshot_test.dart` as the driver
> - **CRITICAL:** do NOT use `pumpAndSettle()` — splash screen `CircularProgressIndicator` prevents settling. Use manual `pump()` sequences.
>
> **4. Update `run_ui_tests.bat` AND `run_ui_tests_stub.bat` with new game entries.**
>
> **Report back:**
> - File paths created and modified
> - For each pair of shared helpers (`test/shared/X.dart` vs `integration_test/shared/X.dart`), report whether `diff` shows them byte-identical
> - Total count of UI tests added (across all 6 files)
> - Count of screenshot states captured by the screenshot test
> - The diff applied to `run_ui_tests.bat` and `run_ui_tests_stub.bat`
>
> **Do NOT:**
> - Use `pumpAndSettle()` in the screenshot test
> - Use `test_driver/integration_test.dart` as the screenshot driver
> - Modify any other game's UI tests
> - Run the UI tests yourself in this phase (the orchestrator runs them in Phase 8)

After the sub-agent returns, run `diff test/shared/element_finders.dart integration_test/shared/element_finders.dart` (and the other 4 pairs) yourself to confirm synchronization.

### Step 7B: Orchestrator runs the Spec Coverage Audit

Per `docs/testing/spec-coverage-audit.md`:

1. **Extract** every option from spec Section 7, every visual element from Section 10, every test requirement from Section 12.
2. **Map** every non-UI test and UI test (from the actual test files) to these requirements.
3. **Build** the coverage matrix:
   | Requirement | Source (spec section) | Non-UI test(s) | UI test(s) |
   |-------------|----------------------|----------------|------------|
   | [option/element/state] | [section] | [test file:name or MISSING] | [test file:name or MISSING] |
4. **Identify gaps** — any row where Non-UI or UI is MISSING.
5. If gaps exist, dispatch a Sonnet sub-agent with the specific missing tests to write. Re-audit after.
6. Repeat until 100% coverage.

### Adversarial Review AR-6: Spec Coverage Matrix

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

Report AR-6 findings. Dispatch a corrective Sonnet sub-agent for any gaps, re-audit until 100%.

### GATE 3: Spec Coverage Audit Clean + Non-UI Tests Pass

Orchestrator runs `flutter test` directly via Bash:
```
Gate 3: Spec Coverage + Non-UI Tests
  Spec coverage:  X% — [PASS only if 100% / FAIL otherwise]
  Non-UI tests:   X/Y passing — [PASS/FAIL]
  OVERALL:        [PASS/FAIL]
```
If FAIL: dispatch sub-agents for missing tests / fixes, re-audit, re-run. Repeat until PASS.

---

## Phase 8: Visual Validation

**Goal:** Execute the FULL iterative validation cycle from `docs/critical-rules/visual-validation.md`. This phase contains the complete visual + UI + non-UI verification loop.

**Model split:**
- **Sonnet sub-agent:** Step 1 (chromedriver lifecycle + screenshot test execution), Step 4 fixes, Step 5 (run UI tests), Step 7 (run flutter test).
- **Orchestrator (Opus):** Step 2 (read every screenshot + evaluate against checklist), Step 3 (report findings), Step 4 decision, Step 6 decision, Step 8 decision, AR-7. **Visual evaluation is the highest-value Opus work in this skill — never delegate it.**

**CRITICAL UNDERSTANDING:** "Screenshot test passed" does NOT mean "visual validation complete." A passing test only means screenshots were captured without runtime errors. The actual validation is reading and evaluating every screenshot against the checklist. These are two completely separate steps — NEVER conflate them.

### The Iterative Validation Cycle

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

### STEP 1: CAPTURE (Sonnet sub-agent)

**Sub-agent prompt template:**

> You are running the screenshot capture for the **[GAME_NAME]** game.
>
> **Read first:**
> - `docs/critical-rules/visual-validation.md`
> - `docs/testing/ui-automation.md`
> - `run_ui_tests.bat` (for the established launch pattern — match it)
>
> **Tasks:**
> 1. Kill any running `chromedriver.exe` processes via `taskkill /F /IM chromedriver.exe` (NEVER kill `chrome.exe` — that triggers Chrome crash recovery state).
> 2. Start chromedriver in the background: `cd chromedriver/chromedriver-win64 && ./chromedriver.exe --port=4444`
> 3. Wait 5 seconds for chromedriver to initialize.
> 4. Run the screenshot test:
>    ```
>    flutter drive --driver=test_driver/screenshot_test.dart --target=integration_test/[GAME_NAME]/[GAME_NAME]_screenshot_test.dart -d chrome
>    ```
>    **CRITICAL:** Use `test_driver/screenshot_test.dart` — NEVER `test_driver/integration_test.dart` (will hang silently on `takeScreenshot()`).
>    **CRITICAL:** Do NOT use `--no-headless`.
> 5. Confirm all screenshots saved to `temp_screenshots/`.
>
> **Report back:**
> - The list of every screenshot file found in `temp_screenshots/` (filename + size)
> - Any errors from chromedriver or `flutter drive`
>
> **Do NOT:**
> - Kill `chrome.exe`
> - Use `--no-headless`
> - Use `pumpAndSettle()`
> - Read or evaluate the screenshots — that's the orchestrator's job

If the screenshot test fails to run, the orchestrator STOPs and asks the user. Do NOT skip.

---

### STEP 2: EVALUATE every screenshot (orchestrator only — Opus)

**Visual evaluation MUST stay on the orchestrator. Do NOT delegate this step.**

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

### STEP 3: REPORT findings (orchestrator)

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
- For each issue, identify the specific code change needed (orchestrator decides the fix).
- Dispatch a Sonnet sub-agent with the full fix list as a self-contained brief — include the screenshot filename, the specific issue, the file/line to change, and the desired result.
- After the sub-agent returns, **go back to STEP 1.** Re-capture AND re-evaluate ALL screenshots — fixes can have unintended effects on other screens.

**NO (issues = 0):**
- Continue to STEP 5.

---

### STEP 5: Run UI automation tests (Sonnet sub-agent)

**Sub-agent prompt template:**

> Run the UI automation tests for the **[GAME_NAME]** game and report results.
>
> Run: `./run_ui_tests.bat [GAME_NAME]`
>
> Report back:
> - Total tests run
> - Pass/fail count
> - Full failure output for any failing tests (test name + error message + relevant stack trace)
> - Total runtime
>
> Do NOT attempt to fix failing tests — only report them.

If chromedriver is not available or tests cannot run:
- Orchestrator STOPs immediately.
- Tell the user which tests cannot run and why.
- Ask the user how to proceed.
- Do NOT skip. Do NOT proceed without running them.

---

### STEP 6: UI tests fail? (orchestrator decision)

**YES (any failures):**
- Orchestrator analyzes failures (root-cause reasoning).
- Present to user per `docs/critical-rules/test-failures.md`: "Tests failed. (A) Fix application code, or (B) Update tests?"
- Wait for user decision. Do NOT auto-fix tests.
- Dispatch a Sonnet sub-agent with the specific fix per user choice.
- **Go back to STEP 1.** Screenshots may have changed due to fixes.

**NO (all pass):**
- Continue to STEP 7.

---

### STEP 7: Run flutter test (Sonnet sub-agent or orchestrator)

This runs ALL non-UI tests across ALL games, not just the new one. Either path is fine — Sonnet sub-agent for cleaner parallelism, or orchestrator running `flutter test` directly via Bash for simplicity.

---

### STEP 8: Non-UI tests fail? (orchestrator decision)

**YES (any failures):**
- Orchestrator analyzes failures.
- Present to user per `docs/critical-rules/test-failures.md`.
- Wait for user decision. Dispatch a Sonnet sub-agent with the fix.
- **Go back to STEP 1.** Start the entire cycle over.

**NO (all pass):**
- Continue to STEP 9.

---

### STEP 9: All pass simultaneously

All three conditions are now true at the same time:
- Visual validation: zero issues
- UI automation tests: 100% pass
- Non-UI tests: 100% pass

Proceed to AR-7.

---

### Adversarial Review AR-7: Validation Completeness (orchestrator)

**Before leaving Phase 8, answer every question honestly. If any answer is "no", go back and complete the missing step.**

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

## Phase 9: Simultaneous Pass Verification

**Goal:** Confirm all four completion conditions are true at the same time, including the spec coverage audit.

**Model:** Orchestrator (Opus) — verification only.

### Steps

1. Confirm spec coverage audit is still clean (from Phase 7). If any code changed during Phase 8 (likely from visual/test fixes), re-run the spec coverage audit on the orchestrator to verify it's still 100%.
2. Confirm visual validation completed with zero issues (from Phase 8).
3. Confirm UI automation tests passed in the most recent cycle (from Phase 8).
4. Confirm non-UI tests passed in the most recent cycle (from Phase 8).

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
- Fix the failing component (dispatch Sonnet sub-agent for code fixes).
- Re-run ALL FOUR checks (not just the fixed one — a fix can break others).
- Repeat until all four pass simultaneously.

If a check CANNOT be run:
- **STOP immediately.**
- Tell the user which check cannot be run and why.
- Ask the user how to proceed.
- **Do NOT skip the check. Do NOT proceed without it.**

---

## Phase 10: Documentation and Definition of Done

**Goal:** Create all game documentation, update project files, verify Definition of Done.

**Model:** Sonnet sub-agent for documentation file authoring + CLAUDE.md / testing docs updates; orchestrator (Opus) for AR-8 + Gate 5.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 10 (Documentation) for the **[GAME_NAME]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — every section (you'll cite specifics in the docs)
> - `docs/games/_GAME_TEMPLATE/` — every file in this directory is a template you must fill out
> - At least one existing game's docs for tone/depth reference (e.g., `docs/games/target-tag/`)
> - `CLAUDE.md`, `docs/testing/test-overview.md`, `docs/testing/non-ui-tests.md`, `docs/testing/ui-automation.md`, `docs/DOCUMENTATION_STRUCTURE.md`
>
> **Tasks:**
>
> **1. Copy the template directory:**
> ```
> docs/games/_GAME_TEMPLATE/  →  docs/games/[GAME-NAME]/
> ```
>
> **2. Fill out all 8 template files in `docs/games/[GAME-NAME]/`:**
> - `README.md` — overview, quick facts, player count, file locations, key features
> - `game-rules.md` — objective, setup, turn structure, scoring, win conditions, edge cases
> - `design-system.md` — color palette with hex codes, typography, screen styling, animations
> - `components.md` — every config factory method documented with parameters
> - `announcements.md` — every announcement event with priorities, sound effects, stacking rules
> - `testing.md` — test counts, test files, widget keys, test patterns
> - `assets.md` — complete asset inventory with descriptions
> - `implementation-notes.md` — provider pattern, model design, algorithms, gotchas
>
> Replace ALL `{{PLACEHOLDER}}` markers with actual values. Do NOT leave any unfilled.
>
> **3. Update `CLAUDE.md`:**
> - Add new game to the Games section in the Documentation Index (with link and one-line description)
> - Update total test counts (non-UI + UI) in the "Current Test Counts" section
> - Add game-specific test run commands in "Run Game-Specific Tests"
> - Update the file structure section if a new top-level directory was created
> - Update the "Last Updated" date
>
> **4. Update `docs/testing/test-overview.md`** with new test counts and breakdown.
>
> **5. Update `docs/testing/non-ui-tests.md`** with new test details.
>
> **6. Update `docs/testing/ui-automation.md`** with new UI test counts.
>
> **7. Update `docs/DOCUMENTATION_STRUCTURE.md`** with the new game docs directory.
>
> **Report back:**
> - File paths created and modified
> - The exact line(s) added to each updated file (so the orchestrator can verify)
> - Confirmation that no `{{PLACEHOLDER}}` markers remain in the new docs (run `grep -r '{{' docs/games/[GAME-NAME]/`)
>
> **Do NOT:**
> - Modify any code files
> - Skip any of the 8 template files
> - Leave any placeholder markers unfilled

After the sub-agent returns, run `grep -r '{{' docs/games/[GAME-NAME]/` yourself to confirm zero matches, and read at least the README and one rules file for quality.

### Adversarial Review AR-8: Final Full Review (orchestrator)

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
> (h) Verify no existing game code or tests were broken — only additive changes per spec Section 16. Check `git diff master...HEAD` for modifications to files outside the new game's directories.
>
> Issues found: [list each with severity]"

Report AR-8 findings. Dispatch a corrective Sonnet sub-agent for any issues found.

### GATE 5: Definition of Done

Verify EVERY item in spec Section 14 (Definition of Done):

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
Gates passed:      5/5 (+ 2 approvals)
ARs completed:     8/8
```

Ask the user: "Would you like me to commit and create a PR?"

---

## Error Handling Rules

These rules apply throughout ALL phases:

### When Tests Fail
Per `docs/critical-rules/test-failures.md`:
1. Orchestrator STOPs and analyzes the failure (root-cause reasoning is Opus work).
2. Present to user: "(A) Fix application code, or (B) Update tests?"
3. Wait for user decision. NEVER auto-fix tests.
4. Dispatch a Sonnet sub-agent to implement the chosen approach.
5. Re-run all tests on the orchestrator.

### When a Gate Cannot Be Run
1. STOP immediately.
2. Tell the user which gate cannot be run and why.
3. Ask the user how to proceed.
4. Do NOT skip. Do NOT proceed without it. There is NO valid reason to skip a gate.

### When Dartboard Emulator Code Needs Changes
Per `docs/critical-rules/dartboard-protection.md`:
1. Do NOT modify. Ask user for permission first.
2. If the user approves, dispatch a Sonnet sub-agent for minimal changes and test thoroughly.

### When Shared Test Helpers Need Changes
Per `docs/testing/test-maintenance.md`:
1. Sub-agent must update BOTH `test/shared/` AND `integration_test/shared/`.
2. Verify synchronization by diffing corresponding files (orchestrator runs the diff).
3. Run both test suites to verify.

### When Cross-Platform Issues Arise
Per `docs/critical-rules/cross-platform.md`:
1. All features must work on web + tablets.
2. Test responsive layouts.
3. Use platform-agnostic APIs.

### Sub-Agent Failure Modes
- **Sub-agent reports success but the work is incomplete:** read the actual files yourself; if gaps exist, dispatch a corrective sub-agent with the specific gap.
- **Sub-agent goes off-script (modifies files outside its brief):** revert the unintended changes (`git checkout -- <file>`), tighten the prompt's "Do NOT" list, dispatch a fresh sub-agent.
- **Sub-agent's tests pass but the AR finds gaps:** the AR is more rigorous than the sub-agent's self-verification — trust the AR, dispatch corrective sub-agent.

### Prohibited Actions
- NEVER skip a phase or gate for any reason.
- NEVER rationalize skipping ("it requires manual setup", "tests were already written", "seems visual-only").
- NEVER mark a gate as complete without actually executing it.
- NEVER move to documentation while any gate is incomplete.
- NEVER treat "screenshot test passed" as "visual validation complete."
- NEVER evaluate only a subset of screenshots.
- NEVER auto-update tests to make them pass without user approval.
- NEVER modify dartboard emulator code without user permission.
- NEVER delegate the screenshot evaluation step (Phase 8 Step 2) to a sub-agent — visual judgment stays on the orchestrator.
- NEVER delegate adversarial reviews to a Sonnet sub-agent — they are critique work and stay on Opus.
