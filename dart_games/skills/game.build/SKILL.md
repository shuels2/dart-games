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

# PIPELINE: 11 Phases (0–10), 7 Gates (5 Hard + 2 Approval), 9 Adversarial Reviews

You MUST execute phases in order. You MUST NOT skip phases. You MUST NOT proceed past a gate until it passes. You MUST execute every adversarial review checkpoint and report the findings before continuing.

At the start of each phase, print:
```
=== Phase X of 11: [Phase Name] ===
Gates passed: X/5 (+ X/2 approvals) | ARs completed: X/9
```

---

## Model Strategy (Two-Model Architecture)

This skill runs as an **orchestrator** on the parent model (intended to be Opus) and **delegates implementation work to Sonnet sub-agents** via the Agent tool. The orchestrator handles all reasoning, judgment, critique, and gate decisions; sub-agents handle bulk coding and mechanical execution.

**Orchestrator (this thread — Opus) handles directly:**
- All phase orchestration, gate decisions, and "fix code or update tests?" questions
- Phase 0 spec analysis, section-map construction, and build plan
- All 9 adversarial reviews (AR-1 through AR-9)
- Phase 5 announcement stacking analysis (the *design* of precedence, before implementation)
- Phase 6 data migration decision
- Phase 7 spec coverage audit
- Phase 8 Step 2 screenshot evaluation against the visual checklist
- Phase 9 simultaneous-pass verification
- Test failure root-cause analysis

**Sonnet sub-agents (spawned via Agent tool) handle:**
- Phase 1 asset verification + pubspec updates + branch creation
- Phase 2 HTML/CSS wireframe authoring
- Phase 3 game model + provider + core tests
- Phase 4 screens + config factory methods + widget keys + Play-to-Complete strategy + main.dart wiring
- Phase 5 sound effects service + announcement helper code (with stacking rules from orchestrator as input)
- Phase 6 serialization + save/restore tests
- Phase 7 UI test files (in subdirectories) + screenshot test + shared helper sync + batch file updates
- Phase 8 Step 1 (chromedriver sync + server startup + screenshot test execution), Step 4 fixes, Steps 5/7 (running UI + non-UI tests)
- Phase 10 documentation files + CLAUDE.md and testing docs updates

### Placeholder Convention

This project uses **two different conventions** for game directory names — the skill must pass both as separate placeholders to every sub-agent:

- `[GAME_NAME_SNAKE]` — snake_case for **code directories and asset directories**. Examples: `clockwork_quest`, `target_tag`, `monster_mash`, `carnival_horse_race`. Used in `lib/screens/games/`, `lib/models/`, `lib/providers/`, `lib/services/`, `assets/games/`, `test/screens/games/`, `test/models/`, `test/providers/`, `integration_test/`.
- `[GAME_NAME_HYPHEN]` — kebab-case for **documentation directories**. Examples: `clockwork-quest`, `target-tag`, `monster-mash`, `carnival-derby`. Used in `docs/games/`.
- `[GAME_NAME_PASCAL]` — PascalCase for **Dart class/method names**. Examples: `ClockworkQuest`, `TargetTag`. Used in `[GameName]MenuKeys`, `AddPlayerDialogConfig.[gameName]()` (note: factory method names use camelCase — `[gameName]`).
- `[GAME_NAME_DISPLAY]` — human-readable for UI labels. Examples: "Clockwork Quest", "Target Tag".

A sub-agent told only "the game's name" will guess wrong half the time. Always cite the specific casing in every prompt.

### Spec Section Number Convention

**Spec section numbers vary by spec.** Some specs have Definition of Done at Section 14; others stop at Section 16 with no DoD; numbering is not stable across the `docs/research/games/` corpus. The skill therefore refers to spec sections by **heading text**, not fixed number, and Phase 0 builds a **section map** (heading → number) that is reused as input to every later sub-agent prompt.

When a phase below says "spec Section X (Asset Checklist)" — the parenthetical heading is the source of truth. The number is illustrative and must be replaced with the actual number from the section map for the spec at hand.

### Delegation Pattern

When delegating to a Sonnet sub-agent, invoke the Agent tool with:

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: 3–5 word task summary
- `prompt`: a **self-contained** prompt — the sub-agent has none of this conversation's context

Every delegation prompt MUST include:
1. The exact spec file path and the spec sections to read (cite the actual section numbers from the Phase 0 section map, plus the heading text)
2. The project rule files to read (cite paths under `docs/`)
3. Every file to create or modify, with full paths
4. The acceptance criteria (what "done" looks like)
5. What to report back (the orchestrator needs concrete evidence, not vague summaries)
6. Hard limits — including the universal git rule: **"Do NOT commit to master/main. Do NOT push to remote without explicit user permission. All work happens on `[BRANCH_NAME]`."**
7. Both `[GAME_NAME_SNAKE]` and `[GAME_NAME_HYPHEN]` placeholders filled in (and `[GAME_NAME_PASCAL]` / `[GAME_NAME_DISPLAY]` where relevant)

Each phase below contains a **Sub-agent prompt template** — fill in the placeholders before invoking.

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

**Goal:** Load the spec, build the section map, extract all requirements, present the build plan, get user approval.

**Model:** Orchestrator (Opus) handles all of Phase 0 directly — this is the highest-stakes analysis in the pipeline.

### Steps

1. Read the full spec file from the provided path.
2. Read `CLAUDE.md` to load all current project rules and test counts.
3. Read `docs/development/adding-games.md` for the full new-game checklist (every step, including Play to Complete, navigation tests, results tests).
4. Read `docs/development/game-integration.md` for the integration checklist.
5. Read `docs/critical-rules/visual-validation.md` for the visual validation rules.
6. Read `docs/testing/spec-coverage-audit.md` for the audit procedure.
7. **Build the spec section map.** Grep the spec for `^## \d+\.` headings and produce a table mapping the heading text → the actual section number for THIS spec. Required entries:
   - "Overview / Quick Facts" (game name, player count, Dual vs Team)
   - "Style & Visual Identity" / "Design" (color palette + fonts)
   - "Asset Checklist"
   - "Rules & Mechanics" / "Beginner Options"
   - "Game Options & Settings"
   - "Announcements & Sound Effects"
   - "Screen Designs"
   - "New Components Required"
   - "Testing Plan"
   - "Development Agent Team" (if present)
   - "Definition of Done" (if present — some specs lack this)
   - "Development Workflow" (branch strategy)
   - "Files Summary" (if present)

   If a section is absent (e.g., the spec has no "Files Summary"), record `MISSING` and proceed without it. The orchestrator must NOT reference an absent section in any later sub-agent prompt.

8. Extract from the spec, using the section map, and **retain in context for later sub-agent prompts**:
   - Game name in all four casings: `[GAME_NAME_DISPLAY]`, `[GAME_NAME_PASCAL]`, `[GAME_NAME_SNAKE]`, `[GAME_NAME_HYPHEN]`
   - Player count (min/max), player list pattern (Dual vs Team)
   - Color palette (exact hex codes), fonts (Google Fonts names)
   - Full asset checklist (image and sound paths)
   - Rules and mechanics
   - Options table — every option, default, values, and expected game-screen effect
   - Announcement events table (with priorities)
   - Screen designs — all widget keys, shared widgets, layout
   - Required new config factory methods
   - Testing plan — non-UI tests, UI tests, visual validation checklist
   - Definition of Done checklist (if present)
   - Branch strategy (default: `[GAME_NAME_HYPHEN]-dev`)
   - Files summary (if present)
