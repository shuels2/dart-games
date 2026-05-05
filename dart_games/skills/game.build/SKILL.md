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

### Universal Rule: Limit Changes to the New Game

**This rule MUST be embedded in every sub-agent prompt's hard-rules section.**

> **"Existing-games-work" baseline:** All existing games (Carnival Derby, Target Tag, Monster Mash, Reef Royale, Clockwork Quest) work with the shared infrastructure today. If you encounter a bug during this build, it is **almost certainly in the new game's code**, NOT in shared widgets, providers, services, or other games. Limit ALL changes to the additive new-game zones below; if you believe a shared file has a bug, **STOP and surface it to the orchestrator** — do not fix it.
>
> **Allowed change zones (additive only):**
> - `lib/{models,providers,services}/[GAME_NAME_SNAKE]*` and `lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart`
> - `lib/screens/games/[GAME_NAME_SNAKE]/`
> - `assets/games/[GAME_NAME_SNAKE]/`
> - `test/screens/games/[GAME_NAME_SNAKE]/`, `test/models/[GAME_NAME_SNAKE]*`, `test/providers/[GAME_NAME_SNAKE]*`, `test/mocks/mock_[GAME_NAME_SNAKE]*`
> - `integration_test/[GAME_NAME_SNAKE]/`
> - `docs/games/[GAME_NAME_HYPHEN]/`
> - `lib/constants/test_keys.dart` — additive: new key class only + `HomeKeys.[gameName]Card`
> - `lib/main.dart` — additive: provider + 3 routes
> - `lib/screens/home_screen.dart` — additive: new game card
> - `lib/widgets/*/[*]_config.dart` — additive: new `.[gameName]()` factory only
> - 12 mirrored shared helpers — additive only (new game-specific helpers)
> - 4 batch files — additive: game name appended to GAMES list
> - `pubspec.yaml` — additive: asset directory entries
>
> **Forbidden zones (do NOT modify):**
> - Any other game's code, tests, docs, or assets
> - The dartboard emulator core widgets
> - Shared widget bodies (only their config files for `.[gameName]()` factories)
> - Existing tests outside the new-game-specific list
> - `.claude/settings.json` or `.claude/settings.local.json`
> - `.git/hooks/*`
>
> **Auto-revert rule:** at the end of each phase, the orchestrator runs `git diff master...HEAD --name-only` and verifies all changed files are within the allowed zones. Any unexpected modification triggers `git checkout -- <file>` and a corrective sub-agent dispatch with a tightened prompt.

### YOLO Mode Pre-Flight

If the user is running this skill in YOLO mode (no permission prompts) — risks include sub-agents pushing to remote, committing to master, or modifying shared code without challenge. The skill mitigates these via:

1. **Hard-rules section in every sub-agent prompt** — already in place; the universal rule above plus per-phase forbids.
2. **Pre-commit hook on master/main** — `.git/hooks/pre-commit` should reject any commit attempted on `master` or `main`. The orchestrator verifies this exists at the start of Phase 0; if missing, the orchestrator BLOCKS the run and surfaces setup instructions to the user.
3. **Per-phase auto-revert** — see "Auto-revert rule" above.
4. **Phase 8 final user acceptance gate** — see Phase 8 STEP 10. Even in YOLO mode, the user explicitly accepts the visual state before docs.
5. **Branch isolation** — all work happens on `[BRANCH_NAME]` (default `[GAME_NAME_HYPHEN]-game`). No commits to master/main, no pushes to remote without user permission.

**Phase 0 Step 0 (pre-flight check, run BEFORE Step 1 of Phase 0):**

Verify the environment is YOLO-safe:

1. Confirm `.git/hooks/pre-commit` exists AND contains a `master|main` block. Test:
   ```bash
   if [ ! -f .git/hooks/pre-commit ] || ! grep -q 'master\|main' .git/hooks/pre-commit; then
     echo "FAIL: pre-commit hook missing master/main protection"
     exit 1
   fi
   ```
   If FAIL: tell the user the hook is missing and offer to create it. STOP until they confirm.

2. Confirm the user is NOT currently on master/main:
   ```bash
   current_branch=$(git branch --show-current)
   if [ "$current_branch" = "master" ] || [ "$current_branch" = "main" ]; then
     echo "FAIL: currently on $current_branch — switch to a dev branch first"
     exit 1
   fi
   ```

3. Confirm the working tree is clean OR the only uncommitted changes are within the allowed zones above.

If any check fails, STOP and surface to the user. Do not proceed.

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
> 8. **Write the asset path manifest** at `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md`. This is consumed by Phase 2 (wireframes) and Phase 3 (model `assetPath` getter). Format:
>    ```
>    # Lunar Lander asset paths (canonical post-rename — use these EXACTLY)
>
>    ## Icon / Background
>    - icon: `assets/games/[GAME_NAME_SNAKE]/icons/[GameName]-Icon.png`
>    - background: `assets/games/[GAME_NAME_SNAKE]/images/[GameName]-Background.png`
>
>    ## Characters (enum_value → path)
>    - spaceDog → `assets/games/[GAME_NAME_SNAKE]/characters/SpaceDog.png`
>    - moonCat  → `assets/games/[GAME_NAME_SNAKE]/characters/MoonCat.png`
>    - ...
>
>    ## Sounds (constant → path → start/end times)
>    - thrusterBurn → `assets/games/[GAME_NAME_SNAKE]/sounds/[GameName]-ThrusterBurn.mp3` → 0.5s–3.0s
>    - ...
>    ```
>    Phase 3 sub-agent reads this file to populate the model's `assetPath` getter using the renamed paths, NOT the spec's original (potentially pre-rename) names.
>
> **Report back:**
> - The asset table from step 4 (paths, naming, present/missing)
> - Confirmation the home-screen icon is at the expected path
> - The diff applied to `pubspec.yaml` (or "no changes needed")
> - The output of `flutter pub get`
> - Confirmation that `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` was written
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
> (g) The asset path manifest at `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` was written and lists every asset with its CANONICAL POST-RENAME path. Read the manifest and verify every listed path resolves to a real file (`if [ -f "$path" ]`). This manifest is the source of truth for Phases 2 (wireframes) and 3 (model `assetPath`) — a path mismatch here cascades into the model and screens, causing silent runtime image-load failures.
>
> I will list every discrepancy found."

Report AR-1 findings. If discrepancies exist, dispatch a corrective Sonnet sub-agent with the specific gaps before proceeding.

---

## Phase 2: Wireframe Mockups (Staged Approval)

**Goal:** Create HTML/CSS wireframe mockups of all game screens so the user can review the visual design and layout BEFORE any game code is written. This catches layout problems, UX issues, and misunderstandings of the spec early — when changes are free.

**Model:** Sonnet sub-agent for HTML/CSS authoring; orchestrator (Opus) for AR-2 + WIREFRAME APPROVAL GATEs.

### Staged Approval Strategy

Past sessions showed that building all wireframes upfront led to multiple revision rounds when the user only realized the visual direction was off after seeing them all. **This phase is now split into 4 stages with cheap approval gates between them.** The goal is to lock in the look-and-feel before investing in the full wireframe set.

- **Stage A:** Menu screen at ONE player count (e.g., 4 players selected) → user approval gate
- **Stage B:** Game screen (early state) at 2 players → user approval gate
- **Stage C:** Results screen at 2 players → user approval gate
- **Stage D:** Full wireframe set across min/mid/max player counts + modals → final user approval gate

After each stage, the user can request changes cheaply. Visual direction confirmed early → Stage D is mostly mechanical replication across player counts.

**CRITICAL — Use REAL game assets in every wireframe:**

The wireframes are NOT generic placeholders. Reference the actual character images, background images, and icon via `<img src="../../assets/games/[GAME_NAME_SNAKE]/...">` paths. Apply the spec's exact color palette + Google Fonts to ALL elements: list boxes, settings panels, modal overlays, AppBars, buttons, everything. The wireframe must be visually close to the final game so the user can give meaningful feedback.

- Use the actual icon for the home-screen card mock-up
- Use the actual background image as the page background on game and results screens
- Use the actual character images on player tiles, descent tracks, winner card, etc.
- Use the spec's exact hex codes (no "approximate" colors)
- Load the spec's Google Fonts via `<link>` tags
- Match the spec's Style section closely — the wireframe should be nearly indistinguishable from the final game in colors/fonts/imagery

The ONLY stylistic restriction: do NOT use the container app's tokens (Nunito font, Flame Orange `#FF6B35`, etc.).

### Stage A: Menu screen wireframe + approval

**Sub-agent prompt template (Stage A only):**

> You are completing Phase 2 Stage A (Menu wireframe) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on "Overview" (player count, Dual/Team), "Style & Visual Identity" (palette + fonts), "Game Options & Settings" (option controls + effects), "Screen Designs" Menu Section, "New Components Required".
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/architecture/design-system.md` — container vs game tokens rule.
> - Asset paths from Phase 1's manifest at `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` — reference these EXACTLY.
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Stage A scope (single file):**
> - `menu_4p.html` — menu with 4 players selected, default option values, fully styled
>
> **The wireframe MUST use real game assets** referenced via `<img src="../../assets/games/[GAME_NAME_SNAKE]/...">`:
> - Real icon, real character images (on the player tile section if the spec calls for it — otherwise generic), real background if the spec specifies one for the menu
> - Spec's exact color palette (every box, every border, every text color)
> - Spec's Google Fonts loaded via `<link>` tags and applied to AppBar, headers, body, buttons
> - Real game-themed labels and messaging from the spec — NOT generic Lorem-ipsum
>
> **Layout requirements (apply consistently — these are the patterns the user has called out as bugs in past sessions):**
> - Option boxes have IDENTICAL heights regardless of control type (slider/toggle/dropdown). Use a fixed `min-height` so a slider box and a toggle box render the same height.
> - Spacing between option columns matches spacing between option columns and player list panel below them. Use the same `gap` / `margin` value throughout the right panel.
> - AppBar shows: back button, title (spec's exact text), DartboardConnectionInfo placeholder on the right, **ResumeGameButton positioned to the LEFT of DartboardConnectionInfo** (per `docs/development/resume-game-button.md`)
> - Player list panel populated with 4 player entries. **Use generic placeholder avatars on player tiles (initials/abstract shapes — NOT character images) — per project rule.** The character images go on game-screen + winner-card only.
>
> **Report back:**
> - File path created
> - Asset paths referenced (verify each is a real file via `if -e $path`)
> - Coverage table: each option from spec → its menu control + visible effect
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Use Nunito or Flame Orange `#FF6B35`.
> - Use generic placeholder colors / fonts / labels — match the spec exactly.
> - Use game characters as player tile avatars (use initials/shapes).
> - Skip the asset paths from `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` (Phase 1 manifest).