9. Create one task per phase using TaskCreate. Mark Phase 0 in_progress.
10. Present the build plan to the user, including:
    - Game name (all four casings)
    - Branch name
    - Spec section map (heading → number table)
    - Number of new files to create and existing files to modify
    - Asset count
    - Planned non-UI test count and UI test count (broken down by subdirectory)
    - Config factory method list
    - Whether the spec includes a Definition of Done section and whether one will be inferred from `docs/development/adding-games.md` if absent
11. Ask the user: "Shall I proceed? Confirm the spec file, branch name, and any inferred sections are correct."

### USER APPROVAL GATE

**STOP and wait for user confirmation before proceeding.** Do not begin Phase 1 until the user explicitly approves.

---

## Phase 1: Asset Setup

**Goal:** Verify all game assets are in place (with correct naming convention), update pubspec.yaml, ensure the dev branch exists.

**Model:** Sonnet sub-agent for verification + pubspec changes; orchestrator (Opus) for AR-1.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 1 (Asset Setup) for the **[GAME_NAME_DISPLAY]** game build in the Dart Games Flutter project.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on the "Asset Checklist" section (Section [N]) and "Development Workflow" (Section [M]) per the section map below.
> - Section map (from Phase 0): [PASTE SECTION MAP TABLE]
> - `docs/development/asset-organization.md` — pay attention to the filename convention `[GameName]-[Element]-[Variant].ext` (lowercase, hyphens, prefixed with game name).
>
> **Tasks (in order):**
> 1. Run `git branch --show-current`. If not on `[BRANCH_NAME]`:
>    - If the branch exists: `git checkout [BRANCH_NAME]`
>    - Otherwise: `git checkout -b [BRANCH_NAME]`
> 2. Verify the asset folder structure exists under `assets/games/[GAME_NAME_SNAKE]/` with subdirectories required by the spec (typically `icons/`, `images/`, `characters/`, `sounds/`).
> 3. **Verify the home-screen card icon exists** at the path the spec specifies (typically `assets/games/[GAME_NAME_SNAKE]/icons/icon.png` per `docs/development/adding-games.md`). This will be referenced by the home_screen.dart card in Phase 4.
> 4. For every asset listed in the spec's Asset Checklist, build a table:
>    | Asset (spec) | Expected path | Filename convention OK? | PRESENT / MISSING |
>    Filename convention: `[GameName]-[Element]-[Variant].ext`, lowercase with hyphens, no spaces, prefixed with the game name (per `docs/development/asset-organization.md`).
> 5. If ANY asset is MISSING or has a non-conforming filename, do NOT continue. Report the issue and STOP — assets are user-provided and renaming requires user approval.
> 6. Read `pubspec.yaml`. If the game's asset directories are not listed under `flutter.assets`, add them in alphabetical order with the existing games.
> 7. Run `flutter pub get` and confirm exit code 0.
>
> **Report back:**
> - The asset table from step 4 (paths, naming, present/missing)
> - Confirmation the home-screen icon is at the expected path
> - The diff applied to `pubspec.yaml` (or "no changes needed")
> - The output of `flutter pub get`
> - The active git branch
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote. All work stays on `[BRANCH_NAME]`.
> - Modify any files outside `pubspec.yaml`
> - Create any placeholder asset files
> - Rename mis-named assets without first reporting and waiting for orchestrator instruction
> - Skip `flutter pub get`

After the sub-agent returns, run `git status` and read the modified `pubspec.yaml` yourself to confirm.

### Adversarial Review AR-1: Asset Verification

> "I will now verify the sub-agent's work against the spec's Asset Checklist section. For every asset listed in the spec, I will re-read the file system and pubspec.yaml to confirm:
> (a) The file exists at the correct path with the correct filename
> (b) The filename follows the `[GameName]-[Element]-[Variant].ext` convention
> (c) The pubspec.yaml includes the asset directory
> (d) The home-screen card icon is present at its expected path
> (e) No assets are in the wrong subdirectory (e.g., character images in sounds/)
> (f) No spec assets were overlooked
>
> I will list every discrepancy found."

Report AR-1 findings. If discrepancies exist, dispatch a corrective Sonnet sub-agent with the specific gaps before proceeding.

---

## Phase 2: Wireframe Mockups

**Goal:** Create HTML/CSS wireframe mockups of all game screens so the user can review the visual design and layout BEFORE any game code is written. This catches layout problems, UX issues, and misunderstandings of the spec early — when changes are free.

**Model:** Sonnet sub-agent for HTML/CSS authoring; orchestrator (Opus) for AR-2 + WIREFRAME APPROVAL GATE.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 2 (Wireframe Mockups) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on the spec's "Overview" (player count, Dual/Team), "Style & Visual Identity" (palette + fonts), "Game Options & Settings" (option controls + effects), "Screen Designs" (Menu/Game/Results), "New Components Required" (shared component list).
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/architecture/design-system.md` — the rule on container vs game tokens.
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Files to create:** Each screen must be shown at multiple player counts to validate scaling. For a game supporting min M / max N players, create wireframes at min, max, and at least one count in between.
>
> Required wireframes:
> - `menu_Xp.html` for each player-count variant (M, mid, N)
> - `game_early_Xp.html` for each player-count variant
> - `game_midgame_Xp.html` for each player-count variant
> - `game_modals.html` (one file — Remove Darts modal + Edit Score button + Dartboard Paused modal + Save Game modal)
> - `results_Xp.html` for each player-count variant
> - `index.html` linking to all wireframes with brief descriptions
>
> **Each Menu wireframe must show:**
> - AppBar with back button, game title, DartboardConnectionInfo placeholder, ResumeGameButton
> - **ResumeGameButton must be positioned to the LEFT of DartboardConnectionInfo** in the AppBar (per `docs/development/resume-game-button.md`)
> - Player list panel (Dual or Team per spec) populated with the appropriate number of sample player entries for that variant — **use generic placeholder avatars (initials, abstract shapes, etc.). Do NOT use the game's character images for player avatars.**
> - All settings controls from the Options section with labels and default values
> - Start Game button with enable/disable state
> - Layout proportions matching the container app pattern
>
> **Each Game-Early wireframe must show:**
> - AppBar with back button, game title, DartboardConnectionInfo placeholder
> - Game board / play area with all visual elements from the Screen Designs section
> - Player indicators showing the appropriate number of players at early game state — **generic avatars only, no character images**
> - Score / progress displays
> - Skip Turn button
> - Dartboard emulator section at BOTTOM of screen
> - Visual representation of every option's effect from the Options section
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
> - Winner display with character/avatar — **the winner card may show the game's character art for the winning player; player tiles still use generic avatars**
> - Full player rankings with stats for all players at that count
> - Play Again, Change Settings, Back to Menu buttons
> - AppBar with game title, DartboardConnectionInfo placeholder
>
> **Hard rules for every HTML file:**
> - Use the game's actual color palette from the spec's Style section (exact hex codes — no "approximate" colors)
> - Use Google Fonts links for the game's typography from the spec
> - **Do NOT use the container app's design tokens** — no Nunito font, no Flame Orange (`#FF6B35`), no other container-only colors. Container tokens are reserved for container screens only (per `docs/architecture/design-system.md`).
> - **Do NOT use game characters as player avatars** (per spec Rule 10 / `docs/development/adding-games.md`).
> - Self-contained: inline CSS, no external dependencies beyond Google Fonts
> - Responsive: use flexbox/grid, look correct at 1280x800 (primary target)
> - Realistic placeholder content (player names, scores)
> - Label shared components clearly (e.g., "DartboardEmulatorSection", "RemoveDartsModal")
> - Show every option from the Options section and where its visual effect appears on the game screen
>
> **Report back:**
> - Full list of files created (paths)
> - A coverage table mapping each option from the spec's Options section to (a) where its menu control appears and (b) where its game-screen effect is shown
> - Confirmation that no game character images are used as player avatars
> - Any spec ambiguities you had to resolve and how
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Use Nunito or Flame Orange anywhere
> - Use game characters as player avatars

After the sub-agent returns, list the files yourself and spot-check at least the menu wireframe at one player count and the game-early wireframe at one player count.

### Adversarial Review AR-2: Wireframe Completeness

> "I will now verify the wireframes against the spec before presenting them to the user:
>
> (a) Every screen from the Screen Designs section has a wireframe (Menu, Game, Results)
> (b) Every option from the Options section has a visible control on the menu wireframe AND a visible effect on the game wireframe
> (c) Every shared component from the New Components section is labeled and positioned on the correct screen
> (d) The color palette matches the spec's Style section exactly (hex codes match)
> (e) The typography matches the spec (correct Google Fonts loaded; no Nunito, no Flame Orange)
> (f) The player list panel type (Dual vs Team) matches the spec
> (g) The game wireframe shows at least two game states (early and mid/late) to demonstrate progression
> (h) Modal overlays are shown (Remove Darts, Save Game, Dartboard Paused)
> (i) Every screen type has wireframes at min player count, max player count, AND at least one count in between
> (j) **ResumeGameButton is positioned to the LEFT of DartboardConnectionInfo on the menu wireframe**
> (k) **No game character images are used as player avatars in any wireframe**
>
> Wireframe coverage:
> | Screen/State | Wireframe File | Section Match | Player Counts |
> |-------------|----------------|---------------|---------------|
> | [screen]    | [file]         | [YES/MISSING] | [e.g., 2,5,8] |
>
> Missing elements: [list any gaps]"

Report AR-2 findings. Dispatch a corrective Sonnet sub-agent for any gaps before presenting to the user.

### WIREFRAME APPROVAL GATE

Present the wireframes to the user:
- List all wireframe files created
- Tell the user to open `temp_wireframes/[GAME_NAME_SNAKE]/index.html` in their browser
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
> 3. `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_test.dart`
>    - Every test listed in the spec's Testing Plan game-logic section
>    - At least one test per Options-section option exercising its effect
>
> **Verification:**
> - Run `flutter test test/screens/games/[GAME_NAME_SNAKE]/`
> - Confirm 100% pass rate
>
> **Report back:**
> - File paths created
> - Number of tests written
> - Test results (X/Y passing)
> - A coverage table mapping each Options-section option to (a) the provider method that consumes it and (b) the test that exercises it
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Modify any files outside the three created above
> - Modify any existing game's code
> - Create the screens (those come in Phase 4)
> - Skip running the tests
> - Swallow exceptions in `updatePlayerStats` calls (the platform auto-logs failures via `/api/v1/stats/failed`)

After the sub-agent returns, read `lib/providers/[GAME_NAME_SNAKE]_provider.dart` yourself and verify Options-section coverage independently before AR-3.

### Adversarial Review AR-3: Options Coverage

> "I will now cross-reference every option from the spec's Options section against the provider code and tests. For each option I will list it by name and verify:
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

Run `flutter test test/screens/games/[GAME_NAME_SNAKE]/` directly via Bash (orchestrator) and report:
```
Gate 1: Core Logic Tests
  Result: X/Y tests passing — [PASS/FAIL]
```
If FAIL: present failures to the user per `docs/critical-rules/test-failures.md`, get the user's choice (fix code vs. update tests), dispatch a Sonnet sub-agent with the specific fix, re-run. Do NOT proceed until this gate passes.

---

## Phase 4: Screens, UI, and Play-to-Complete

**Goal:** Create all three screens with full visual theming, shared component integration, and Play-to-Complete strategy + button + runner wiring.