After the sub-agent returns, run AR-2 (Stage A subset) on the orchestrator.

### Stage A approval gate

Present the menu wireframe to the user:
- "Open `temp_wireframes/[GAME_NAME_SNAKE]/menu_4p.html` in your browser"
- "Confirm: colors, fonts, layout, character/imagery use, option box heights, spacing"

**STOP and wait for user approval.** Iterate per user feedback (each round = one corrective sub-agent dispatch). Do NOT proceed to Stage B until the user explicitly approves the menu look-and-feel.

### Stage B: Game screen wireframe + approval

**Sub-agent prompt template (Stage B only):**

> You are completing Phase 2 Stage B (Game screen wireframe) for the **[GAME_NAME_DISPLAY]** game build. The orchestrator has already locked in the menu visual direction in Stage A — REUSE the same color palette, fonts, panel styling, AppBar pattern from `menu_4p.html`.
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Stage B scope (single file):**
> - `game_early_2p.html` — game screen at the START of a game (2 players, all at starting state)
>
> **Layout requirements:**
> - AppBar: back button, title, DartboardConnectionInfo on the right (NO ResumeGameButton on game screen)
> - Active player panel (LEFT, 200px wide per spec Section 10B if specified): use the player's CHARACTER IMAGE rendered NATIVELY (no circle clipping, `object-fit: contain`). Apply a shape-conformal `filter: drop-shadow` for active-player glow.
> - Player progress visualization (descent track / coral cards / shields / etc. per spec): use REAL CHARACTER IMAGES, not rocket/circle placeholders. Render them at native size with no circle masking.
> - Background: use the real background image from `assets/games/[GAME_NAME_SNAKE]/images/...` if the spec specifies one. The background must be visible on the game screen (recurring miss in past sessions).
> - **The dartboard emulator section is a TEMPORARY OVERLAY at the bottom — NOT space-reserving infrastructure.** The primary game UI should fill the FULL available height as if the dartboard didn't exist. The emulator overlaps the bottom portion at run time. Reference: in the actual implementation, DartboardEmulatorSection is a `Positioned(bottom: 0)` child of the **outer Stack** (sibling of Scaffold, NOT inside the body Stack), on top of the game UI. Mirror this in the wireframe by drawing the game content full-height and placing the dartboard label as an overlay at the bottom edge.
> - Skip Turn button visible (per spec's screen design)
> - Show every option's visible effect from the Options section (e.g., "HARD LANDING" badge if HL ON, altitude readout, etc.)
>
> **Hard rules — same as Stage A.**

Present `game_early_2p.html` to the user. **Wait for approval.**

### Stage C: Results screen wireframe + approval

**Sub-agent prompt template (Stage C only):**

> You are completing Phase 2 Stage C (Results screen wireframe) for the **[GAME_NAME_DISPLAY]** game build. REUSE the locked-in visual direction from Stage A + Stage B.
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Stage C scope (single file):**
> - `results_2p.html` — results screen with 2 players, the winner highlighted
>
> **Layout requirements:**
> - AppBar: title (e.g., "[GAME] RESULTS") + DartboardConnectionInfo on right. **NO back button** — results-screen navigation is exclusively via the 3 action buttons (Play Again, Change Settings, Back to Menu). Use `automaticallyImplyLeading: false` on the AppBar.
> - Background: use the real background image (recurring miss — must be visible on results screen)
> - Winner card: real character image at native size (no circle clipping), winner stats, victory styling
> - Player rankings list: generic avatars (initials), NOT character images per the project rule (winner card is the only exception)
> - 3 buttons: Play Again, Change Settings, Back to Menu — colored per spec
>
> **Hard rules — same as Stage A.**

Present `results_2p.html` to the user. **Wait for approval.**

### Stage D: Full wireframe set + final approval

**Sub-agent prompt template (Stage D only):**

> You are completing Phase 2 Stage D (full wireframe set) for the **[GAME_NAME_DISPLAY]** game build. The orchestrator has locked in the menu, game, and results visual direction in Stages A-C. Now produce the full set across player-count variants and add the modals wireframe + index.
>
> **Read first:**
> - The 3 approved wireframes: `menu_4p.html`, `game_early_2p.html`, `results_2p.html` — REUSE their CSS, colors, fonts, structures verbatim
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Files to create:** Each screen must be shown at multiple player counts to validate scaling. For a game supporting min M / max N players, create wireframes at min, max, and at least one count in between.
>
> Required wireframes:
> - `menu_Xp.html` for each player-count variant (M, mid, N — N being max)
> - `game_early_Xp.html` for each player-count variant
> - `game_midgame_Xp.html` for each player-count variant
> - `game_modals.html` (one file — Remove Darts modal + Edit Score button + Dartboard Paused modal + Save Game modal)
> - `results_Xp.html` for each player-count variant
> - `index.html` linking to all wireframes with brief descriptions
>
> **Each variant inherits the locked-in styling from Stages A-C and varies ONLY player count.**
>
> **Game-modals wireframe (single file with 3 stacked panels):**
> - Game screen with Remove Darts modal overlay (including Edit Score button inside the modal)
> - Dartboard Paused modal state
> - Save Game modal (back-button triggered)
>
> **Hard rules — same as Stage A. Do NOT introduce new colors/fonts; reuse the locked-in CSS.**
>
> **Report back:**
> - Full list of files created (paths)
> - A coverage table mapping each option from the spec's Options section to (a) where its menu control appears and (b) where its game-screen effect is shown
> - Confirmation that no game character images are used as player tile avatars
> - Any spec ambiguities you had to resolve and how

After the sub-agent returns, list the files yourself and spot-check the new player-count variants.

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
> (k) **No game character images are used as player TILE avatars** (winner card and active-player panel exceptions allowed per spec)
> (l) **Real character images ARE used** on the game screen (descent track / coral cards / shields / etc.) and on the winner card — rendered NATIVELY without circle clipping (no `border-radius: 50%` + `overflow: hidden` masking the character art)
> (m) **Background image is visible** on the game screen and results screen IF the spec specifies one (recurring miss in past sessions — flag it)
> (n) **Option boxes have IDENTICAL heights** regardless of control type (slider, toggle, dropdown all render to the same `min-height`)
> (o) **Spacing is consistent** — gap between option columns equals gap between option columns and the player list panel below
> (p) **Dartboard emulator is positioned as a BOTTOM OVERLAY** that overlaps the bottom of the game UI — NOT as a space-reserving section that the game UI flows around. The game content fills full available height as if the dartboard didn't exist.
>
> Wireframe coverage:
> | Screen/State | Wireframe File | Section Match | Player Counts |
> |-------------|----------------|---------------|---------------|
> | [screen]    | [file]         | [YES/MISSING] | [e.g., 2,5,8] |
>
> Missing elements: [list any gaps]"

Report AR-2 findings. Dispatch a corrective Sonnet sub-agent for any gaps before presenting to the user.

### Stage D: Final wireframe approval gate

Present the full wireframe set to the user:
- List all wireframe files created
- Tell the user to open `temp_wireframes/[GAME_NAME_SNAKE]/index.html` in their browser
- Ask the user to review the full set across player counts and the modals wireframe

**STOP and wait for user approval.**

The user may:
- **Approve** — proceed to Phase 3
- **Request changes** — dispatch a corrective Sonnet sub-agent with specific feedback, present again, wait for approval
- **Request major redesign** — return to the appropriate Stage (A/B/C) for re-approval first

Do NOT proceed to Phase 3 until the user explicitly approves the full wireframe set. This is the cheapest place to catch design issues — before any code is written.

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
> (c) **Turn increment rule:** `grep -n 'totalTurns' lib/models/[GAME_NAME_SNAKE]_game.dart lib/providers/[GAME_NAME_SNAKE]_provider.dart` — the increment (`totalTurns[...] = ... + 1`) MUST appear in EXACTLY ONE place: the provider's `processDartThrow` guarded by `if (game.dartsThrown[playerId] == 1)`. Any increment in `advanceToNextPlayer` or anywhere else is a double-count bug.
> (d) **Asset paths in model match Phase 1 manifest:** for every enum value in the model with an `assetPath` getter, the returned path MUST exist on disk. Run `flutter test test/screens/games/[GAME_NAME_SNAKE]/` — if any character image fails to load, the unit tests still pass (they don't load images). The check is: read the model file and grep each `return 'assets/...'` path, then confirm the file exists.
>
> Coverage matrix:
> | Option | Provider Logic | Test Coverage |
> |--------|---------------|---------------|
> | [name] | [method]      | [test name]   |
>
> I will report any option that lacks either provider logic or test coverage, plus any turn-increment double-count or any model assetPath that doesn't exist on disk."

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
> - `lib/widgets/dartboard_emulator/play_to_complete_strategy.dart` — the actual interface (3 methods, all take `BuildContext context`)
> - `lib/widgets/dartboard_emulator/play_to_complete_runner.dart` — the runner: constructor takes strategy + mockApi + context + optional `onComplete`; exposes `run()`, `cancel()`, `dispose()`
> - `lib/services/play_to_complete/target_tag_strategy.dart` — canonical reference strategy implementation
> - `lib/screens/games/target_tag/target_tag_game_screen.dart` — canonical Play-to-Complete wiring (field name `_playToCompleteRunner`, `_onPlayToComplete()`, `_onCancelAutoPlay()`, dispose)
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
> - Implement `PlayToCompleteStrategy` (from `lib/widgets/dartboard_emulator/play_to_complete_strategy.dart`). The interface has THREE methods — **all take `BuildContext context`, NOT a provider**. The strategy itself calls `context.read<[GAME_NAME_PASCAL]Provider>()` to access state.
>   - `SimulatedThrow? getNextThrow(BuildContext context)` — returns the next dart action as a `SimulatedThrow` (fields `score`, `multiplier`, `baseScore`), or `null` when the game is done.
>   - `bool isGameComplete(BuildContext context)` — returns `true` when the win condition is met.
>   - `bool shouldAutoTakeout(BuildContext context)` — returns `true` if takeout should fire automatically after this throw.
> - Reference `lib/services/play_to_complete/target_tag_strategy.dart` (canonical) for the pattern. Also study the other 4 game strategies (`carnival_derby_strategy.dart`, `clockwork_quest_strategy.dart`, `monster_mash_strategy.dart`, `reef_royale_strategy.dart`) to confirm the convention.
>
> **4. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart`:**
> - Use the correct PlayerListPanel per spec (Dual vs Team)
> - **DualPlayerListPanel layout — MUST have bounded height** (recurring crash in past sessions): the panel's internal Column has `Expanded` children that crash with unbounded height constraints. Wrap pattern:
>   - In wide layout (constraints.maxWidth > 800): `Expanded(child: DualPlayerListPanel(...))` so the panel takes remaining vertical space in the right-panel Column.
>   - In narrow scrollable layout (constraints.maxWidth <= 800): `SizedBox(height: 400, child: DualPlayerListPanel(...))` because `Expanded` cannot live inside a `SingleChildScrollView`.
>   - Reference: `monster_mash_menu_screen.dart` line 715 — `Expanded(child: DualPlayerListPanel(...))`.
> - **Generic avatars only on player TILE — do NOT assign game character images to player tile avatars**
> - All settings from the Options section with correct controls bound to provider state. **Option boxes MUST have IDENTICAL heights** regardless of control type (slider/toggle/dropdown). Use a fixed `min-height` so visual rhythm stays consistent across the settings row.
> - Add Player Dialog integration
> - DartboardConnectionInfo in AppBar (right side)
> - **ResumeGameButton in AppBar, positioned to the LEFT of DartboardConnectionInfo**
> - **AppBar back arrow — canonical pattern (mandatory, identical on the menu AND game screens):**
>   ```dart
>   leading: IconButton(
>     key: [GAME_NAME_PASCAL]MenuKeys.backButton, // or GameKeys.backButton on game screen
>     icon: const Icon(Icons.arrow_back, color: [SPEC_TEXT_COLOR], size: 32),
>     onPressed: () => Navigator.of(context).pop(), // or game-screen save-modal logic
>     hoverColor: Colors.transparent,
>     highlightColor: Colors.transparent,
>     splashColor: Colors.transparent,
>   ),
>   ```
>   - **Icon size MUST be 32** — matches Clockwork Quest, Reef Royale, Monster Mash, Carnival Derby, Target Tag (all 5 reference games)
>   - **All three hover-suppression properties (`hoverColor`, `highlightColor`, `splashColor`) MUST be `Colors.transparent`** — eliminates the default IconButton hover/splash effect for tablet/touch UX
>   - **Each screen's back arrow MUST use its own keys class** (`MenuKeys.backButton`, `GameKeys.backButton`) — never reuse another game's key class. Define `backButton` on each Keys class even if not currently referenced by tests.
>   - **Menu and game screens MUST be identical in size, color, and hover-suppression** — a consistent, predictable back-arrow experience.
>   - **Results screen MUST NOT have a back arrow** — set `automaticallyImplyLeading: false` on the AppBar and do NOT supply a `leading:` widget. Navigation off the results screen is exclusively via the 3 action buttons (Play Again, Change Settings, Back to Menu). Reference: Clockwork Quest, Reef Royale, Monster Mash, Target Tag, Carnival Derby — all 5 reference games omit the back arrow on results.
> - **initState pattern (mandatory — Clockwork Quest reference):**
>   ```dart
>   @override
>   void initState() {
>     super.initState();
>
>     // 1. Restore settings from the most recent game (when reentering via
>     //    Results → CHANGE MISSION). The provider retains `currentGame` after
>     //    the game ends; CHANGE MISSION pushes a fresh menu without clearing
>     //    it. Reading those values here makes the menu remember the user's
>     //    last settings instead of resetting to defaults.
>     final lastGame = context.read<[GAME_NAME_PASCAL]Provider>().currentGame;
>     if (lastGame != null) {
>       // Read each spec-defined setting from lastGame and assign to local state
>       _settingA = lastGame.settingA;
>       _settingB = lastGame.settingB;
>       // ...
>     }
>
>     // 2. Initial saved-games check — if any saves exist on first menu entry,
>     //    AUTO-OPEN the resume modal. Subsequent re-checks (after games
>     //    complete or user actions) only update _hasSavedGames; they do NOT
>     //    auto-open the modal.
>     WidgetsBinding.instance.addPostFrameCallback((_) async {
>       final hasSaved = await SaveGameService().hasSavedGames('[GAME_NAME_SNAKE]');
>       if (mounted) {
>         setState(() {
>           _hasSavedGames = hasSaved;
>           _showResumeModal = hasSaved;  // ← auto-open on initial load
>         });
>       }
>     });
>   }
>   ```
>   Reference: `clockwork_quest_menu_screen.dart` lines 63-77 + 79-84.
> - **MENU SCREEN STRUCTURE — outer-Stack modal pattern (MANDATORY, apply EXACTLY — same shape as game screen):**
>   The menu screen wraps `Scaffold` in an outer `Stack` so menu modals paint OVER the AppBar (back arrow, ResumeGameButton, DartboardConnectionInfo). The build method's return value is `Stack`, NOT `Scaffold`.
>   ```dart
>   @override
>   Widget build(BuildContext context) {
>     final dartboardProvider = context.watch<DartboardProvider>();
>     // ...other watch calls and computations...
>     return Stack(
>       children: [
>         // 1. Scaffold — AppBar (back + ResumeGameButton if saved games + DartboardConnectionInfo)
>         //    + body (background, options, player list panel).
>         Scaffold(
>           appBar: AppBar(...),
>           body: Stack(children: [bg, content]),
>         ),
>         // 2. ResumeGameModal (conditional) — auto-shown on initial entry if saved
>         //    games exist; or on tap of ResumeGameButton in AppBar.
>         if (_showResumeModal) ResumeGameModal(...),
>         // 3. DartboardPausedModal (conditional) — LAST child; paints on top.
>         //    Same conditional as the game screen's paused modal.
>         if (!dartboardProvider.isEmulator &&
>             dartboardProvider.status != DartboardConnectionStatus.connected &&
>             dartboardProvider.status != DartboardConnectionStatus.emulator)
>           DartboardPausedModal(config: DartboardPausedModalConfig.[gameName]()),
>       ],
>     );
>   }
>   // 4. AddPlayerDialog — NOT an outer-Stack child. It is a routed dialog
>   //    (`showAddPlayerDialog()`) launched from INSIDE `DualPlayerListPanel` (the
>   //    shared player list panel widget — see `lib/widgets/player_list_panel/`).
>   //    The menu screen passes `addPlayerButtonKey` + `addPlayerButtonEmptyStateKey`
>   //    to the panel; the panel handles the dialog internally. The menu screen
>   //    file does NOT call `showAddPlayerDialog` directly. As a routed dialog it
>   //    paints above all outer-Stack siblings (including DartboardPausedModal)
>   //    when shown.
>   ```
>   Reference: any menu screen for the canonical pattern (e.g. `lunar_lander_menu_screen.dart` lines ~105-225).
> - Start button enable/disable logic (min players per spec Overview)
> - **Spacing consistency:** the gap between option columns MUST equal the gap between the option row and the player list panel below. Use a single spacing constant.
>
> **5. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart`:**
> - Game board / play area per the Screen Designs section layout
> - **Background image (if spec specifies one):** render it as `Positioned.fill(child: Image.asset(BACKGROUND_PATH, fit: BoxFit.cover))` as the FIRST child of the body Stack — AppBar + game content render on top of it. **Recurring miss in past sessions:** specs often list a background image but the implementation never uses it. Reference `clockwork_quest_results_screen.dart` lines ~222-228 for the canonical pattern.
> - **GAME SCREEN STRUCTURE — outer-Stack modal pattern (MANDATORY, apply EXACTLY):**
>   The game screen wraps `Scaffold` in an outer `Stack` whose siblings are the 4 visible modals, the dartboard emulator section, AND the dartboard emulator FAB. This is required so gameplay-screen modals paint OVER the AppBar (and so SaveGameModal/PausedModal cover the FAB too). A modal placed inside the Scaffold's `body:` cannot paint over the `appBar:` slot — the back arrow stays tappable behind the modal, which is the wrong UX. The FAB is moved OUT of `Scaffold.floatingActionButton` and into the outer Stack as a `Positioned` child between the emulator section and `SaveGameModal`, so it's blocked by Save/Paused but NOT by RemoveDartsModal (the user must be able to FAB-toggle the emulator visibility during takeout). Reference: any of the 6 game screens (e.g. `lunar_lander_game_screen.dart`, `clockwork_quest_game_screen.dart`).
>   ```dart
>   @override
>   Widget build(BuildContext context) {
>     // Provider data MUST be hoisted to the top of build() (not inside a
>     // Consumer<X> subtree) so the outer-Stack modals below can reference it.
>     final dartboardProvider = context.watch<DartboardProvider>();
>     final provider = context.watch<[GAME]Provider>();
>     final playerProvider = context.watch<PlayerProvider>();
>     // ... compute currentPlayer, dartsThrown, shouldPromptTakeout, etc. ...
>
>     return PopScope(
>       canPop: !hasDartsThrown || _showSaveModal,
>       onPopInvokedWithResult: (didPop, result) {
>         if (didPop || _showSaveModal) return;
>         setState(() => _showSaveModal = true);
>       },
>       child: Stack(
>         children: [
>           // 1. Scaffold — contains AppBar + body (background + main game content).
>           //    Body Stack contains ONLY background and main game UI — NO modals here.
>           //    NO floatingActionButton — moved to outer-Stack layer 4 below.
>           Scaffold(
>             appBar: AppBar(...),
>             body: Stack(
>               children: [
>                 // 1a. Background image (if any) — first child of body Stack.
>                 if (BACKGROUND_PATH != null)
>                   Positioned.fill(child: Image.asset(BACKGROUND_PATH, fit: BoxFit.cover)),
>                 // 1b. Main game content — Column with Expanded(game area).
>                 Column(...),
>               ],
>             ),
>           ),
>           // 2. RemoveDartsModal (conditional) — turn-end takeout overlay, painted
>           //    BEHIND the emulator so DARTS REMOVED stays visible/tappable on top
>           //    of the takeout modal. Paints OVER the AppBar — blocks back arrow.
>           if (shouldPromptTakeout) RemoveDartsModal(...),
>           // 3. DartboardEmulatorSection — wrapped in Positioned(left:0, right:0, bottom:0).
>           //    Sits ABOVE RemoveDartsModal so DARTS REMOVED paints on top of the
>           //    takeout overlay. Sits BELOW SaveGameModal/PausedModal so those
>           //    modals' buttons aren't intercepted by the emulator section.
>           //    NOTE: this is an outer-Stack sibling (NOT a body-Stack child) so the
>           //    Save/Paused modals above it can also cover the AppBar.
>           //    The Play To Complete button is INSIDE the emulator section's Column
>           //    (above the dartboard), so it lives at this same layer; it is disabled
>           //    when shouldPromptTakeout=true.
>           Positioned(left: 0, right: 0, bottom: 0,
>               child: DartboardEmulatorSection(...)),
>           // 4. DartboardEmulatorFAB (Positioned end-float) — moved OUT of
>           //    Scaffold.floatingActionButton into the outer Stack so RemoveDartsModal
>           //    (layer 2) does NOT block the FAB tap. The user must be able to toggle
>           //    emulator visibility during takeout (e.g. to hide the emulator and
>           //    re-show it on the takeout flow). SaveGameModal (5) and
>           //    DartboardPausedModal (6) still cover the FAB — correct, those modals
>           //    indicate states where toggling emulator visibility is irrelevant.
>           //    In real games (physical dartboard connected), DartboardEmulatorFAB
>           //    returns SizedBox.shrink anyway (`isConnected` short-circuit), so this
>           //    layer is a no-op outside emulator/test mode.
>           Positioned(right: 16, bottom: 16, child: DartboardEmulatorFAB(...)),
>           // 5. SaveGameModal (conditional) — explicit user action (back-button save flow).
>           //    Paints OVER the AppBar AND the FAB — blocks both.
>           if (_showSaveModal) SaveGameModal(...),
>           // 6. DartboardPausedModal (conditional) — MUST BE THE LAST CHILD.
>           //    Disconnected state means the dartboard hardware can't register input.
>           //    Paints OVER the AppBar AND the FAB. Auto-dismisses on reconnect.
>           if (!dartboardProvider.isEmulator &&
>               dartboardProvider.status != DartboardConnectionStatus.connected &&
>               dartboardProvider.status != DartboardConnectionStatus.emulator)
>             DartboardPausedModal(...),
>         ],
>       ),
>     );
>   }
>   // 6. EditScoreDialog — NOT an outer-Stack child. It is a Flutter routed dialog
>   //    (`showDialog()`) launched from the "Edit Score" button INSIDE RemoveDartsModal.
>   //    Navigator routes always paint above the underlying page, so when shown it
>   //    sits above ALL outer-Stack layers (including DartboardPausedModal).
>   ```
>
>   **Why this structure — outer Stack wrapping Scaffold:**
>   - **AppBar must be blocked when any modal is open.** The AppBar's leading IconButton (back arrow) is tappable. If a modal is a body-Stack child, it sits inside Scaffold's body slot and cannot paint over the AppBar — the back arrow stays tappable behind the modal, leading to confusing or destructive taps (e.g. re-triggering the save flow on top of the takeout flow). Outer-Stack siblings of the Scaffold paint OVER the entire Scaffold, including the AppBar slot.
>   - **FAB must be blocked too.** `Scaffold.floatingActionButton` paints above the body, so a body-Stack modal cannot cover the FAB. Outer-Stack siblings cover everything in the Scaffold including the FAB.
>   - **The body Stack now contains ONLY background + main game content.** The 4 modals + emulator section are all outer-Stack siblings. The internal z-order rationale (RemoveDarts < Emulator < Save < Paused) is unchanged from the prior body-Stack design — only the parent Stack moved.
>   - **EditScoreDialog already covers the AppBar+FAB by being a routed dialog** — it doesn't need to be in the outer Stack.
>   - **Provider data must be hoisted to the top of `build()`** so outer-Stack modals can reference `currentPlayer`, `shouldPromptTakeout`, etc. Use `context.watch<XProvider>()` at the start of `build()` rather than wrapping a subtree in `Consumer<X>`. The entire build rebuilds on provider notifications either way; outer-Stack siblings cannot otherwise access variables computed inside a nested `Consumer` builder.
>
>   **Why the modal z-order is what it is — semantic z-stacking driven by where each interactive button lives:**
>   - **RemoveDartsModal at the back of the modal stack**: its only interactive widget (Edit Score button) is in the centered card. The actual dismissal trigger is the DARTS REMOVED button INSIDE the dartboard emulator section. RemoveDartsModal therefore goes behind the emulator so DARTS REMOVED stays visible/tappable.
>   - **DartboardEmulatorSection above RemoveDartsModal**: its DARTS REMOVED button must paint on top of the takeout overlay so the user can finish the takeout. Sits at `Positioned(bottom: 0)` so it only covers the bottom strip of the screen.
>   - **SaveGameModal above the emulator**: the user explicitly tapped back to save — that intent wins over the takeout flow. The Don't Save button is at the bottom of the modal's centered card; painting SaveGameModal above the emulator means Don't Save isn't covered by the emulator section.
>   - **DartboardPausedModal at the very top of the outer Stack**: the dartboard is disconnected; the game can't reliably register state changes regardless of what the user taps. Painting Paused above everything visually communicates "non-functional state."
>   - **EditScoreDialog above the entire outer Stack as a routed dialog**: it is a focused, blocking interaction the user explicitly opened from inside RemoveDartsModal. Implementing it as a `showDialog()` route automatically gives it correct z-order above every outer-Stack layer, plus a barrier scrim and modal focus trap for free. The dialog's `barrierDismissible: false` and explicit Save / Cancel buttons mean it owns the user's attention until dismissed.
>   - **EditScoreDialog auto-cancels on dartboard disconnect (already implemented in `lib/widgets/edit_score/edit_score_dialog.dart`)**: because the dialog is a route, layer 5 (`DartboardPausedModal`) cannot paint above it. The shared `showEditScoreDialog` therefore watches `DartboardProvider` and, when the paused condition (`!isEmulator && status != connected && status != emulator`) becomes true, schedules a post-frame `Navigator.pop()` WITHOUT calling `onSubmit`. No score updates while disconnected — when the dartboard reconnects the user can re-open Edit Score from RemoveDartsModal. Game screens do NOT need to wire anything game-specific for this; it's centralized in the shared dialog. **Rule: any future routed dialog launched from the gameplay screen must replicate this auto-cancel-on-disconnect pattern, or layer 5 will be visually shadowed by the dialog.**
>   - **Edit Score button placement and flow (mandatory, identical across all games)**: the Edit Score button MUST live inside RemoveDartsModal and ONLY inside RemoveDartsModal — never as a standalone widget on the game screen, never in the AppBar, never in any other modal. Pass it in via `editScoreButtonKey: [GAME]GameKeys.editScoreButton` + `onEditScore: () => showEditScoreDialog(...)`. The user flow is: (1) takeout begins (3 darts thrown OR Skip Turn) → RemoveDartsModal renders → (2) user taps Edit Score → EditScoreDialog routes over the page → (3) user taps Save (provider scores updated) OR Cancel (no update) → dialog pops → (4) user is back on the game screen with RemoveDartsModal still visible (`shouldPromptTakeout` is still true) → (5) user can re-open Edit Score, or tap DARTS REMOVED inside the emulator section to finish the takeout and start the next turn. This means Edit Score is **gated by takeout** — a player cannot edit scores mid-turn (only after their 3 darts are in / they skipped), which prevents partial-turn corrections from desyncing announcements and turn state.
>   **The dartboard emulator is a TEMPORARY OVERLAY, not reserved space in the visual hierarchy.** The primary game UI (descent area, player panels, scores) should be designed to fill the FULL available screen height. Reference `monster_mash_game_screen.dart` for canonical full-height game UI + Positioned emulator overlay.
> - DartboardEmulatorFAB
> - **PlayToCompleteRunner integration:**
>   - Field: `PlayToCompleteRunner? _playToCompleteRunner;`
>   - Method: `_onPlayToComplete()` instantiates the runner with `[GAME_NAME_PASCAL]Strategy`
>   - Method: `_onCancelAutoPlay()` cancels the runner
>   - Auto-play guards on announcement and takeout chains (skip when runner is active)
>   - Dispose the runner in `dispose()`
> - RemoveDartsModal overlay (with Edit Score button inside — do NOT add a custom remove-darts button outside the modal, and do NOT add an Edit Score button anywhere outside this modal — see "Edit Score button placement and flow" rule above)
> - DartboardPausedModal overlay — show only when `!dartboardProvider.isEmulator && status != connected && status != emulator`
> - SaveGameModal (back button + PopScope pattern)
> - Skip turn button
> - **Skip Turn 0-darts bypass (mandatory, identical across all 6 games)**: the Skip Turn `onPressed` handler MUST branch on `dartsThrown`. With darts on the board (`dartsThrown > 0`), follow the normal takeout flow — schedule `_audioQueue?.announceRemoveDarts(...)` after 1500ms (where applicable) and `_mockApi?.simulateTakeoutStarted()` after 3500ms so RemoveDartsModal renders and the user is prompted to take out the darts. With NO darts on the board (`dartsThrown == 0`), there is nothing to remove, so schedule `_mockApi!.simulateTakeoutFinished()` (or `_handleTakeoutFinished()` when `_mockApi == null`) after 500ms — this short-circuits the takeout overlay and advances the player directly. Reference: `lunar_lander_game_screen.dart` and `clockwork_quest_game_screen.dart` skip-turn handlers (canonical bypass pattern). Without the bypass, players see a "Remove Your Darts" modal with no darts on the board — confusing UX. The Skip Turn `onPressed` MUST also be guarded by `provider.shouldPromptTakeout ? null : ...` so the button is disabled while a takeout is already in progress.
>   ```dart
>   onPressed: provider.shouldPromptTakeout
>       ? null
>       : () {
>           final dartsThrown = provider.getCurrentPlayerDartsThrown();
>           provider.skipTurn();
>           if (dartsThrown > 0) {
>             // Darts on board — wait for physical takeout or emulator's
>             // DARTS REMOVED button. Optional 1500ms `announceRemoveDarts`
>             // call then 3500ms `simulateTakeoutStarted`.
>             Future.delayed(const Duration(milliseconds: 1500), () {
>               if (mounted) _audioQueue?.announceRemoveDarts(/* args */);
>             });
>             Future.delayed(const Duration(milliseconds: 3500), () {
>               if (mounted) _mockApi?.simulateTakeoutStarted();
>             });
>           } else {
>             // No darts on board — auto-finish takeout to advance the player
>             // directly. RemoveDartsModal never renders for this path.
>             Future.delayed(const Duration(milliseconds: 500), () {
>               if (mounted) {
>                 if (_mockApi != null) {
>                   _mockApi!.simulateTakeoutFinished();
>                 } else {
>                   _handleTakeoutFinished();
>                 }
>               }
>             });
>           }
>         },
>   ```
>   **Verification:** UI tests for skip-turn-no-darts MUST NOT call `clickDartsRemoved` after Skip Turn — the player auto-advances. Tests for skip-turn-with-darts-thrown MUST `await tester.pump(const Duration(seconds: 4))` (or longer) after `clickSkipTurn` to let the 3500ms `simulateTakeoutStarted` schedule fire before tapping DARTS REMOVED.
> - DartboardConnectionInfo in AppBar
> - **`announceRemoveDarts` is called UNCONDITIONALLY on takeout** (not inside a precedence `else`; the call is independent of which moment-announcement won precedence)
> - **Victory flow MUST wait for DARTS REMOVED (mandatory):** When `hasWinner` becomes true after a dart throw, the game screen MUST NOT auto-navigate to the results screen. The RemoveDartsModal must still appear, the Edit Score button must remain accessible, and navigation to results must ONLY happen through the takeout flow: user clicks DARTS REMOVED → `_handleTakeoutFinished()` checks `hasWinner` → if true, calls `_handleGameWon()`.
>
>   **Prohibited patterns:**
>   - Do NOT add `if (provider.hasWinner) { addPostFrameCallback(_handleGameWon) }` in `build()`.
>   - Do NOT auto-call `simulateTakeoutStarted()` / `simulateTakeoutFinished()` on a winning turn.
>   - Do NOT call `_handleGameWon()` directly from the dart-event handler.
>
>   **Why:** The Edit Score button lives inside the RemoveDartsModal. If the game auto-navigates on a winning turn, the player cannot correct a mistaken score that triggered a false victory. The DARTS REMOVED step is the user's last chance to review and edit before the victory flow fires.
>
>   **Correct `shouldPromptTakeout` condition:** `dartsThrown >= 3 || provider.hasWinner` — ensures RemoveDartsModal always shows on a winning turn.
>
>   **Standardized `_handleTakeoutFinished()` pattern (all 6 games follow this):**
>   ```dart
>   void _handleTakeoutFinished() {
>     final provider = context.read<[Game]Provider>();
>     if (!mounted) return;
>
>     if (provider.hasWinner) {
>       _handleGameWon();
>       return;
>     }
>
>     if (!provider.isGameActive) return;
>
>     provider.handleTakeoutFinished(); // or confirmDartsRemoved() / advanceTurn()
>     // Game-specific: announce turn, scroll to player, check buffs
>     setState(() {});
>   }
>   ```
>
>   **Standardized `_handleGameWon()` pattern (all 6 games follow this):**
>   ```dart
>   void _handleGameWon() {
>     if (_gameCompleted) return;
>     _gameCompleted = true;
>
>     void navigateToResults() {
>       if (!mounted) return;
>       Navigator.pushReplacement(context,
>         MaterialPageRoute(builder: (_) => const [Game]ResultsScreen()));
>     }
>
>     if (_dartboardEmulatorController.isAutoPlaying) {
>       navigateToResults();
>     } else {
>       // Announce winner (MANDATORY — every game must announce here)
>       final provider = context.read<[Game]Provider>();
>       final playerProvider = context.read<PlayerProvider>();
>       final winnerId = provider.currentGame?.winnerId;
>       if (winnerId != null) {
>         final winner = playerProvider.allPlayers.firstWhere(
>           (p) => p.id == winnerId,
>           orElse: () => playerProvider.allPlayers.first,
>         );
>         _audioQueue?.announceWinner(winner.name);
>       }
>       Future.delayed(const Duration(milliseconds: 3000), navigateToResults);
>     }
>   }
>   ```
>
>   Key requirements:
>   - (1) `_gameCompleted` guard prevents double navigation.
>   - (2) `isAutoPlaying` check skips the delay and announcement for Play-to-Complete.
>   - (3) Winner announcement fires BEFORE the 3000ms delay (announcement plays during the delay).
>   - (4) 3000ms delay gives time for victory announcement before navigation.
>   - (5) Navigation uses `Navigator.pushReplacement` with `MaterialPageRoute` (NOT `pushReplacementNamed`).
>   - (6) `hasWinner` check is at the TOP of `_handleTakeoutFinished`, BEFORE calling the provider advance method.
>   - (7) The game's announcement helper MUST have a public `announceWinner(String playerName)` method (or equivalent like `announceVictory`).
>   - (8) The `_audioQueue` field (typed as the game's `AnnouncementHelper`) MUST be initialized in `_initializeGame()`.
>
>   **Reference:** All 6 game screens now follow this pattern. Use any as reference.
> - **Edit Score `initialSegments` MUST map a thrown miss (score 0) to `'Miss'`, NOT `'-'`.** The shared EditScoreDialog distinguishes between:
>   - `'-'` or empty → dart NOT yet thrown (`ring=null` → invalidates the dialog Save button)
>   - `'Miss'` → dart thrown as a miss (`ring='Miss'` → valid)
>   - `'S20'` / `'D20'` / `'T20'` → numeric scoring darts
>   - `'Bull'` (50) / `'25'` (outer bull)
>
>   Edit Score is only accessible AFTER the turn ends (3 darts thrown), so all 3 segments should be valid (`'Miss'`, `'Bull'`, `'25'`, or `'SX'`/`'DX'`/`'TX'` for some X). NEVER pass `'-'` for a thrown miss — it disables Save. The `onSubmit` handler must explicitly handle each segment type (`Miss`, `Bull`, `25`, regex match for `SDTsdt\d+`).
> - **Score display pattern — Total Score vs Dart Throw (choose ONE per game):**
>
>   **Pattern A — Total Score Display** (Carnival Derby, Lunar Lander): The D1/D2/D3 labels on the game screen AND the Edit Score dialog score boxes show the **calculated point value** (e.g., "60" for T20, "20" for S20). Use this when the game's scoring is based on POINT VALUES that affect player position/score (points toward target, altitude descent).
>   - `EditScoreDialogConfig` factory MUST include `scoreDisplayTransform: _gameScoreDisplay` — a static method that converts segment strings to point values (S20→"20", D13→"26", T20→"60").
>   - **Provider MUST store raw segment strings** alongside calculated scores. The game model needs a `currentTurnDartSegments` field (`Map<String, List<String>>`) that stores the original sector strings ('S20', 'D15', 'T20', 'Bull', 'Miss'). The game screen passes the raw sector string from the dart event through to the provider's `processDartThrow(sector: sector)`. Without this, the Edit Score dialog cannot reconstruct the correct ring+number pre-selection — converting calculated values back to segments is lossy (e.g., score 40 becomes 'S40' which has no matching number on the dartboard grid). The `onEditScore` handler reads `provider.getCurrentTurnDartSegments(playerId)` to get proper segments for `initialSegments`. The field must be serialized in `toJson`/`fromJson` for save/resume, cleared in `advanceToNextPlayer`, and rebuilt during `editPlayerScore` replay.
>   - **Test constraint:** Single values (S5, S10) cause duplicate text matches in the dialog because the score display AND number button show the same value. Tests MUST use Double or Triple values (D5, T5) so the score display differs from the number button (D5 → score display "10", number button "5").
>
>   **Pattern B — Dart Throw Display** (Target Tag, Monster Mash, Reef Royale, Clockwork Quest): The D1/D2/D3 labels show the **raw segment string** (e.g., "S20", "T20", "Bull"). Use this when the game's scoring is based on TARGETS HIT (reef claiming, gear activation, shield damage, elimination).
>   - `EditScoreDialogConfig` factory does NOT include `scoreDisplayTransform` (default null — raw segment string shown).
>   - **Test constraint:** No duplicate text issue since "S20" ≠ "20".
>
>   **If unsure which pattern applies to a new game, ASK THE USER before implementing.** The choice affects the Edit Score dialog config, test design, and dart indicator display. Getting it wrong means rework across multiple files.
> - All option effects visible per the spec's Options section
> - **Generic avatars only on player TILE / rankings list — do NOT assign game character images to player avatars there.** Character images go on:
>   - The active player panel (LEFT side of game screen) — render character at native size, NO circle clipping (no `border-radius: 50%` + `overflow: hidden` masking the cute character art into a circle). Use `BoxFit.contain`. Apply shape-conformal `filter: drop-shadow` for active-player glow.
>   - The descent track / coral cards / shields / etc. (per spec's Screen Designs) — same: native size, no circle clipping.
>   - The results screen winner card — same.
>
> **6. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart`:**
> - **RESULTS SCREEN STRUCTURE — outer-Stack modal pattern (MANDATORY, apply EXACTLY — same shape as game/menu screens):**
>   The results screen wraps `Scaffold` in an outer `Stack` so DartboardPausedModal can paint OVER the AppBar when the dartboard disconnects on this screen. The build method's return value is `Stack`, NOT `Scaffold`.
>   ```dart
>   @override
>   Widget build(BuildContext context) {
>     final dartboardProvider = context.watch<DartboardProvider>();
>     // ...other watch calls and computations...
>     return Stack(
>       children: [
>         // 1. Scaffold — AppBar (NO back arrow + title + DartboardConnectionInfo)
>         //    + body (background, winner card, rankings, action buttons).
>         Scaffold(
>           appBar: AppBar(automaticallyImplyLeading: false, ...),
>           body: ...,
>         ),
>         // 2. DartboardPausedModal (conditional) — LAST child; paints on top.
>         //    Same conditional as the game and menu screens.
>         if (!dartboardProvider.isEmulator &&
>             dartboardProvider.status != DartboardConnectionStatus.connected &&
>             dartboardProvider.status != DartboardConnectionStatus.emulator)
>           DartboardPausedModal(config: DartboardPausedModalConfig.[gameName]()),
>       ],
>     );
>   }
>   ```
>   Reference: any results screen for the canonical pattern (e.g. `lunar_lander_results_screen.dart`).
>   **If a future feature adds another modal to the results screen** (e.g. a confirm-delete dialog, a stats dialog), follow the same outer-Stack-wrapping-Scaffold pattern: add the new modal as another outer-Stack sibling above the Scaffold and below DartboardPausedModal (which is always the last child). Routed dialogs (`showDialog`) are also fine and will paint above the entire outer Stack — for those, follow the EditScoreDialog auto-cancel-on-disconnect rule documented in the game-screen section above.
> - **Background image (if spec specifies one):** render it as `Positioned.fill(child: Image.asset(BACKGROUND_PATH, fit: BoxFit.cover))` as the FIRST child of the body Stack — winner card + rankings + buttons render on top of it. Reference: `clockwork_quest_results_screen.dart` lines ~222-228.
> - Winner display + rankings (**winner card uses character art rendered NATIVELY without circle clipping** — no `border-radius: 50%` + `overflow: hidden`. Use `BoxFit.contain` and `filter: drop-shadow` for any glow effect. Player tiles in the rankings list use generic avatars per project rule.)
> - Victory music integration via VictoryMusicService
> - Player stats update (`updatePlayerStats`) for ALL players (winners AND losers) with the SAME `gameDuration` value
> - **Auto-delete saved game**: `_deleteResumedSavedGame()` runs INDEPENDENTLY in `WidgetsBinding.instance.addPostFrameCallback(...)` — it is NOT awaited inline after `_updatePlayerStats()` (per `save-resume-game.md`)
> - Play Again, Change Settings, Back to Menu buttons
> - **Exit / Back-to-Home button: use `Navigator.popUntil(context, (route) => route.isFirst)`. NEVER use `pushNamedAndRemoveUntil('/', (route) => false)`** — the `(route) => false` predicate breaks the navigation stack (per `docs/development/game-integration.md`).
> - **Change Settings button: use `Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => [GAME_NAME_PASCAL]MenuScreen()), (route) => route.isFirst)`** — keeps home in the stack so the menu's back button still works. NEVER use `(route) => false`.
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
> (g1) **Back arrow consistency** — read the `leading: IconButton(...)` block on the MENU and GAME screens and verify ALL of: (1) `Icon` size is `32`, (2) all three of `hoverColor`, `highlightColor`, `splashColor` are `Colors.transparent`, (3) each screen's IconButton uses its OWN keys class (`MenuKeys.backButton`, `GameKeys.backButton` — never another game's class). Menu and game MUST be identical in size, color treatment, and hover suppression. Reference: Monster Mash, Carnival Derby for the canonical pattern.
> (g2) **Results screen has NO back arrow** — read the results-screen AppBar and verify `automaticallyImplyLeading: false` is set AND no `leading:` widget is supplied. Confirm the 3 action buttons (Play Again, Change Settings, Back to Menu) are the only navigation off the results screen.
> (h) **No custom 'remove darts' button exists outside RemoveDartsModal** — grep `lib/screens/games/[GAME_NAME_SNAKE]/` for any button labeled "Remove" outside the modal
> (h1) **No Edit Score button exists outside RemoveDartsModal** — grep the game screen for any `key: ...editScoreButton` or `'Edit Score'` button outside RemoveDartsModal. The button must ONLY be wired via `RemoveDartsModal(editScoreButtonKey: ..., onEditScore: () => showEditScoreDialog(...))`. No standalone Edit Score button on the game screen, in the AppBar, or anywhere else.
> (i) Correct PlayerListPanel pattern (Dual vs Team) — and the Team config lives in `team_player_list_panel_config.dart`, not `dual_player_list_panel_config.dart`
> (j) SaveGameModal uses PopScope + outer Stack on game screen (sibling of Scaffold, not body-Stack child)
> (k) **Menu screen outer-Stack modal pattern**: build() returns `Stack`, NOT Scaffold. Outer-Stack siblings (back → front): Scaffold → `if (_showResumeModal) ResumeGameModal(...)` → conditional `DartboardPausedModal(...)` (last child, same paused condition as game screen). AddPlayerDialog is NOT a Stack child — it's a routed dialog launched from inside `DualPlayerListPanel` via `showAddPlayerDialog()` (the panel handles it; menu screen passes `addPlayerButtonKey` only).
> (k1) **Results screen outer-Stack modal pattern**: build() returns `Stack`, NOT Scaffold. Outer-Stack siblings (back → front): Scaffold → conditional `DartboardPausedModal(...)` (last child, same paused condition). `context.watch<DartboardProvider>()` must be at the top of build().
> (l) ResumeGameButton appears in menu screen AppBar, positioned to the LEFT of DartboardConnectionInfo
> (m) **`announceRemoveDarts` is called UNCONDITIONALLY in the game-screen takeout handler** (the call is not inside a precedence `else` block) — read the actual code and trace the call site
> (n) **DartboardPausedModal shown only when** `!dartboardProvider.isEmulator && status != connected && status != emulator` — read the actual conditional
> (o) **`Navigator.popUntil(context, (route) => route.isFirst)` is used for Back-to-Home** and `(route) => false` is NOT used anywhere — grep result
> (p) **`_deleteResumedSavedGame()` runs INDEPENDENTLY in `addPostFrameCallback`** on the results screen — not awaited inline after `_updatePlayerStats()`
> (q) **PlayToCompleteRunner is wired:** strategy file exists at `lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart`, `PlayToCompleteButtonConfig.[gameName]()` exists, runner field is on game screen state, runner is disposed in `dispose()`
> (r) **`HomeKeys.[gameName]Card`** exists in `lib/constants/test_keys.dart` and is used on the home_screen.dart card
> (s) **Game characters are NOT used as player TILE avatars** in the player tile / rankings list — grep `lib/screens/games/[GAME_NAME_SNAKE]/` for character image asset paths in player tile / rankings list contexts (must return zero matches there). They ARE allowed on the active player panel + descent/coral/shield game UI + winner card.
> (t) No Nunito font or Flame Orange (`#FF6B35`) used in game-screen styling
> (u) **Background image (if spec specifies one) IS rendered on game AND results screens.** Grep for the background asset path in `lib/screens/games/[GAME_NAME_SNAKE]/`. Must appear in both `[GAME_NAME_SNAKE]_game_screen.dart` AND `[GAME_NAME_SNAKE]_results_screen.dart` if a background asset is in the spec's Asset Checklist. Recurring miss in past sessions.
> (v) **Outer-Stack modal pattern on the game screen (CRITICAL — wrong structure silently breaks AppBar blocking AND the takeout/Don't Save flows):** the build method must `return PopScope(child: Stack(children: [Scaffold(...), ...modals + emulator + FAB]))`. Verify by reading the actual `return` statement: (1) PopScope's child is `Stack`, NOT `Scaffold`. (2) The Scaffold is the FIRST child of the outer Stack. (3) The Scaffold has NO `floatingActionButton:` argument — the FAB is moved to the outer Stack (see step 5). (4) Inside the Scaffold's `body: Stack(...)`, the children are ONLY the background image and the main game Column — **NO modals inside body**. (5) The outer-Stack siblings AFTER the Scaffold appear in this exact order: `RemoveDartsModal` (conditional, back) → `Positioned(bottom: 0, child: DartboardEmulatorSection)` → `Positioned(right: 16, bottom: 16, child: DartboardEmulatorFAB)` → `SaveGameModal` (conditional) → `DartboardPausedModal` (conditional, last/front). Semantics: takeout overlay sits behind the emulator so DARTS REMOVED stays tappable; FAB sits ABOVE RemoveDartsModal so the user can toggle emulator visibility during takeout (RemoveDartsModal does NOT block the FAB); save modal beats takeout AND covers the FAB so Don't Save isn't intercepted by the emulator section AND emulator toggling is irrelevant during save flow; paused-disconnect modal beats everything; the modals cover the AppBar back arrow so no AppBar control is reachable while a modal is up. The FAB is layer 4 because in real games (physical dartboard) `DartboardEmulatorFAB.build` returns `SizedBox.shrink` anyway, so this layering is only meaningful in emulator/test mode.
> (v1) **No modals inside `Scaffold.body` Stack** — grep `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart` for `RemoveDartsModal(`, `SaveGameModal(`, `DartboardPausedModal(`, `DartboardEmulatorSection(`, `DartboardEmulatorFAB(`. Each must appear EXACTLY ONCE, and the surrounding context (find the parent `Stack(children:` it lives in by reading 50 lines up) must be the OUTER Stack (sibling of Scaffold inside PopScope.child), NOT the inner body Stack. The Scaffold MUST NOT have `floatingActionButton:` or `floatingActionButtonLocation:` arguments — the FAB lives in the outer Stack as `Positioned(right: 16, bottom: 16, child: DartboardEmulatorFAB(...))`. If any of the five widgets is inside `body: Stack(...)`, OR the FAB is still on `Scaffold.floatingActionButton`, the layered behavior breaks.
> (v2) **Provider data hoisted to top of `build()`** — read the first ~20 lines of the build method and verify `context.watch<DartboardProvider>()`, `context.watch<[GAME]Provider>()`, and (when needed for outer-Stack modals) `context.watch<PlayerProvider>()` are called there. Variables computed inside a `Consumer<X>` builder are NOT visible to outer-Stack siblings; this fails compilation or silently strips data from the modals.
> (w) **DualPlayerListPanel has bounded height** on the menu screen — wrapped in `Expanded(...)` for wide layout AND `SizedBox(height: ...)` for narrow scrollable layout. Read the menu screen and verify both branches.
> (x) **Menu screen initState restores settings from `provider.currentGame`** when it's not null (so CHANGE MISSION preserves them). Read `initState()` and verify the read.
> (y) **Menu screen initState auto-shows resume modal when saved games exist on initial entry** — `setState(() { _hasSavedGames = hasSaved; _showResumeModal = hasSaved; })` inside the initial `addPostFrameCallback`.
> (z) **Victory flow waits for DARTS REMOVED** — the game screen MUST NOT auto-navigate to results when `hasWinner` becomes true. Grep the game screen for `addPostFrameCallback(_handleGameWon)` and `simulateTakeoutFinished` inside `hasWinner` blocks — neither should exist. `_handleGameWon()` must ONLY be called from `_handleTakeoutFinished()`. The `shouldPromptTakeout` condition should be `dartsThrown >= 3 || provider.hasWinner` so RemoveDartsModal (and the Edit Score button inside it) is always accessible after a winning turn.
> (aa) **Edit Score `initialSegments` maps thrown miss (score 0) to `'Miss'`, NOT `'-'`.** Read the menu/game screen's onEditScore handler and verify the segment building. The `'-'` value invalidates the dialog Save button; thrown misses must be `'Miss'`.
> (bb) **Character images on game screen + winner card are rendered NATIVELY (no circle clipping).** Grep for `border-radius:.*5[0-9]%` and `BorderRadius.circular(.*5[0-9]\.0` near `Image.asset(.*characters/`. Avatar widgets in the player tile / rankings list MAY use circles (initials placeholders); the active player panel + descent/coral/shield + winner card MUST NOT clip the character art.
> (cc) **Sound effect files follow naming convention** — list all files in `assets/games/[GAME_NAME_SNAKE]/sounds/` and verify every filename uses the `GameName-SoundName.mp3` pattern (PascalCase, hyphen separator). No snake_case filenames.
> (dd) **Sound effects config `_basePath` has no `assets/` prefix** — read the `_basePath` constant in `lib/services/[GAME_NAME_SNAKE]_sound_effects.dart` and verify it starts with `'games/'` not `'assets/games/'`.
> (ee) **Sound effects config has trim times** — verify every `SoundEffectConfig` has a non-null `endSeconds` value matching the spec's Asset Checklist.
> (ff) **Announcement helper has `dispose()` method** — read the helper class and verify a `void dispose()` method exists that calls `_queueService.dispose()`.
> (gg) **Game screen calls `announceGameStart()` in `_initializeGame()`** — grep the game screen for `announceGameStart` and verify it fires after `_audioQueue` creation. Also verify first turn is announced with a 2s delay.
> (hh) **Game screen disposes `_audioQueue`** — read the `dispose()` method and verify `_audioQueue?.dispose()` is present.
> (ii) **Per-dart announcements wired in `_handleDartThrow`** — verify the game screen calls announcement methods after `processDartThrow()` with an `isAutoPlaying` guard. Announcements must follow precedence (victory > milestone > advance > miss).
> (jj) **Game-with-announcements integration test exists** — verify `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_with_announcements_test.dart` exists with lifecycle, moment, precedence, and auto-play suppression tests.
> (kk) **DartboardPausedModal UI tests exist** — verify `integration_test/[GAME_NAME_SNAKE]/pause_modal/` directory exists with 3 test files: `menu_pause_test.dart` (7 tests), `gameplay_pause_test.dart` (8 tests), `results_pause_test.dart` (5 tests). These verify the pause modal appears on disconnect, blocks all interaction (AppBar, buttons, modals), and dismisses on reconnect. The gameplay test must verify EditScoreDialog auto-closes on disconnect.
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
> **Mandatory conventions (all 6 existing games follow these — do NOT diverge):**
>
> - **Sound file naming:** `GameName-SoundName.mp3` (PascalCase game name, PascalCase sound name, hyphen separator). Example: `ClockworkQuest-GearClick.mp3`, `LunarLander-ThrusterBurn.mp3`. Do NOT use snake_case filenames.
> - **Sound effects config `_basePath`:** `'games/[game_name_snake]/sounds/'` — NO `assets/` prefix. The Flutter asset system prepends `assets/` automatically.
> - **Sound trim times:** Every `SoundEffectConfig` MUST have an `endSeconds` value from the spec's Asset Checklist. Do NOT leave `endSeconds: null` — untrimmed audio makes the game feel sluggish.
> - **Announcement helper `dispose()`:** Every helper class MUST have a `void dispose() { _queueService.dispose(); }` method. The game screen calls `_audioQueue?.dispose()` in its `dispose()`.
> - **Game screen audio wiring checklist:**
>   1. `_audioQueue` field typed as the game's `AnnouncementHelper?`
>   2. Initialized in `_initializeGame()` via `GameAnnouncementQueueService` + `loadSettings()`
>   3. `announceGameStart()` called after init
>   4. First turn announced with 2000ms delay
>   5. Per-dart moment announcements in `_handleDartThrow` (with precedence chain + `isAutoPlaying` guard)
>   6. Remove darts announcement at 1500ms delay when `shouldPromptTakeout`
>   7. Turn announcement in `_handleTakeoutFinished` at 500ms delay (with `isAutoPlaying` guard)
>   8. `_audioQueue?.dispose()` in `dispose()`
> - **Test file:** `[GAME_NAME_SNAKE]_game_with_announcements_test.dart` testing full game flow with announcements (~18 tests covering lifecycle, moments, milestones, precedence, auto-play suppression)
>
> **Files to create:**
> 1. `lib/services/[GAME_NAME_SNAKE]_sound_effects.dart` — every sound file from the Asset Checklist + Announcements section with correct start/end times
> 2. `lib/services/[GAME_NAME_SNAKE]_announcement_helper.dart` — every announcement event with correct priority levels and sound effect associations, implementing the stacking precedence rules above. MUST include `dispose()` method.
> 3. `test/mocks/mock_[GAME_NAME_SNAKE]_audio_queue_service.dart`
> 4. `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_announcement_test.dart`
>    - Every test from the spec's Announcements testing section
>    - A test verifying max 2 announcements fire on the worst-case dart
>    - A test verifying "Remove your darts" always plays (cannot be suppressed)
> 5. `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_with_announcements_test.dart`
>    - Integration tests verifying announcements fire correctly from game state changes via the provider
>    - Lifecycle tests (game start, turn change, remove darts)
>    - Per-dart moment tests (hit, miss, advance, milestone events)
>    - Precedence tests (higher-priority events suppress lower-priority)
>    - Auto-play suppression tests (no announcements fire during Play-to-Complete)
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

**Goal:** Write all UI tests in the proper subdirectory layout (including mandatory navigation, results, and play-to-complete tests), synchronize the 12 shared helpers, update all 4 batch files, run the spec coverage audit.

**Model:** Sonnet sub-agent for shared helper sync + UI test files + screenshot test + batch file updates; orchestrator (Opus) for the spec coverage audit + AR-6 + Gate 3.

### Step 7A: Delegate UI test infrastructure to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 7 (UI Automation Tests) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — Testing Plan section (UI test list and screenshot test states)
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/testing/test-maintenance.md` — **CRITICAL: shared helper synchronization rules**
> - `docs/testing/shared-helpers-reference.md` — **authoritative reference for all 12 mirrored shared helpers, the `_helpers.dart` delegate pattern for per-subdirectory game-specific helpers, and the decision tree for where new helper functions belong**
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
> There are **12 mirrored shared helper files** that must stay byte-identical between `test/shared/` and `integration_test/shared/`:
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
> - `save_resume_helpers.dart`
> - `settings_helpers.dart`
> - `ui_test_helpers.dart`
>
> Apply game-specific changes to each that needs them in BOTH directories.
>
> **Note:** `test/shared/` also contains additional non-UI-only files (`mock_api_helpers.dart`, `player_test_utils.dart`, `sector_parser.dart`, plus their `_test.dart` files) that have NO `integration_test/shared/` counterpart. The byte-identical synchronization rule applies ONLY to the 12 mirrored files above.
>
> After editing, for every pair `test/shared/X.dart` ↔ `integration_test/shared/X.dart` in the 12-file list, run `diff` and confirm byte-identical (apart from the path, contents must match).
>
> **1.5. Create per-subdirectory `_helpers.dart` files** (delegate pattern from `docs/testing/shared-helpers-reference.md`):
>
> Every test subdirectory needs an `_helpers.dart` file. Follow the delegate pattern documented at lines 76-163 of `docs/testing/shared-helpers-reference.md`:
> - Import the relevant shared helpers from `../../shared/`
> - Expose **one-line delegate functions** that preserve the local function names test files already use (e.g., `Future<void> setupGame(...) => GameSetupHelpers.setupGame(...)`)
> - ONLY add genuinely game-specific logic that doesn't belong in shared helpers (e.g., a `completeGameToVictory()` that knows how to drive THIS game's win condition)
> - When unsure whether new logic belongs in `_helpers.dart` or in the shared helpers, follow the decision tree in `shared-helpers-reference.md` (used by ≥2 games → shared; used only by this game → `_helpers.dart`).
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
> - `save_resume/` — Save/Resume tests
> - **`navigation/`** — the 4 mandatory navigation tests (see below)
> - **`play_to_complete/`** — Play-to-Complete tests (see below)
> - `visual_validation/` — Screenshot test (Step 7 below)
> - **`pause_modal/`** — Dartboard pause modal tests (3 files: `menu_pause_test.dart`, `gameplay_pause_test.dart`, `results_pause_test.dart`)
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
> - `edit_creates_winner_stats_test.dart` — Position the game near the win condition (programmatically or via gameplay), throw 3 non-winning darts, open Edit Score and change darts to winning values. Verify `hasWinner == true`, call `clickDartsRemoved(tester)`, wait for results screen navigation (pump 4 seconds for `_handleGameWon` delay + 5 seconds for `_updatePlayerStats` async call + `PumpSequences.fullRebuild`), then verify: `VictoryMusicService().isInitialized == true`, winner `gamesPlayed == 1`, winner `gamesWon == 1`, winner `gameHistory.length == 1`, winner `gameHistory.first.gameName == '[GAME_NAME_DISPLAY]'`, loser `gamesPlayed == 1`, loser `gamesWon == 0`.
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
> **7. Visual validation tests** (in `integration_test/[GAME_NAME_SNAKE]/visual_validation/`):
>
> Two categories are required: a screenshot test AND programmatic visual state tests. Together these cover both broad visual regression (screenshots) and specific UI state assertions (programmatic).
>
> **7a. Screenshot test** — `[GAME_NAME_SNAKE]_screenshot_test.dart`:
> - Capture every state listed in the spec's Testing Plan visual checklist
> - **CRITICAL:** must be runnable via `test_driver/screenshot_test.dart` as the driver
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
> **8. Update ALL FOUR batch files** with the new game:
> - `run_ui_tests.bat`
> - `run_ui_tests_stub.bat`
> - `run_ui_tests_parallel.bat` — TWO places to update:
>   1. The `GAMES` variable (top of file, ~line 15) — add `[GAME_NAME_SNAKE]`
>   2. The pre-run worktree cleanup `for %%G in (...)` loop (~line 272) — add `[GAME_NAME_SNAKE]` to the hardcoded list. Without this, stale worktrees from a previous failed run for the new game won't be auto-cleaned at startup, which can cause `git worktree add` to fail and abort the entire run. Grep `run_ui_tests_parallel.bat` for the existing list of game names; both occurrences must include the new game.
> - `run_ui_tests_parallel_stub.bat` — same dual-update if the stub variant has the same hardcoded cleanup list
>
> Also update the port-assignment table in `docs/testing/ui-automation.md` for the new game (Server = `9000 + N`, ChromeDriver = `4443 + N`, where N is the new index).
>
> **Report back:**
> - File paths created and modified, organized by subdirectory
> - For each pair of shared helpers (12 pairs), `diff` result (must be byte-identical)
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
- Run `diff` on each of the 12 shared-helper pairs yourself
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
> (c) **Verify all FOUR batch files include the new game:** `run_ui_tests.bat`, `run_ui_tests_stub.bat`, `run_ui_tests_parallel.bat`, `run_ui_tests_parallel_stub.bat`. For `run_ui_tests_parallel.bat` SPECIFICALLY: grep for the new game name and verify it appears in BOTH (1) the `GAMES` variable AND (2) the pre-run worktree cleanup `for %%G in (...)` loop near line 272. Past failure: Lunar Lander was added to GAMES but not to the cleanup loop, leaving stale worktrees uncleaned across runs. Also verify the port-assignment table in `docs/testing/ui-automation.md` was updated.
>
> (d) Verify all 12 mirrored shared helpers in `test/shared/` and `integration_test/shared/` are synchronized — diff each pair and report any mismatches. (Non-mirrored `test/shared/` files like `mock_api_helpers.dart`, `player_test_utils.dart`, `sector_parser.dart` are excluded from this check.)
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
> (l) **Build a "Visual element" coverage matrix from spec Section 10** (Screen Designs) — list every distinct UI state (e.g., "Active player track is orange", "Altitude pill turns red when negative", "Hard Landing badge appears in AppBar", "Win flag shows on results"). For each visual state, identify the programmatic UI test that verifies it. List any visual state without a corresponding test.
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

**Hung-process safety:** Past sessions have seen the screenshot test deadlock for 25+ minutes when the game UI has a build error or missing widget. The orchestrator imposes a **60-second progress timeout** on the screenshot test process — if no new screenshot files appear in `temp_screenshots/` for 60 seconds AND the flutter_drive process hasn't exited, the orchestrator instructs the sub-agent to KILL chromedriver + chrome + flutter_drive, read the partial log, and assess what's wrong before retrying. Don't let a single deadlocked run burn 10+ minutes.

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

**Per-screen iteration option (when full screenshot test breaks midway):** if the screenshot test fails partway through (e.g., screenshots 1-7 captured, 8-11 missing because step 8 throws), don't loop on the full test. Instead:
1. Diagnose what's wrong with the screen at the failure point (read the partial log + assess widget tree state).
2. Dispatch a focused diagnostic sub-agent to capture JUST the failing screen state via a minimal targeted test that sets up just enough state for that screen.
3. Once that one screen renders, re-run the full screenshot test. Per-screen iteration is much faster than re-running the full ~4-minute screenshot capture for each fix.

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

Proceed to STEP 10 (final user acceptance).

---

### STEP 10: FINAL USER ACCEPTANCE GATE (mandatory)

After the orchestrator's iterative review passes, present the FINAL screenshot set + Phase 2 wireframes to the user for explicit acceptance:

> "All gates have passed internally. Before we move to documentation, please review the final visual state:
>
> 1. Open `temp_screenshots/` and review every captured screenshot.
> 2. Open `temp_wireframes/[GAME_NAME_SNAKE]/index.html` and compare against the Phase 2 wireframes you originally approved.
>
> Confirm:
> - The implementation matches the wireframe intent (colors, fonts, layout, character/imagery use).
> - All player counts (min/mid/max) render correctly.
> - All option states are represented (defaults, alternates, ON/OFF toggles).
> - All screens look polished and family-friendly at scale.
>
> Reply: ✅ **Accept** (proceed to AR-7) — OR — 🔧 list specific UI changes you'd like."

**STOP and wait for user response.**

If the user requests changes:
- Dispatch a Sonnet sub-agent to apply the UI fixes to the relevant screen file(s).
- After the sub-agent returns, **go back to STEP 1.** Re-capture AND re-evaluate ALL screenshots.
- Then re-run the UI test suite (STEP 5) and non-UI tests (STEP 7).
- Repeat the entire Phase 8 cycle until the user explicitly accepts.

**Do NOT proceed to AR-7 until the user has explicitly accepted.** The orchestrator's "all gates pass" is necessary but not sufficient — final visual judgement is the user's.

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
- [ ] All 12 mirrored shared helpers synchronized (test/shared/ matches integration_test/shared/)
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
1. Sub-agent must update BOTH `test/shared/` AND `integration_test/shared/` (all 12 mirrored files in each — non-mirrored `test/shared/` files like `mock_api_helpers.dart`, `player_test_utils.dart`, `sector_parser.dart` are excluded).
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

### Per-Phase Auto-Revert Audit (mandatory, applies in YOLO mode)

After EVERY phase completes (and before moving to the next), the orchestrator runs:

```bash
git diff master...HEAD --name-only
```

For each file in the output, verify it's within the additive allowed zones (see "Universal Rule: Limit Changes to the New Game" at the top of this skill). Any file outside those zones triggers:
1. `git checkout master -- <file>` to revert.
2. A corrective Sonnet sub-agent dispatch with a tightened prompt that includes the specific violation.
3. The phase's gates re-run after the revert + corrective fix.

This catches sub-agents that drift out of scope before the divergence cascades into AR-9 / Gate 5.

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