**Model:** Sonnet sub-agent for screens + config factories + key registration + Play-to-Complete strategy + main.dart wiring; orchestrator (Opus) for AR-4.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 4 (Screens, UI, and Play-to-Complete) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on Overview (Dual vs Team panel), Style (colors + fonts), Options (controls and effects), Screen Designs (widget keys + layout), New Components (config factory methods).
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/architecture/shared-systems.md`
> - `docs/architecture/design-system.md` — game screens MUST NOT use container tokens (no Nunito, no Flame Orange)
> - `docs/development/game-integration.md` — full integration checklist including `(route) => false` rule
> - `docs/development/widget-keys.md` — including the `HomeKeys.[gameName]Card` requirement
> - `docs/development/dartboard-emulator.md` — **including the Play-to-Complete architecture (Strategy interface, Button factory, Runner wiring) — this is mandatory.**
> - `docs/development/resume-game-button.md` — exact menu state setup (`_hasSavedGames`, `_checkForSavedGames()`, `addPostFrameCallback`)
> - `docs/development/dartboard-paused-modal.md` — the conditional: show only if `!dartboardProvider.isEmulator && status != connected && status != emulator`
> - `docs/development/save-resume-game.md` — `_deleteResumedSavedGame()` runs INDEPENDENTLY in `addPostFrameCallback`, NOT awaited inline after `_updatePlayerStats()`
> - `docs/development/announcement-system.md` — `announceRemoveDarts` MUST be called UNCONDITIONALLY on takeout (not inside a precedence `else` block)
> - At least one existing game's screens for reference (e.g., `lib/screens/games/target_tag/`, including its play-to-complete integration)
> - The wireframes from Phase 2: `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Tasks:**
>
> **1. Add widget keys to `lib/constants/test_keys.dart`:**
> - `[GAME_NAME_PASCAL]MenuKeys` — every key from the spec's Menu screen design
> - `[GAME_NAME_PASCAL]GameKeys` — every key from the spec's Game screen design
> - `[GAME_NAME_PASCAL]ResultsKeys` — every key from the spec's Results screen design
> - **Add `HomeKeys.[gameName]Card`** to the existing `HomeKeys` class for the home-screen card
>
> **2. Create config factory methods (ADD to existing files):**
> - `AddPlayerDialogConfig.[gameName]()` in `lib/widgets/add_player/add_player_dialog_config.dart`
> - `EditScoreDialogConfig.[gameName]()` in `lib/widgets/edit_score/edit_score_dialog_config.dart`
> - `DartboardSectionConfig.[gameName]()`, `DartboardFABConfig.[gameName]()`, **`PlayToCompleteButtonConfig.[gameName]()`** all in `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`
> - **Player list panel — TWO SEPARATE FILES depending on type:**
>   - For Dual: `DualPlayerListPanelConfig.[gameName]()` in `lib/widgets/player_list_panel/dual_player_list_panel_config.dart`
>   - For Team: `TeamPlayerListPanelConfig.[gameName]()` in `lib/widgets/player_list_panel/team_player_list_panel_config.dart` (NOT in dual_player_list_panel_config.dart — these are separate files)
> - `RemoveDartsModalConfig.[gameName]()` in `lib/widgets/remove_darts_modal/remove_darts_modal_config.dart`
> - `DartboardConnectionInfoConfig.[gameName]()` in `lib/widgets/dartboard_connection_info/dartboard_connection_info_config.dart`
> - `DartboardPausedModalConfig.[gameName]()` in `lib/widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart`
> - `SaveGameModalConfig.[gameName]()` in `lib/widgets/save_game_modal/save_game_modal_config.dart`
> - `ResumeGameModalConfig.[gameName]()` in `lib/widgets/resume_game_modal/resume_game_modal_config.dart`
>
> **3. Create the Play-to-Complete strategy:**
> - File: `lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart`
> - Implement `PlayToCompleteStrategy`:
>   - `getNextThrow(provider)` — returns the next dart action based on game state
>   - `isGameComplete(provider)` — returns true when win condition is met
>   - `shouldAutoTakeout(provider)` — true if takeout should happen automatically after a throw
> - Reference `lib/services/play_to_complete/target_tag_strategy.dart` (or another existing strategy) for the pattern.
>
> **4. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart`:**
> - Use the correct PlayerListPanel per spec (Dual vs Team)
> - **Generic avatars only — do NOT assign game character images to player avatars**
> - All settings from the Options section with correct controls bound to provider state
> - Add Player Dialog integration
> - DartboardConnectionInfo in AppBar (right side)
> - **ResumeGameButton in AppBar, positioned to the LEFT of DartboardConnectionInfo**
> - Menu state setup per `resume-game-button.md`: `_hasSavedGames` field, `_checkForSavedGames()` method, `WidgetsBinding.instance.addPostFrameCallback(...)` call in `initState()`
> - ResumeGameModal overlay (Stack pattern)
> - Start button enable/disable logic (min players per spec Overview)
>
> **5. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart`:**
> - Game board / play area per the Screen Designs section layout
> - DartboardEmulatorSection at BOTTOM of the screen
> - DartboardEmulatorFAB
> - **PlayToCompleteRunner integration:**
>   - Field: `PlayToCompleteRunner? _playToCompleteRunner;`
>   - Method: `_onPlayToComplete()` instantiates the runner with `[GAME_NAME_PASCAL]Strategy`
>   - Method: `_onCancelAutoPlay()` cancels the runner
>   - Auto-play guards on announcement and takeout chains (skip when runner is active)
>   - Dispose the runner in `dispose()`
> - RemoveDartsModal overlay (with Edit Score button inside — do NOT add a custom remove-darts button outside the modal)
> - DartboardPausedModal overlay — show only when `!dartboardProvider.isEmulator && status != connected && status != emulator`
> - SaveGameModal (back button + PopScope pattern)
> - Skip turn button
> - DartboardConnectionInfo in AppBar
> - **`announceRemoveDarts` is called UNCONDITIONALLY on takeout** (not inside a precedence `else`; the call is independent of which moment-announcement won precedence)
> - All option effects visible per the spec's Options section
> - **Generic avatars only — do NOT assign game character images to player avatars**
>
> **6. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart`:**
> - Winner display + rankings (winner card may show character art; player tiles use generic avatars)
> - Victory music integration via VictoryMusicService
> - Player stats update (`updatePlayerStats`) for ALL players (winners AND losers) with the SAME `gameDuration` value
> - **Auto-delete saved game**: `_deleteResumedSavedGame()` runs INDEPENDENTLY in `WidgetsBinding.instance.addPostFrameCallback(...)` — it is NOT awaited inline after `_updatePlayerStats()` (per `save-resume-game.md`)
> - Play Again, Change Settings, Back to Menu buttons
> - **Exit / Back-to-Home button: use `Navigator.popUntil(context, (route) => route.isFirst)`. NEVER use `pushNamedAndRemoveUntil('/', (route) => false)`** — the `(route) => false` predicate breaks the navigation stack (per `docs/development/game-integration.md`).
> - **Change Settings button: use `Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/[GAME_NAME_SNAKE]_menu')`** — never `(route) => false`.
> - DartboardConnectionInfo in AppBar
>
> **7. Add the game card to `lib/screens/home_screen.dart`:**
> - Use the icon from `assets/games/[GAME_NAME_SNAKE]/icons/icon.png` (or whatever the spec specifies)
> - Tag the card with `key: HomeKeys.[gameName]Card` (added in step 1)
> - Wire navigation to the route name (added in step 8)
> - Match the visual style of existing cards
>
> **8. Register the provider in `lib/main.dart` MultiProvider, and add routes for the three new screens.**
>
> **9. Run `flutter test` to verify no regressions across the full suite.**
>
> **Report back:**
> - File paths created and modified
> - The full text of each new factory method (for orchestrator review)
> - Confirmation that `announceRemoveDarts` is called unconditionally in the game screen's takeout handler (cite line number)
> - Confirmation that `_deleteResumedSavedGame()` runs independently in addPostFrameCallback on the results screen (cite line number)
> - Confirmation that the Play-to-Complete strategy + button + runner are wired (cite the file paths and runner instantiation line)
> - Confirmation that `(route) => false` is NOT used anywhere in the new screens (grep result)
> - Confirmation that game characters are NOT used as player avatars (grep for character image asset paths in the menu / game screens)
> - Test results from `flutter test` (X/Y passing)
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Modify the dartboard emulator core code (`lib/widgets/dartboard_emulator/dartboard_emulator.dart`) — only ADD config entries to the config file
> - Modify any other game's screens or providers
> - Add a custom "remove darts" button outside RemoveDartsModal
> - Use game characters as player avatars
> - Use `(route) => false` in any Navigator call
> - Use Nunito font or Flame Orange in any game-screen styling
> - Skip running `flutter test`

After the sub-agent returns:
- Run `git diff lib/main.dart` and read each new screen file yourself
- `grep -n 'announceRemoveDarts' lib/screens/games/[GAME_NAME_SNAKE]/`
- `grep -rn '(route) => false' lib/screens/games/[GAME_NAME_SNAKE]/` (must return zero matches)
- `grep -rn 'addPostFrameCallback' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart`
- before AR-4

### Adversarial Review AR-4: Integration Audit

> "I will now act as the Integration Agent. For each item below, I will verify it is actually present in the code — not just planned, but imported AND instantiated:
>
> (a) PlayerProvider used for user management
> (b) GameAnnouncementQueueService used (NOT DartAnnouncerService directly)
> (c) VictoryMusicService called on results screen
> (d) DartboardProvider used for dart input
> (e) updatePlayerStats called for ALL players (winners AND losers) with the SAME gameDuration
> (f) Every shared widget from the spec's Definition-of-Done functional-completeness list is instantiated in a screen
> (g) All 3 AppBars have: back button + title + DartboardConnectionInfo
> (h) **No custom 'remove darts' button exists outside RemoveDartsModal** — grep `lib/screens/games/[GAME_NAME_SNAKE]/` for any button labeled "Remove" outside the modal
> (i) Correct PlayerListPanel pattern (Dual vs Team) — and the Team config lives in `team_player_list_panel_config.dart`, not `dual_player_list_panel_config.dart`
> (j) SaveGameModal uses PopScope + Stack on game screen
> (k) ResumeGameModal uses Stack on menu screen
> (l) ResumeGameButton appears in menu screen AppBar, positioned to the LEFT of DartboardConnectionInfo
> (m) **`announceRemoveDarts` is called UNCONDITIONALLY in the game-screen takeout handler** (the call is not inside a precedence `else` block) — read the actual code and trace the call site
> (n) **DartboardPausedModal shown only when** `!dartboardProvider.isEmulator && status != connected && status != emulator` — read the actual conditional
> (o) **`Navigator.popUntil(context, (route) => route.isFirst)` is used for Back-to-Home** and `(route) => false` is NOT used anywhere — grep result
> (p) **`_deleteResumedSavedGame()` runs INDEPENDENTLY in `addPostFrameCallback`** on the results screen — not awaited inline after `_updatePlayerStats()`
> (q) **PlayToCompleteRunner is wired:** strategy file exists at `lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart`, `PlayToCompleteButtonConfig.[gameName]()` exists, runner field is on game screen state, runner is disposed in `dispose()`
> (r) **`HomeKeys.[gameName]Card`** exists in `lib/constants/test_keys.dart` and is used on the home_screen.dart card
> (s) **Game characters are NOT used as player avatars** — grep `lib/screens/games/[GAME_NAME_SNAKE]/` for any reference to character image asset paths in player tile / avatar widget code (must return zero matches in avatar context)
> (t) No Nunito font or Flame Orange (`#FF6B35`) used in game-screen styling
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

1. List every announcement event in the spec's Announcements section.
2. Identify the worst-case dart throw — the single dart that could trigger the most simultaneous events.
3. Define the precedence order: which event wins when multiple fire on the same dart.
4. Confirm the rule: max 2 announcements per dart (1 moment + Remove Darts), and "Remove your darts" is NEVER suppressed.
5. Document the precedence chain as numbered rules — this becomes input to the sub-agent prompt.

### Step 5B: Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 5 (Announcement and Sound System) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on the Asset Checklist (sound files with start/end times) and Announcements & Sound Effects section.
> - Section map: [PASTE SECTION MAP TABLE]
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
> - **The game screen's takeout handler must call `announceRemoveDarts` UNCONDITIONALLY** (not inside a precedence `else` block — the call is independent of the moment-announcement winner)
>
> **Files to create:**
> 1. `lib/services/[GAME_NAME_SNAKE]_sound_effects.dart` — every sound file from the Asset Checklist + Announcements section with correct start/end times
> 2. `lib/services/[GAME_NAME_SNAKE]_announcement_helper.dart` — every announcement event with correct priority levels and sound effect associations, implementing the stacking precedence rules above
> 3. `test/mocks/mock_[GAME_NAME_SNAKE]_audio_queue_service.dart`
> 4. `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_announcement_test.dart`
>    - Every test from the spec's Announcements testing section
>    - A test verifying max 2 announcements fire on the worst-case dart
>    - A test verifying "Remove your darts" always plays (cannot be suppressed)
>
> **Files to modify:**
> - `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart` — wire the announcement helper into dart processing; verify `announceRemoveDarts` is called unconditionally on takeout (this was a Phase 4 requirement; if not yet present, add it now)
>
> **Verification:**
> - Run `flutter test test/screens/games/[GAME_NAME_SNAKE]/`
> - Confirm 100% pass rate
>
> **Report back:**
> - File paths created and modified
> - The full text of the precedence selection method in the announcement helper
> - The exact line number in the game screen where `announceRemoveDarts` is called (and confirmation it is NOT inside an `else` block)
> - The test name(s) covering the worst-case stacking scenario
> - Test results (X/Y passing)
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.

After the sub-agent returns, read `lib/services/[GAME_NAME_SNAKE]_announcement_helper.dart` and the relevant section of `[GAME_NAME_SNAKE]_game_screen.dart` yourself and trace the precedence implementation against your Step 5A design.

### Adversarial Review AR-5: Announcement Stacking Analysis

> "I will now verify the implementation matches the precedence design. I will:
>
> (a) Re-state the worst-case dart scenario from Step 5A
> (b) List all events that this worst-case dart could trigger simultaneously
> (c) Trace through the announcement helper code (the actual Dart code, not memory) to verify the precedence chain correctly suppresses lower-priority events
> (d) Count how many announcements would actually fire for this worst case
> (e) Verify the count does not exceed 2 (1 moment + Remove Darts)
> (f) **Trace the game-screen takeout handler** — read the actual code and verify `announceRemoveDarts` is called UNCONDITIONALLY (not inside a precedence `else`, not gated by the moment-announcement winner). Cite the file and line.
> (g) Verify there is a test that covers this worst-case scenario, and that the test asserts both the count limit and Remove-Darts presence
>
> Worst-case scenario: [describe]
> Events triggered: [list]
> Announcements that fire: [count] — [PASS if <=2 / FAIL if >2]
> 'Remove your darts' suppressed: [YES/NO — must be NO]
> Game-screen call site: [file:line] — [UNCONDITIONAL / GATED]"

Report AR-5 findings. Dispatch a corrective Sonnet sub-agent for any issues before proceeding.

---

## Phase 6: Save/Resume and Data Migration

**Goal:** Verify save/resume is fully wired, decide on migration needs, write the remaining serialization tests.

**Model:** Orchestrator (Opus) for migration decision and verification of existing wiring; Sonnet sub-agent for serialization + save/restore test authoring; orchestrator runs Gate 2.

### Step 6A: Orchestrator verifies wiring and decides on migration

Verify on the orchestrator (read the actual files):
1. `toJson()` / `fromJson()` exist in the game model (from Phase 3)
2. `saveGame()`, `restoreGame()`, `resumedSavedGameId`, `clearResumedSavedGameId()` exist in the provider (from Phase 3)
3. `SaveGameModalConfig` and `ResumeGameModalConfig` factory methods exist (from Phase 4)
4. SaveGameModal is integrated into the game screen with PopScope + Stack (from Phase 4)
5. ResumeGameModal is integrated into the menu screen with Stack (from Phase 4)
6. **`_deleteResumedSavedGame()` runs INDEPENDENTLY in `addPostFrameCallback` on the results screen** (NOT awaited inline after `_updatePlayerStats()` — this is intentional per `docs/development/save-resume-game.md`)

Read `docs/development/data-migrations.md` and decide:
- If the new game only adds new tables/columns and optional fields with defaults → **no migration needed**.
- If any existing columns or table shapes change → **migration required**, including server-side migration tests in `server/test/`.

Document the migration decision (with reasoning) before continuing.

### Step 6B: Delegate test authoring to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 6 (Save/Resume Tests) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — Testing Plan section, serialization + save/restore tests
> - `lib/models/[GAME_NAME_SNAKE]_game.dart`
> - `lib/providers/[GAME_NAME_SNAKE]_provider.dart`
> - At least one existing game's serialization tests for reference (e.g., `test/models/target_tag_game_serialization_test.dart`)
>
> **Migration decision from orchestrator:** [PASTE DECISION + REASONING]
> [If migration required: include the migration spec the sub-agent should implement, including server-side migration tests in `server/test/`.]
>
> **Files to create:**
> 1. `test/models/[GAME_NAME_SNAKE]_serialization_test.dart` — round-trip toJson/fromJson tests covering every field including the tricky ones (enums, Sets, Maps with int keys, per-player maps)
> 2. `test/providers/[GAME_NAME_SNAKE]_save_restore_test.dart` — provider save/restore lifecycle tests
> [If migration: 3. `server/test/migrations/[migration_name]_test.dart`]
>
> **Verification:**
> - Run `flutter test test/models/[GAME_NAME_SNAKE]_serialization_test.dart test/providers/[GAME_NAME_SNAKE]_save_restore_test.dart`
> - Then run the full `flutter test` suite to verify no regressions
> - **Then run `cd server && dart test` to verify server-side regression-free**
> - Confirm 100% pass rate on all three
>
> **Report back:**
> - File paths created
> - Number of serialization round-trip tests
> - Number of save/restore tests
> - Full `flutter test` results (X/Y passing across the entire suite)
> - Full server test results (`cd server && dart test`, X/Y passing)
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.

### GATE 2: Full Non-UI Test Suite Passes (Flutter + Server)

Run BOTH suites directly via Bash on the orchestrator and report:
```
Gate 2: Full Non-UI Test Suite
  Flutter tests:  X/Y passing — [PASS/FAIL]
  Server tests:   X/Y passing — [PASS/FAIL]
  OVERALL:        [PASS/FAIL]
```
Commands:
- `flutter test`
- `cd server && dart test`

**Both must pass at 100%.** The 178 server tests are mandatory per `CLAUDE.md` and `docs/deployment/build-process.md`.

If FAIL:
- Analyze failures per `docs/critical-rules/test-failures.md` on the orchestrator (root-cause reasoning is Opus work).
- Present to user: "Tests failed. (A) Fix application code, or (B) Update tests?"
- Wait for user decision. Do NOT auto-fix tests.
- Dispatch a Sonnet sub-agent with the specific fix per user choice, re-run BOTH suites. Repeat until PASS.

---

## Phase 7: UI Automation Tests, Spec Coverage Audit, and Mandatory Coverage

**Goal:** Write all UI tests in the proper subdirectory layout (including mandatory navigation, results, and play-to-complete tests), synchronize the 11 shared helpers, update all 4 batch files, run the spec coverage audit.

**Model:** Sonnet sub-agent for shared helper sync + UI test files + screenshot test + batch file updates; orchestrator (Opus) for the spec coverage audit + AR-6 + Gate 3.

### Step 7A: Delegate UI test infrastructure to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 7 (UI Automation Tests) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — Testing Plan section (UI test list and screenshot test states)
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/testing/test-maintenance.md` — **CRITICAL: shared helper synchronization rules**
> - `docs/testing/ui-automation.md` — including the per-session DB isolation pattern (`X-DB-Session` header, `resetServerState()`) and the parallel runner port-assignment table
> - `docs/testing/continuous-animations.md` — `pumpAndSettle()` rules
> - `docs/development/adding-games.md` — **including mandatory navigation tests (4), mandatory results-screen tests (3), and mandatory play-to-complete tests**
> - `docs/development/game-integration.md` — `(route) => false` rule
> - `docs/development/dartboard-emulator.md` — Play-to-Complete strategy + tests
> - At least one existing game's UI tests for reference (use Clockwork Quest as the canonical example: `integration_test/clockwork_quest/`)
> - `test_driver/screenshot_test.dart` (the correct driver — DO NOT use `test_driver/integration_test.dart`)
>
> **Tasks:**
>
> **1. Update shared test helpers in BOTH locations (mandatory synchronization).**
>
> The `test/shared/` directory currently contains 11 files. Apply game-specific changes to each that needs them, AND mirror every change in `integration_test/shared/`:
>
> - `dart_throw_helpers.dart`
> - `edit_score_helpers.dart`
> - `element_finders.dart`
> - `game_setup_helpers.dart`
> - `game_ui_config.dart`
> - `play_to_complete_helpers.dart`
> - `provider_helpers.dart`
> - `pump_sequences.dart`
> - `results_helpers.dart`
> - `settings_helpers.dart`
> - `ui_test_helpers.dart`
>
> After editing, for every pair `test/shared/X.dart` ↔ `integration_test/shared/X.dart`, run `diff` and confirm byte-identical (apart from the path, contents must match).
>
> **2. Create UI test files using the SUBDIRECTORY layout** (NOT flat files):
>
> Create the following subdirectories under `integration_test/[GAME_NAME_SNAKE]/`:
>
> - `add_player/` — Add Player Dialog tests (one or more `*_test.dart` files per spec scenarios)
> - `edit_score/` — Edit Score Dialog tests
> - `gameplay/` — Core gameplay tests
> - `menu_and_settings/` — Menu screen + settings tests
> - `results/` (or `results_screen/` if matching reference game) — Results screen tests, INCLUDING the three mandatory tests below
> - `save_resume/` — Save/Resume tests
> - **`navigation/`** — the 4 mandatory navigation tests (see below)
> - **`play_to_complete/`** — Play-to-Complete tests (see below)
>
> **3. Mandatory navigation tests** (4 separate files in `integration_test/[GAME_NAME_SNAKE]/navigation/`, per `docs/development/game-integration.md`):
>
> - `menu_back_to_home_test.dart` — back arrow on menu returns to home with ≥3 game cards visible
> - `game_back_settings_persist_test.dart` — back from game returns to menu with previously-set settings preserved
> - `change_settings_back_to_home_test.dart` — Change Settings on results returns to menu, then back to home
> - `change_settings_preserves_settings_test.dart` — Change Settings preserves all menu settings (does NOT reset)
>
> **4. Mandatory results-screen tests** (3 specific tests in `integration_test/[GAME_NAME_SNAKE]/results/`, per `docs/development/adding-games.md`):
>
> - **Exit-button test** — assert ≥3 game cards visible after pressing Back-to-Home, AND verify the implementation uses `Navigator.popUntil(context, (route) => route.isFirst)` (NOT `pushNamedAndRemoveUntil('/', (route) => false)`)
> - **`winner_stats_updated_test.dart`** — after game completes, use `ProviderHelpers.findPlayerByName` to assert `gamesPlayed == 1` and `gamesWon == 1` for the winner, and `gamesWon == 0` for losers
> - **`victory_music_initialized_test.dart`** — after `resetServerState()` and game completion, assert `VictoryMusicService().isInitialized == true`
>
> **5. Mandatory play-to-complete tests** (in `integration_test/[GAME_NAME_SNAKE]/play_to_complete/`, per `docs/development/dartboard-emulator.md`):
>
> - `default_settings_test.dart` — runs the strategy with default settings; game completes; results screen reached
> - `mid_game_test.dart` — invokes Play-to-Complete from a mid-game state
> - One test file per game-critical setting (e.g., `tower_max_15_test.dart`, `quick_path_enabled_test.dart`) — every option whose setting changes the strategy's behavior gets its own test
>
> **6. Every UI test must call `await UITestHelpers.resetServerState()` at the start.** This is required for per-session DB isolation (Flutter Bug #67090 spawns a phantom 2nd browser; without per-session DBs the phantom contaminates results — see `docs/testing/ui-automation.md`).
>
> **7. Create `integration_test/[GAME_NAME_SNAKE]/visual_validation/[GAME_NAME_SNAKE]_screenshot_test.dart`:**
> - Capture every state listed in the spec's Testing Plan visual checklist
> - **CRITICAL:** must be runnable via `test_driver/screenshot_test.dart` as the driver
> - **CRITICAL:** do NOT use `pumpAndSettle()` — splash screen `CircularProgressIndicator` prevents settling. Use manual `pump()` sequences from `pump_sequences.dart`.
>
> **8. Update ALL FOUR batch files** with the new game:
> - `run_ui_tests.bat`
> - `run_ui_tests_stub.bat`
> - `run_ui_tests_parallel.bat` — add `[GAME_NAME_SNAKE]` to the `GAMES` variable
> - `run_ui_tests_parallel_stub.bat`
>
> Also update the port-assignment table in `docs/testing/ui-automation.md` for the new game (Server = `9000 + N`, ChromeDriver = `4443 + N`, where N is the new index).
>
> **Report back:**
> - File paths created and modified, organized by subdirectory
> - For each pair of shared helpers (11 pairs), `diff` result (must be byte-identical)
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
- Run `diff` on each of the 11 shared-helper pairs yourself
- `find integration_test/[GAME_NAME_SNAKE] -type d` to confirm subdirectory layout
- `grep -rL 'resetServerState' integration_test/[GAME_NAME_SNAKE]` (must return zero — every test file must contain a `resetServerState` call)
- Confirm the 4 batch files were updated

### Step 7B: Orchestrator runs the Spec Coverage Audit

Per `docs/testing/spec-coverage-audit.md`:

1. **Extract** every option from the spec's Options section, every visual element from Screen Designs, every test requirement from Testing Plan.
2. **Map** every non-UI test and UI test (from the actual test files) to these requirements.
3. **Build** the coverage matrix:
   | Requirement | Source (spec heading) | Non-UI test(s) | UI test(s) |
   |-------------|----------------------|----------------|------------|
4. **Identify gaps** — any row where Non-UI or UI is MISSING.
5. If gaps exist, dispatch a Sonnet sub-agent with the specific missing tests to write. Re-audit after.
6. Repeat until 100% coverage.

### Adversarial Review AR-6: Spec Coverage Matrix

> "I will now act as the Tester Agent. I will:
>
> (a) Count every test I wrote vs. every test the spec's Testing Plan requires. List any spec-required test that is missing by name.
>
> (b) For each option in the Options section, verify there is at least one non-UI test AND one UI test that exercises it. Build the matrix:
> | Option | Non-UI Test | UI Test |
> |--------|-------------|---------|
>
> (c) **Verify all FOUR batch files include the new game:** `run_ui_tests.bat`, `run_ui_tests_stub.bat`, `run_ui_tests_parallel.bat` (in the `GAMES` variable), `run_ui_tests_parallel_stub.bat`. Also verify the port-assignment table in `docs/testing/ui-automation.md` was updated.
>
> (d) Verify all 11 shared helpers in `test/shared/` and `integration_test/shared/` are synchronized — diff each pair and report any mismatches.
>
> (e) **Verify the 4 mandatory navigation tests exist** in `integration_test/[GAME_NAME_SNAKE]/navigation/`: menu_back_to_home, game_back_settings_persist, change_settings_back_to_home, change_settings_preserves_settings.
>
> (f) **Verify the 3 mandatory results-screen tests exist** in `integration_test/[GAME_NAME_SNAKE]/results/`: exit-button (popUntil + ≥3 cards assertion), winner_stats_updated, victory_music_initialized.
>
> (g) **Verify play-to-complete tests exist** in `integration_test/[GAME_NAME_SNAKE]/play_to_complete/`: default_settings, mid_game, plus one per game-critical setting.
>
> (h) **`(route) => false` is NOT used anywhere in the new game's code or tests** (grep `lib/screens/games/[GAME_NAME_SNAKE]/` and `integration_test/[GAME_NAME_SNAKE]/`).
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

## Phase 8: Visual Validation

**Goal:** Execute the FULL iterative validation cycle from `docs/critical-rules/visual-validation.md`. This phase contains the complete visual + UI + non-UI verification loop.

**Model split:**
- **Sonnet sub-agent:** Step 1 (chromedriver version sync + chromedriver lifecycle + backend server startup + screenshot test execution), Step 4 fixes, Step 5 (run UI tests), Step 7 (run flutter test + server test).
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

> You are running the screenshot capture for the **[GAME_NAME_DISPLAY]** game.
>
> **Read first:**
> - `docs/critical-rules/visual-validation.md`
> - `docs/testing/ui-automation.md` (chromedriver version sync, server startup, port assignments)
> - `run_ui_tests.bat` (for the established launch pattern — match it)
>
> **Tasks:**
> 1. **Sync chromedriver to the installed Chrome version:** run `./update_chromedriver.bat` from the repo root. Without this step, a Chrome auto-update will cause silent test failures with cryptic chromedriver errors.
> 2. Kill any running `chromedriver.exe` processes via `taskkill /F /IM chromedriver.exe` (NEVER kill `chrome.exe` — that triggers Chrome crash recovery state).
> 3. **Start the backend server in the background** (the screenshot test needs it):
>    ```
>    cd server && dart run bin/server.dart --port 9000 --data-dir ../ui_test_data
>    ```
>    Wait until it logs that it's listening on port 9000.
> 4. Start chromedriver in the background: `cd chromedriver/chromedriver-win64 && ./chromedriver.exe --port=4444`
> 5. Wait 5 seconds for chromedriver to initialize.
> 6. Run the screenshot test:
>    ```
>    flutter drive --driver=test_driver/screenshot_test.dart --target=integration_test/[GAME_NAME_SNAKE]/visual_validation/[GAME_NAME_SNAKE]_screenshot_test.dart -d chrome
>    ```
>    **CRITICAL:** Use `test_driver/screenshot_test.dart` — NEVER `test_driver/integration_test.dart` (will hang silently on `takeScreenshot()`).
>    **CRITICAL:** Do NOT use `--no-headless`.
> 7. Confirm all screenshots saved to `temp_screenshots/`.
> 8. Tear down: kill the chromedriver process; kill the backend server process. (Do NOT kill `chrome.exe`.)
>
> **Report back:**
> - The list of every screenshot file found in `temp_screenshots/` (filename + size)
> - The chromedriver version sync output
> - Any errors from the backend server, chromedriver, or `flutter drive`
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Kill `chrome.exe`
> - Use `--no-headless`
> - Use `pumpAndSettle()`
> - Skip `update_chromedriver.bat`
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
- [ ] Fonts match the spec's Style section typography
- [ ] No Nunito font or other container tokens leaking through
- [ ] Adequate text contrast and readability
- [ ] Consistent styling across similar elements

**Visual Quality:**
- [ ] Colors match the game's palette from the spec's Style section
- [ ] No Flame Orange (`#FF6B35`) or other container colors
- [ ] Visual appeal appropriate for the game's theme
- [ ] Family-friendly scale and content
- [ ] Option effects are visible where applicable

**Correctness:**
- [ ] Game characters render correctly (not used as player avatars)
- [ ] All interactive elements clearly identifiable
- [ ] All game states display correct information
- [ ] Button sizes are tappable (touch-friendly)

Also check any game-specific visual items from the spec's Testing Plan visual section.

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

> Run the UI automation tests for the **[GAME_NAME_DISPLAY]** game and report results.
>
> Run: `./run_ui_tests.bat [GAME_NAME_SNAKE]`
>
> Report back:
> - Total tests run, broken down by subdirectory (add_player, edit_score, gameplay, menu_and_settings, navigation, play_to_complete, results, save_resume)
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

### STEP 7: Run all non-UI tests (Sonnet sub-agent or orchestrator)

Run BOTH:
- `flutter test`
- `cd server && dart test`

This runs ALL non-UI tests across ALL games and the entire server. Either path is fine — Sonnet sub-agent for cleaner parallelism, or orchestrator running directly via Bash for simplicity.

---

### STEP 8: Non-UI tests fail? (orchestrator decision)

**YES (any failures in flutter test OR server test):**
- Orchestrator analyzes failures.
- Present to user per `docs/critical-rules/test-failures.md`.
- Wait for user decision. Dispatch a Sonnet sub-agent with the fix.
- **Go back to STEP 1.** Start the entire cycle over.

**NO (all pass):**
- Continue to STEP 9.

---

### STEP 9: All pass simultaneously

All four conditions are now true at the same time:
- Visual validation: zero issues
- UI automation tests: 100% pass
- Flutter non-UI tests: 100% pass
- Server tests: 100% pass

Proceed to AR-7.

---

### Adversarial Review AR-7: Validation Completeness (orchestrator)

**Before leaving Phase 8, answer every question honestly. If any answer is "no", go back and complete the missing step.**

> "(a) Did I run `update_chromedriver.bat` before the screenshot test?
> (b) Did I start the backend server before the screenshot test?
> (c) Did I actually RUN the screenshot test (not just write it)?
> (d) Did I actually READ every screenshot image with the Read tool (not just assume they were fine)?
> (e) For each screenshot, did I check EVERY item on the full checklist (not a subset)?
> (f) After EVERY fix, did I go back to Step 1 and re-capture AND re-evaluate ALL screenshots (not just the changed ones)?
> (g) Did I run the UI automation tests with `run_ui_tests.bat` (not just the non-UI tests)?
> (h) Did I run BOTH `flutter test` AND `cd server && dart test` after the UI tests passed?
> (i) Are ALL four (visual clean + UI pass + flutter test pass + server test pass) true RIGHT NOW, simultaneously?
>
> Answers: (a) [Y/N] (b) [Y/N] (c) [Y/N] (d) [Y/N] (e) [Y/N] (f) [Y/N] (g) [Y/N] (h) [Y/N] (i) [Y/N]
>
> If any answer is NO, I will go back and complete the missing step before proceeding."

---

## Phase 9: Simultaneous Pass Verification

**Goal:** Confirm all five completion conditions are true at the same time, including the spec coverage audit and server tests.

**Model:** Orchestrator (Opus) — verification only.

### Steps

1. Confirm spec coverage audit is still clean (from Phase 7). If any code changed during Phase 8, re-run the spec coverage audit on the orchestrator to verify it's still 100%.
2. Confirm visual validation completed with zero issues (from Phase 8).
3. Confirm UI automation tests passed in the most recent cycle (from Phase 8).
4. Confirm flutter non-UI tests passed in the most recent cycle (from Phase 8).
5. Confirm server tests passed in the most recent cycle (from Phase 8).

### GATE 4: Simultaneous Pass (NON-NEGOTIABLE)

```
Gate 4: Simultaneous Pass Verification
  Spec coverage audit:  [PASS/FAIL] — X%
  Visual validation:    [PASS/FAIL] — X screenshots, zero issues
  UI automation tests:  [PASS/FAIL] — X/Y passing
  Flutter non-UI tests: [PASS/FAIL] — X/Y passing
  Server tests:         [PASS/FAIL] — X/Y passing
  OVERALL:              [PASS/FAIL]
```

If ANY component fails:
- Fix the failing component (dispatch Sonnet sub-agent for code fixes).
- Re-run ALL FIVE checks (not just the fixed one — a fix can break others).
- Repeat until all five pass simultaneously.

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

> You are completing Phase 10 (Documentation) for the **[GAME_NAME_DISPLAY]** game build.
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
> Record: total flutter non-UI count, total server count, this game's UI count broken down by subdirectory (add_player, edit_score, gameplay, menu_and_settings, navigation, play_to_complete, results, save_resume, visual_validation). These are the real numbers — do NOT estimate.
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
> - `components.md` — every config factory method documented with parameters; **fill the "Custom Components" section if the game introduces game-specific widgets** (e.g., a custom button or panel)
> - `announcements.md` — every announcement event with priorities, sound effects, stacking rules
> - `testing.md` — REAL test counts from step 1 (broken down by subdirectory), test files, widget keys, test patterns; include navigation tests, results tests, play-to-complete tests
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
> (d) Verify `updatePlayerStats` is called for ALL players (winners AND losers) with the SAME `gameDuration` value.
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
> (o) Verify CLAUDE.md test counts were updated using REAL numbers (Phase 10 step 1) — not estimates. The flutter test count, server test count, and UI test count for this game must match the latest test run output.
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

**Testing:**
- [ ] Flutter non-UI tests pass (count: real)
- [ ] Server tests pass (count: real)
- [ ] UI test files in subdirectory layout (add_player/, edit_score/, gameplay/, menu_and_settings/, navigation/, play_to_complete/, results/, save_resume/, visual_validation/)
- [ ] **4 mandatory navigation tests present and passing**
- [ ] **3 mandatory results-screen tests present and passing**
- [ ] **Play-to-complete tests present and passing**
- [ ] All 4 batch files updated (run_ui_tests, run_ui_tests_stub, run_ui_tests_parallel, run_ui_tests_parallel_stub)
- [ ] All 11 shared helpers synchronized (test/shared/ matches integration_test/shared/)
- [ ] Every UI test calls `resetServerState()`

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
- [ ] Test organization and helper usage match references
- [ ] Visual consistency with reference games verified
- [ ] Documentation depth and structure parity with references
- [ ] Zero High/Medium divergences (Low/justified divergences allowed)

Present the full Definition of Done checklist to the user with PASS/FAIL for each item.

---

## Final Summary

After Gate 5 passes, print:

```
=== Game Build Complete ===
Game:                  [Game Name]
Branch:                [branch-name]
Files created:         X new files
Files modified:        Y existing files
Flutter non-UI tests:  X (all passing)
Server tests:          X (all passing)
UI tests:              Y (all passing, broken down by subdirectory)
Screenshots:           Z (all evaluated, zero issues)
Spec coverage:         100%
Definition of Done:    X/X verified
Gates passed:          5/5 (+ 2 approvals)
ARs completed:         9/9
```

Ask the user: "Would you like me to commit and create a PR?"

(Per `docs/deployment/git-workflow.md` and the universal hard rule in every sub-agent prompt: NEVER commit to master/main and NEVER push to remote without explicit user permission.)

---

## Error Handling Rules

These rules apply throughout ALL phases:

### When Tests Fail
Per `docs/critical-rules/test-failures.md`:
1. Orchestrator STOPs and analyzes the failure (root-cause reasoning is Opus work).
2. Present to user: "(A) Fix application code, or (B) Update tests?"
3. Wait for user decision. NEVER auto-fix tests.
4. Dispatch a Sonnet sub-agent to implement the chosen approach.
5. Re-run all tests on the orchestrator (BOTH `flutter test` AND `cd server && dart test`).

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
1. Sub-agent must update BOTH `test/shared/` AND `integration_test/shared/` (all 11 files in each).
2. Verify synchronization by diffing every corresponding pair (orchestrator runs the diff).
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
- **Sub-agent guesses wrong on hyphen vs underscore:** the prompt did not pass both `[GAME_NAME_SNAKE]` and `[GAME_NAME_HYPHEN]` clearly — fix the prompt and re-dispatch.

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
- NEVER skip `cd server && dart test` — the 178 server tests are mandatory at every gate that runs non-UI tests.
- NEVER skip the 4 mandatory navigation tests, the 3 mandatory results-screen tests, or the play-to-complete tests.
- NEVER use `(route) => false` in any Navigator call — use `(route) => route.isFirst` or `route.isFirst || route.settings.name == '/...'`.
- NEVER use Nunito font or Flame Orange (`#FF6B35`) in game-screen styling — those are container-app tokens.
- NEVER use game characters as player avatars.
- NEVER commit to master/main. NEVER push to remote without explicit user permission.
