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
- All 9 adversarial reviews (AR-1 through AR-9) plus AR-Coverage (Phase 10 self-check)
- Phase 5 announcement stacking analysis (the *design* of precedence, before implementation)
- Phase 6 data migration decision
- Phase 7 spec coverage audit
- Phase 8 Step 2 screenshot evaluation against the visual checklist
- Phase 9 simultaneous-pass verification
- Phase 10 cross-game test-coverage audit, gap synthesis, and remediation planning (the audit itself stays on the orchestrator; only test-writing in Step 8 is delegated)
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
- Phase 10 Step 8 — writing the new tests that close approved coverage gaps (audit + planning stays on orchestrator)
- Phase 11 documentation files + CLAUDE.md and testing docs updates

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
> - Mirrored shared helpers in `test/shared/` and `integration_test/shared/` — additive only (new game-specific helpers); see Rule §26 for the dynamic-discovery rule
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
> - Spec file: `[SPEC_PATH]` — focus on the "Asset Checklist" section (Section [N]) and "Development Workflow" (Section [M]) per the section map below. The Asset Checklist MUST have BOTH a "Source File" column (where the user dropped the raw asset, typically under `C:\Users\steve\Downloads\<GameName>\...`) AND a "File Path" column (canonical target path under `assets/games/[GAME_NAME_SNAKE]/...` with the project's `[GameName]-[Element].ext` PascalCase convention). The skill auto-copies + renames from Source → File Path; the user does NOT pre-stage assets in the project tree.
> - Section map (from Phase 0): [PASTE SECTION MAP TABLE]
> - `docs/development/asset-organization.md` — pay attention to the filename convention `[GameName]-[Element]-[Variant].ext` (PascalCase, hyphens between game name and element, prefixed with game name).
>
> **Tasks (in order):**
> 1. Run `git branch --show-current`. If not on `[BRANCH_NAME]`:
>    - If the branch exists: `git checkout [BRANCH_NAME]`
>    - Otherwise: `git checkout -b [BRANCH_NAME]`
> 2. Create the asset folder structure under `assets/games/[GAME_NAME_SNAKE]/` (use `mkdir -p`). Include every subdirectory the spec's Asset Checklist references (typically `icons/`, `images/`, `characters/`, `sounds/`) — create them ALL up front, even if some asset types are absent.
> 3. **Auto-copy + rename every asset** from the spec's Asset Checklist Source File column → File Path column. For each row:
>    - If the **target File Path already exists**, skip (idempotent re-run safety) — log "SKIP (already in place): <target>".
>    - Else if the **Source File exists**, copy with renaming via `cp "<source>" "<target>"`. Create any missing intermediate directories. Log "COPY: <source> → <target>".
>    - Else (both missing) — STOP immediately, do NOT proceed. Report the missing asset(s) to the orchestrator: list every row where neither source nor target exists. The user must place the source files at the spec's listed Source paths before re-running.
>    - The renaming is mechanical and unconditional — the spec's File Path column IS the canonical target. Do NOT prompt the user before renaming; the spec's File Path column is the authority.
> 4. **Verify the home-screen card icon is now at the expected target path** (typically `assets/games/[GAME_NAME_SNAKE]/icons/[GameName]-Icon.png` per the spec's Asset Checklist + `docs/development/adding-games.md`). This will be referenced by the home_screen.dart card in Phase 4.
> 5. For every asset listed in the spec's Asset Checklist, build a verification table AFTER the copy pass:
>    | Asset (spec) | Source path | Target path | Filename convention OK? | PRESENT (post-copy)? |
>    Filename convention: `[GameName]-[Element]-[Variant].ext`, PascalCase, hyphens between game name and element, no spaces, prefixed with the game name. Every row's "PRESENT (post-copy)?" column MUST be YES; if any is NO, dispatch the copy logic again or stop and surface to the orchestrator.
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
> - The copy-pass log from step 3 (each row: COPY / SKIP / FAIL)
> - The verification table from step 5 (paths, naming, present-post-copy)
> - Confirmation the home-screen icon is at the expected target path
> - The diff applied to `pubspec.yaml` (or "no changes needed")
> - The output of `flutter pub get`
> - Confirmation that `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` was written
> - The active git branch
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote. All work stays on `[BRANCH_NAME]`.
> - Modify any files outside `pubspec.yaml` and the new `assets/games/[GAME_NAME_SNAKE]/` tree (the asset copies and the directories required for them are the ONLY allowed creations).
> - Create any placeholder asset files (only copy real source files from the spec's Source paths)
> - Overwrite an asset that already exists at the target path (skip — see step 3 idempotency rule)
> - Skip `flutter pub get`
> - Proceed if any source AND target are both missing — STOP and surface to the orchestrator instead

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
> (h) **Background image suitability check.** Read `[GameName]-Background.png` (and any per-screen background) using the Read tool. Evaluate it against the spec's Style section: is the image a TEXTURE (parchment, gradient, low-detail wash) suitable as a backdrop for UI overlays, OR a fully ILLUSTRATED SCENE (characters, dense detail, high-contrast features) that will visually compete with foreground elements? Past failure: Pirate's Grid shipped with a fully illustrated pirate scene as `PiratesGrid-Background.png`; UI elements (settings boxes, player tiles, dart indicators) were buried against the busy art and had to be polished with a 65% Ocean Navy overlay after the build. If the image looks too detailed for an overlay backdrop, surface this to the user IMMEDIATELY ('the user-provided background is illustrated rather than textured — recommend either (a) replace with a low-detail texture, OR (b) plan to add a translucent color overlay (e.g., `Container(color: navy.withOpacity(0.65))`) on top of the bg in every screen so UI is readable'). The Stage A wireframe sub-agent in Phase 2 needs this decision baked in, not discovered later.
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
- **Use the actual background image as the page background on EVERY screen — menu, game, AND results.** This is non-negotiable. Past failure: the Pirate's Grid initial wireframes used a parchment-style placeholder background; the actual user-provided `PiratesGrid-Background.png` was a fully illustrated scene that buried UI elements. Two recurrences across multiple games where Stage A/B/C wireframes silently reverted to a CSS gradient or a plain dark fill instead of `background-image: url('../../assets/games/[GAME_NAME_SNAKE]/images/[GameName]-Background.png')`. Verification: `grep -c '[GameName]-Background' temp_wireframes/[GAME_NAME_SNAKE]/*.html` must report ≥ 1 hit per HTML file.
- Use the actual character images on player tiles, descent tracks, winner card, etc.
- Use the spec's exact hex codes (no "approximate" colors)
- Load the spec's Google Fonts via `<link>` tags
- Match the spec's Style section closely — the wireframe should be nearly indistinguishable from the final game in colors/fonts/imagery

The ONLY stylistic restriction: do NOT use the container app's tokens (Nunito font, Flame Orange `#FF6B35`, etc.).

**CRITICAL — Design for the default headless test viewport (1366×768):**

The parallel UI test runner uses Chrome in headless mode at the default Chrome viewport (1366×768 wide on Windows, sometimes 1280×800 on macOS). Wireframes that look fine at desktop monitor sizes (1920×1080+) but overflow at 1366×768 produce screenshot tests that pass capture but fail layout (clipped buttons, overflowing text, RenderFlex errors). Past failures from the Pirate's Grid build: 76px player-column overflow at default viewport; grid not centered when the height-based cell size shrunk below the width-based one; winner character overflowing on small viewports because the Column had a fixed 420px size. Each cost an iteration round on screenshot review.

- Author every wireframe HTML with a fixed wrapper of `width: 1366px; height: 768px` for the orchestrator's visual review (so the HTML matches what tests see)
- Inside that wrapper, use responsive layout primitives (`LayoutBuilder` equivalents: % widths, `min/max` clamps, flex/grid) so the design adapts gracefully when run-time constraints differ
- Verify in the browser dev tools at exactly 1366×768 — no horizontal scroll, no clipped buttons, no overflow indicators

The orchestrator's AR-2 review explicitly checks the wireframe at this viewport before approving the stage.

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
> - **Game UI fills the full screen height. The dartboard emulator is a transparent OVERLAY anchored to the bottom — NOT a sibling that competes for vertical space.** The most common Phase 2 mistake (re-occurring across at least 3 game builds) is to lay out the wireframe as `Column[gameContent, dartboardEmulator]` where the emulator gets ~150-200px of inline height and the game content gets the rest. That model is WRONG. The emulator only renders when `!dartboardProvider.isConnected`; in production gameplay (board connected) the game content has the FULL screen height. The wireframe must reflect this: gameContent is the entire screen, dartboardEmulator is `position: absolute; bottom: 0; left: 0; right: 0;` at z-index 1 (or `Positioned(bottom: 0)` inside the OUTER Stack — sibling of Scaffold, NOT inside the body Stack). Otherwise the actual game-screen layout shrinks vertically when transplanted from wireframe to Flutter, and per-player columns / grids / tracks overflow at the default 1366×768 headless viewport. Past failure: PG game-screen layout overflowed by 76px because cellSize was clamped against the wireframe's reduced height that already accounted for an inline emulator.
> - AppBar: back button, title, DartboardConnectionInfo on the right (NO ResumeGameButton on game screen)
> - Active player panel (LEFT, 200px wide per spec Section 10B if specified): use the player's CHARACTER IMAGE rendered NATIVELY (no circle clipping, `object-fit: contain`). Apply a shape-conformal `filter: drop-shadow` for active-player glow.
> - Player progress visualization (descent track / coral cards / shields / etc. per spec): use REAL CHARACTER IMAGES, not rocket/circle placeholders. Render them at native size with no circle masking.
> - **Background: use the real background image** from `assets/games/[GAME_NAME_SNAKE]/images/...`. Even if the spec doesn't explicitly call for one on the game screen, use the same background image the menu uses (visual continuity). The background must be visible on the game screen (recurring miss in past sessions).
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
> - **DualPlayerListPanel alignment + spacing — MUST match the options-row exactly** (recurring miss across builds — Carnival Derby, Reef Royale, Clockwork Quest, Lunar Lander, Pirate's Grid, AND Gladiator Arena all shipped with this wrong on first cycle and required a polish pass). The two list panes must visually align with the option boxes above them: the AVAILABLE pane's left edge = the left option box's left edge, the SELECTED pane's right edge = the right option box's right edge, and the gap between the two panes = the gap between the two option boxes in a row.
>
>   The `DualPlayerListPanelConfig` has THREE knobs that control this:
>   - `availableContainerMargin` (defaults to `EdgeInsets.only(left: 16.0)`)
>   - `selectedContainerMargin` (defaults to `EdgeInsets.only(right: 16.0)`)
>   - `listGap` (defaults to `16`)
>
>   **The defaults are wrong for the canonical menu layout.** Every game's factory MUST explicitly override:
>   ```dart
>   availableContainerMargin: EdgeInsets.zero,
>   selectedContainerMargin: EdgeInsets.zero,
>   listGap: 4,  // ← NOT the same as the SizedBox(width: N) in the options row — see below
>   ```
>
>   **CRITICAL — `listGap` value is COUNTERINTUITIVE.** The instinct is to make `listGap` equal to the `SizedBox(width: N)` between the option boxes (e.g. `8` if options use `SizedBox(width: 8)`). **THAT IS WRONG.** Using `listGap: 8` produces a VISIBLY WIDER gap between the panes than between the options because the SHARED `dual_player_list_panel.dart` widget hardcodes `padding: EdgeInsets.all(16.0)` inside each section (lines 89 + 212). That 16px inner padding pushes the list content (player tiles) 16px in from each pane's visible border, while options-row content typically only has 12-16px horizontal padding inside its boxes. The net visual gap between PANES (including the 16+16 inner padding) is much wider than the visual gap between OPTIONS at the same `listGap == option-row-SizedBox` value. Empirically, `listGap: 4` (HALF of the options-row SizedBox value) compensates for this and makes the visible BOX-to-BOX gap appear to match.
>
>   **Recommended option-box internal padding:** `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` to match the panes' inner 16px horizontal padding. With both at 16px horizontal, the option-content x-positions and player-tile x-positions visually align (the option labels/controls sit at the same indent inside the option box as the player tiles do inside the pane). Combined with `listGap: 4`, this produces a visually balanced layout.
>
>   **Recipe (apply EXACTLY in the new game's factory + menu screen):**
>   - In `DualPlayerListPanelConfig.[gameName]()`:
>     ```dart
>     availableContainerMargin: EdgeInsets.zero,
>     selectedContainerMargin: EdgeInsets.zero,
>     listGap: 4,
>     ```
>   - In the menu's `_buildTargetScoreBox()` and `_buildToggleBox()`:
>     ```dart
>     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
>     ```
>   - In the settings row's `Row` between option boxes:
>     ```dart
>     const SizedBox(width: 8),  // visible options-row gap
>     ```
>
>   Why these specific values: the SHARED widget's hardcoded `EdgeInsets.all(16)` is the constant that drives everything else. Until the shared widget is updated to expose a `sectionPadding` config knob, every game must work around it via the smaller `listGap`. If you need a different visual gap, scale `listGap` proportionally — but document it in your factory with a comment explaining the perceived-vs-actual distinction.
>
>   **AR-4 audit (mandatory grep):**
>   ```
>   grep -nA1 '[GAME_NAME_PASCAL]\b\|gladiatorArena\b' \
>     lib/widgets/player_list_panel/dual_player_list_panel_config.dart \
>     | grep -E 'availableContainerMargin|selectedContainerMargin|listGap'
>   ```
>   Must show: `availableContainerMargin: EdgeInsets.zero`, `selectedContainerMargin: EdgeInsets.zero`, `listGap: 4` (NOT 8 — see counterintuitive note above). Then visually compare the screenshot at the menu_4_players_ready or menu_default state — the gap between AVAILABLE/SELECTED panes should look EQUAL to the gap between TARGET SCORE/DOUBLE FINISH boxes, and the player tiles' left edge should align with the option labels' left edge.
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
>   - **Game/Player providers in the RESULTS screen MUST also use `context.watch` (not `context.read`).** The results screen has early-return paths for `currentGame == null` and `winners.isEmpty`/`winnerId == null`. If the screen builds before the provider state is fully populated AND uses `context.read`, the screen never re-renders when the data arrives — it stays stuck on a "No game data" / "No winner found" placeholder, hiding the Play Again / Change Settings / Back to Menu buttons and breaking every results-screen test. **Pattern recurrence:** Lunar Lander (round 2 fix), Monster Mash + Reef Royale + Target Tag (round 4 fix). Carnival Derby uses `Consumer2<HorseRaceProvider, PlayerProvider>` which is also fine. Clockwork Quest uses `Provider.of<X>(context)` (defaults to listen=true, equivalent to `context.watch`). All new games' results screens MUST use `context.watch` — verify in AR-4 below. The DartboardProvider can stay on `context.watch` (no change). Background services (e.g. VictoryMusicService, SaveGameService cleanup) are fine to fetch via `context.read` from inside `initState` / `addPostFrameCallback` — only the BUILD METHOD'S provider lookups for the game/player providers need `context.watch`.
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
> - Player stats update for ALL players (winners AND losers) with the SAME `gameDuration` value. **MUST batch in a single call** — `await playerProvider.batchUpdatePlayerStats([for (final id in playerIds) PlayerStatsUpdate(playerId: id, won: ..., gameName: ..., gameDuration: ..., dartThrows: ..., turns: ..., playerCount: ...)]);`. Do NOT loop `playerProvider.updatePlayerStats(...)` per player — every shipped game uses the batch call (server-side `POST /api/v1/players/history/batch` wraps the inserts in a single transaction, saving N-1 HTTP round-trips per match). Reference: any results screen (e.g. `reef_royale_results_screen.dart` `_updatePlayerStats` body, ~line 113). Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding A1.
> - **Auto-delete saved game**: `_deleteResumedSavedGame()` runs INDEPENDENTLY in `WidgetsBinding.instance.addPostFrameCallback(...)` — it is NOT awaited inline after `_updatePlayerStats()` (per `save-resume-game.md`)
> - Play Again, Change Settings, Back to Menu buttons
> - **Exit / Back-to-Home button: use `Navigator.popUntil(context, (route) => route.isFirst)`. NEVER use `pushNamedAndRemoveUntil('/', (route) => false)`** — the `(route) => false` predicate breaks the navigation stack (per `docs/development/game-integration.md`).
> - **Change Settings button: use `Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => [GAME_NAME_PASCAL]MenuScreen()), (route) => route.isFirst)`** — keeps home in the stack so the menu's back button still works. NEVER use `(route) => false`.
> - DartboardConnectionInfo in AppBar
>
> **7. Add the game card to `lib/screens/home_screen.dart`:**
> - Use the icon from `assets/games/[GAME_NAME_SNAKE]/icons/icon.png` (or whatever the spec specifies)
> - Tag the card with `key: HomeKeys.[gameName]Card` (added in step 1)
> - Set `'gameId': '[GAME_NAME_SNAKE]'` on the card map so the filter bar can match it against the filter registry (per Rule §42)
> - Wire navigation to the route name (added in step 8)
> - Match the visual style of existing cards
>
> **7a. Register filter metadata in `lib/constants/game_filter_registry.dart`:**
>
> The home-screen filter bar reads `GameFilterRegistry` to decide which cards to render given the user's filter selections. Every game MUST register an entry — without it, the card shows but the user can't filter to it / away from it consistently.
>
> Add a `GameMetadata` entry with all five fields populated:
> ```dart
> GameMetadata(
>   gameId: '[GAME_NAME_SNAKE]',          // matches the card's gameId
>   displayName: '[GAME_NAME_DISPLAY]',   // e.g. "Pirate's Grid"
>   maxPlayers: MaxPlayersBucket.<one>,   // twoOnly | upToEight | upToTen
>   gameplayStyles: {GameplayStyle.<one or more>}, // race | versus | strategy
>   playerInteraction: PlayerInteraction.<one>,    // parallel | light | heavy
>   gameLength: GameLength.<one>,         // quick | medium | long (at default settings)
>   soloTeam: SoloTeamSupport.<one>,      // soloOnly | soloOrTeam
> ),
> ```
> Decision guide:
> - **maxPlayers** — `MaxPlayersBucket.twoOnly` if exactly 2; `upToEight` if up to 8; `upToTen` if up to 10. Add a new bucket if the new game has a different cap.
> - **gameplayStyles** — `race` (first to a goal, no inter-player effects), `versus` (direct attacks/eliminations), `strategy` (claim positions/patterns). Set may contain multiple if the game spans styles; existing games each have one.
> - **playerInteraction** — `parallel` (no inter-player effects, side-by-side races), `light` (occasional disruption like steal/buff/claim), `heavy` (direct attacks/damage/eliminations).
> - **gameLength** — `quick` (< 10 min at defaults), `medium` (10–25 min), `long` (25+ min). At-default-settings duration only.
> - **soloTeam** — `soloOrTeam` if the spec calls out a Team mode toggle; `soloOnly` otherwise.
>
> If the spec introduces a new filter criterion entirely (e.g. "Family-friendly" / "Adult"), add the enum to `lib/models/game_metadata.dart`, add the field to `GameMetadata`, populate it for ALL existing games' registry entries, and add a dropdown to `lib/widgets/game_filter_bar/game_filter_bar.dart`. Then add a `FilterCriterion` enum value and the `HomeKeys.filter<NewCriterion>Button` + per-option key in `lib/constants/test_keys.dart`. Past failure: if the registry entry is missing, the card silently fails the orphan check in `test/models/game_metadata_test.dart` → game appears unfiltered but doesn't appear in any filtered view.
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
> (e) **Stats persistence MUST batch:** read the results screen's `_updatePlayerStats` body and verify it calls `playerProvider.batchUpdatePlayerStats([...])` exactly once with one `PlayerStatsUpdate` per player. Verify the file does NOT contain a `for (... in playerIds) await playerProvider.updatePlayerStats(...)` loop. The legacy per-player `updatePlayerStats` API still exists but the results screen MUST use the batch path so the server-side single-transaction route fires once instead of N times. Reference: any results screen (e.g. `monster_mash_results_screen.dart::_updatePlayerStats`). Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding A1.
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
> (v3) **Results screen uses `context.watch` (NOT `context.read`) for the game and player providers in `build()`** — read the first ~10 lines of the results screen's build method and verify the game-specific provider AND `PlayerProvider` are accessed via `context.watch` (or `Provider.of<X>(context)` which defaults to listen=true, or wrapped in a `Consumer`). If they use `context.read` AND the screen has any early-return path for `currentGame == null` / `winners.isEmpty` / `winnerId == null`, the screen will get stuck on the placeholder when the test/user reaches it before provider data finishes loading — Play Again / Change Settings / Back to Menu buttons never appear. Recurring miss: caught in Lunar Lander, Monster Mash, Reef Royale, Target Tag in past sessions. The `DartboardProvider` itself can stay on `context.watch` (it's already correct in all games).
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
> (ll) **Continuous-animation subtrees wrapped in `RepaintBoundary`** — grep `lib/screens/games/[GAME_NAME_SNAKE]/` and `lib/widgets/[GAME_NAME_SNAKE]_*` for every `AnimatedBuilder(` and verify a `RepaintBoundary` ancestor wraps the animated subtree as closely as possible. Without it, animation frames dirty sibling widgets and force the entire screen to repaint per frame. Also flag any AnimationController-driven custom widget that paints continuously (background pulses, progress glow, character animations) without an enclosing `RepaintBoundary`. Reference: `lib/widgets/carnival_string_lights.dart` `_buildBulb` for the canonical pattern. Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding A4.
> (mm) **No `Opacity`/`Transform`/`Color` inside `AnimatedBuilder.builder` driven by an AnimationController** — grep for `Opacity(opacity:` inside `AnimatedBuilder(...).builder` callbacks. Use `FadeTransition(opacity: anim, ...)` (or `SlideTransition`/`ScaleTransition`/`RotationTransition`) outside the builder instead — `Opacity` allocates a saveLayer per frame whereas the transition widgets short-circuit. Same rule for animated `Transform.translate`/`Transform.rotate` inside a builder. Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding A5.
> (nn) **No empty `setState(() {})` as a rebuild hack** — grep `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_*.dart` for `setState\(\(\) \{\}\)`. If the rebuild is needed because a `Provider` field changed, the provider's own `notifyListeners()` covers it — no setState required. If local widget state is changing, give the field an actual setter call inside the setState closure (e.g. `setState(() { _foo = bar; })`). An empty setState hides the dependency, causes spurious full-subtree rebuilds, and tends to multiply over time as code is copy-pasted between games. **Permitted exception:** rebuilding after assigning a local non-Provider field (e.g. `_mockApi = ...` in `_initializeGame`) — in that case the field assignment IS the state change and an empty closure is acceptable; cite this case in the AR-4 report. Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding C3.
> (oo) **Menu screen `initState` calls `await playerProvider.loadPlayers()` then `playerProvider.clearSelection()` inside its `addPostFrameCallback`** — read the menu screen's `initState()` and verify both calls are present, in that order, before any preselect logic (`selectPlayer(...)` / `getPlayerById(...)`). Without `clearSelection()`, `_selectedPlayers` on `PlayerProvider` is shared global state that LEAKS across games — entering the new game shows whatever players were selected on the previously-visited game's menu. Without `loadPlayers()`, players added on the home / options screen since the app booted won't appear in the new game's roster. Reference: `target_tag_menu_screen.dart:93-94`, `horse_race_menu_screen.dart:52-53`, `reef_royale_menu_screen.dart:89-90`, `clockwork_quest_menu_screen.dart:59-60`, `monster_mash_menu_screen.dart:82-83`, `lunar_lander_menu_screen.dart` (post-fix). Recurring miss: Lunar Lander shipped without these calls and exhibited the cross-game selection-leak bug until 2026-05-06.
>
> (pp) **Accumulated Build Quality Rules compliance** — review the "## Accumulated Build Quality Rules" section at the end of this skill. For each of the 27 rules, note whether it applies to this game and verify compliance:
> - Rule 1 (Character Randomization): applies if the game has more characters than players. Verify `_characterPaths` is shuffled in `initState`, not hardcoded by player index.
> - Rule 2 (Shape-following glow): applies if active-player characters have transparent PNG backgrounds. Verify `ImageFiltered`+`ColorFiltered` approach, NOT `BoxShadow` on Container.
> - Rule 3 (Per-player controls in player column): verify dart indicators and skip-turn button are in the player display column, not AppBar.
> - Rule 4 (Dart indicator hit tracking): applies if indicators show player color for hits vs neutral for misses. Verify `_currentTurnHits` tracked at throw time, cleared on turn change.
> - Rule 5 (All badge states): verify rankings/results badges show WIN, LOSS, and DRAW — no empty transparent loser state.
> - Rule 6 (Icon vs emoji): verify flag/bullet indicators use `Icon(...)` not emoji where player color matters.
> - Rule 7 (Text readability): verify significant text over background images uses 4-corner shadow outline.
> - Rule 8 (Settings + player persistence): verify `_changeSettings` passes all settings AND `initialSelectedPlayerIds` as constructor params; menu screen re-selects players in `addPostFrameCallback`.
> - Rule 9 (Randomized grid targets): applies to grid-based games. Verify targets shuffle from full 1–20 range with `Random?` parameter — no hardcoded layouts.
> - Rule 10 (Play-to-complete steal loop prevention): applies if game has steal/takeover mechanics. Verify non-winner always misses, winner only targets empty cells.
> - Rule 11 (Test keys for dynamic values): verify widget keys on runtime-determined values; ProviderHelpers expose them.
> - Rule 12 (`completeGameToVictory` dynamic reads): verify helper reads actual targets from provider — no hardcoded numbers; `throwForCellTarget` dispatch included.
> - Rule 13 (LayoutBuilder for game boards): verify game board elements use proportional sizing from `LayoutBuilder`, not fixed pixel sizes. Grid container margin is subtracted from available width before computing sibling column widths.
> - Rule 14 (Background texture opacity): verify texture images use ≥ 0.50 opacity; verify files actually exist at their paths.
> - Rule 15 (Inline `[DIAG]` reason strings): verify every navigation-dependent `findsOneWidget` in UI tests embeds an inline diagnostic in `reason:` — built from already-imported `ElementFinders` methods, not via a new shared helper. Apply to every nav-back, tap-then-expect, and modal-action assertion.
> - Rule 16 (`ensureVisible` before scrollable-content taps): verify `tester.ensureVisible(button); await tester.pump();` precedes every tap on a button inside a `SingleChildScrollView` — results-screen actions, save/resume modal buttons. `clickPlayAgain`/`clickChangeSettings`/`clickSelectDifferentGame` in `shared/results_helpers.dart` must include this from day one.
> - Rule 17 (Save/Resume real-flow): verify any test that taps Resume sets up the saved game via the in-game Save flow, NOT `preSaveGame(GameSaveConfig.foo())`. `preSaveGame` is only for tests that verify the resume modal appears in the saved-games list.
> - Rule 18 (Resume tile selection): verify every test that taps Resume calls `UITestHelpers.selectSavedGameTile(tester, savedId)` first — the Resume button is disabled until a tile is selected.
> - Rule 19 (`Navigator.push` not `pushReplacement`): verify `_startGame` in the menu screen uses `Navigator.push` so the menu stays on the route stack — back-from-game and Save-modal-Save both pop to menu.
> - Rule 20 (`_resetTurnForPlayer` undoes match-level): verify the provider's edit-score reset captures `winnerId == playerId`, `matchWinnerId == playerId`, and `isMatchDraw && !thisTurnWonMatch` BEFORE clearing round-level fields, then undoes `roundsWon` decrement, `matchWinnerId = null`, `isMatchDraw = false`, `state = GameState.playing`, `gameEndTime = null` for the affected paths.
> - Rule 21 (Edit dialog fills dropped darts): verify "edit removes winner" tests explicitly set ALL three darts in the dialog (typically `setDart1/2/3('Miss')`) — provider drops post-win Miss throws via the `!isGameActive` early return, so the initial segments only contain the winning dart.
> - Rule 22 (`_parseSegment` Miss representations): verify the helper accepts `'Miss'`, `'M'`, `'miss'`, `'-'`, `'—'`, and empty string as miss; lowercase `d`/`t` regex prefixes; `ensureVisible` on every ring/number tap.
> - Rule 23 (Strategy returns miss-shaped throw): verify `getNextThrow` returns `SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0)` for deliberate-miss turns, NOT `null`. Null is the runner's STOP signal.
> - Rule 24 (Inner LayoutBuilder for player column): verify `_buildPlayerColumn` wraps its body in a `LayoutBuilder` that clamps `charSize` against `columnConstraints.maxHeight`, with reserve `220 + (game.speedPlay ? 56 : 0)` for active and `80` for inactive.
> - Rule 25 (RGB-byte color comparison): verify visual-validation tests compare `color.red`/`green`/`blue` directly, NOT `color.value`.
> - Rule 26 (Shared helper sync): verify every shared-helper file in `integration_test/shared/` has an identical counterpart in `test/shared/`. Run `diff -q` on each pair.
> - Rule 27 (Runtime target lookup): if rule 9 applies (randomized targets), verify a `get[GameName]CellTargetNumber(tester, row, col)` helper exists in `provider_helpers.dart` and EVERY gameplay test that throws a specific dart uses it; verify a `throwForCellTarget(tester, target)` dispatch helper handles the `single`/`double`/`triple`/`bull` multiplier chooser.
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

**Goal:** Write all UI tests in the proper subdirectory layout (including mandatory navigation, results, and play-to-complete tests), synchronize the mirrored shared helpers, update all 4 batch files, run the spec coverage audit.

**Model:** Sonnet sub-agent for shared helper sync + UI test files + screenshot test + batch file updates; orchestrator (Opus) for the spec coverage audit + AR-6 + Gate 3.

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
>   await tester.pump(const Duration(seconds: 4));
>   await tester.pump();
>   await tester.pump();
>   expect(config.getPlayAgainButton(), findsOneWidget);
> });
> ```
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
> - **CRITICAL — ONE `testWidgets` block per file.** All screenshot captures go inside a single continuous `testWidgets`. Splitting into multiple `testWidgets` works under sequential `-d chrome` (in-process Chrome) but **silently fails under parallel `-d web-server`** with `AppConnectionException` / `SocketException` at `WebDriver.quit` because the `integration_test_driver_extended` request/response protocol expects one test per file — multiple `testWidgets` cause DWDS to disconnect between test transitions. Past failure: Tiki Golf shipped with 10 separate `testWidgets` blocks — passed sequentially, failed every parallel run with no useful diagnostic. The fix was structural consolidation (commit history).
>
> - **CRITICAL — Define ALL helpers AND helper BODIES inline in the screenshot test file.** Do NOT import a sibling `_helpers.dart`. Do NOT delegate to `shared/dart_throw_helpers.dart` or `shared/game_setup_helpers.dart` either — talk to `package:dart_games/services/mock_scolia_api_service.dart` directly and write out the `mockApi.simulateDartThrow(...)` / `mockApi.simulateTakeoutFinished()` calls inline. The per-test `SettingsHelpers` / `UITestHelpers` / `PumpSequences` / `ProviderHelpers` shared files ARE fine — only `dart_throw_helpers.dart`, `game_setup_helpers.dart`, and per-test-directory `_helpers.dart` are the hazard.
>
>   **Why:** the parallel `-d web-server` web-compile path has a cache hazard with helper imports specific to the screenshot driver (cf. commit `cea7027` / `4d1377e` about new `integration_test/shared/` files being silently ignored — same hazard, different scope). Works under sequential `-d chrome`; fails under parallel `-d web-server`. **Same symptom signature** as the multiple-testWidgets failure mode — log stops after "Debug service listening" with no "Starting application from main method", `flutter drive` crashes ~14s in, runner waits 600s for done patterns that never appear.
>
>   **Past failure (Tiki Golf, three iterations to find):** consolidating to one `testWidgets` didn't fix it; removing the `import '_helpers.dart' as h;` didn't fix it; the third fix — inlining helper *bodies* and removing the `shared/dart_throw_helpers.dart` + `shared/game_setup_helpers.dart` imports — finally worked. The pattern that always passes: copy `integration_test/pirates_grid/visual_validation/pirates_grid_screenshot_test.dart` structure line-for-line.
>
> - **CRITICAL — keep each screenshot test file UNDER 600s (10 min) total runtime.** The parallel UI worker (`run_ui_tests_parallel_worker.bat:253`) polls the per-test log for done patterns for up to 600 seconds, then kills Chrome. A still-running test at 600s → framework never emits "All tests passed" → log shows only "Debug service listening" → `SocketException` at `WebDriver.quit`. **Same log signature as the multi-testWidgets / helper-import failures above**, so before going down a structural-bug rabbit hole, **check `DURATION=` in `integration_test_output/parallel/<game>_results.txt` first** — if it's near 600s the cause is total runtime, not test structure.
>
>   **Fix when over budget:** split the screenshot test across multiple files. Both filenames must contain `"screenshot"` so the worker auto-routes both through `test_driver/screenshot_test.dart` (each `flutter drive` invocation gets its own 600s budget). Suggested cut: `<game>_screenshot_test.dart` for menu + early gameplay scenarios, `<game>_screenshot_results_test.dart` for endgame + results-screen scenarios (the slowest captures, typically including full game completions). Apply the same inline-helper rules to every file.
>
>   **Past failure (Tiki Golf timeout):** the full screenshot test ran 698 lines / 28 captures including 2 full 9-hole rapid-completion loops. Total runtime ~12 minutes — failed silently every parallel run. **Three earlier "fix" rounds (consolidate testWidgets, remove `_helpers.dart`, inline helper bodies) all looked plausible because the symptom is identical — only the duration tells you it's the timeout.** Final fix: split into `tiki_golf_screenshot_test.dart` (PARTS 1-5) + `tiki_golf_screenshot_results_test.dart` (PARTS 6-10), each well under 600s.
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

## Phase 8: Visual Validation

**Goal:** Execute the FULL iterative validation cycle from `docs/critical-rules/visual-validation.md`. This phase contains the complete visual + UI + non-UI verification loop.

**Model split:**
- **Sonnet sub-agent:** Step 1 (chromedriver version sync + chromedriver lifecycle + backend server startup + screenshot test execution), Step 4 fixes, Step 5 (run UI tests), Step 7 (run flutter test + server test).
- **Orchestrator (Opus):** Step 2 (read every screenshot + evaluate against checklist), Step 3 (report findings), Step 4 decision, Step 6 decision, Step 8 decision, AR-7. **Visual evaluation is the highest-value Opus work in this skill — never delegate it.**

**CRITICAL UNDERSTANDING:** "Screenshot test passed" does NOT mean "visual validation complete." A passing test only means screenshots were captured without runtime errors. The actual validation is reading and evaluating every screenshot against the checklist. These are two completely separate steps — NEVER conflate them.

### Phase 8 pre-flight verification (orchestrator runs BEFORE Step 1)

Before invoking any Sonnet sub-agent for Step 1, verify the runner scripts have the false-positive guards and stale-cache wipes:

1. **Pass-detection includes `Failure Details:` as a fail marker.** Both `run_ui_tests.bat` and `run_ui_tests_parallel_worker.bat` should have:
   ```powershell
   $found = ($c -match 'All tests passed') `
        -and (-not ($c -match 'Some tests failed')) `
        -and (-not ($c -match 'Failure Details:'));
   ```
   Why: in `-d chrome` mode, the integration_test framework can emit BOTH `+2: All tests passed!` AND a trailing `Failure Details:` block when an assertion in the test body throws. Without this guard, the script reports PASSED on a broken test (false positive). Verified failure: pirates_grid 2026-05-07 — sub-test was failing the `Should be on menu after NEW VOYAGE` assertion in both modes; sequential reported PASS; parallel reported FAIL.
2. **flutter_tools temp kernel cache wipe in pre-flight.** Both runners should delete `%LOCALAPPDATA%\Temp\flutter_tools.*` before any flutter command:
   ```bat
   for /d %%D in ("%LOCALAPPDATA%\Temp\flutter_tools.*") do rmdir /S /Q "%%D" >nul 2>&1
   ```
   Why: `flutter_tools` keeps an `app.dill` kernel snapshot that survives `flutter clean`. When a method is added to a file already in the cached kernel, the next `flutter drive` reuses the stale kernel and reports "Member not found" — wasting hours on what looks like a code bug.

If either guard is missing, fix the runner scripts BEFORE running Phase 8 — otherwise visual-validation feedback is unreliable.

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

**Hung-process safety:** Past sessions have seen the screenshot test deadlock for 25+ minutes when the game UI has a build error or missing widget. The orchestrator imposes a **25-second progress timeout** on the screenshot test process — if no new screenshot file appears in `temp_screenshots/` for 25 seconds AND the flutter_drive process hasn't exited, the orchestrator instructs the sub-agent to KILL chromedriver + chrome + flutter_drive, read the partial log, and assess what's wrong before retrying. The 25s threshold matches the actual per-screenshot capture time observed in healthy runs (5–15s typical, with margin for the initial app boot of the first capture). Past failure: Pirate's Grid screenshot test halted at #12 of 15 (the speed-play timer transition) and we waited 4 minutes before killing it — wasted iteration time. Tighter timeout = faster failure detection = faster fix loop.

**Known problem area — timer-based UI states:** Screenshot tests that capture a state involving a continuously-running `Timer` (e.g., a Speed Play countdown, an animation that loops indefinitely) deadlock if the test pumps `pump(Duration)` on a continuously-firing timer — the timer keeps emitting events and `pumpAndSettle` never completes, freezing capture. The screenshot test for any timer-driven UI state MUST: (a) freeze the timer before capturing — set the screen state to a fixed timer value via `provider.<setTimerForTest>(...)` if a hook exists, OR (b) capture immediately on the same frame the timer was started (no `pump(Duration)`), OR (c) skip that visual state and document it in the spec coverage report as a known gap. Reference: PG `game_speed_play_timer` capture at index #12; the screen had an active `Timer.periodic` and `pumpAndSettle` never settled.

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

**CRITICAL — driver choice during build vs production:**

During build (Phase 7 + Phase 8, while failure-screenshot wraps from Rule §38 are still in place), tests MUST be invoked via `flutter drive --driver=test_driver/screenshot_test.dart` per test file in foreground. This is the SAME invocation pattern the visual-validation screenshot test uses in Phase 8 STEP 1. Reasons:

- The wraps' `runWithFailureScreenshot` calls write PNG bytes to `temp_screenshots/failures/` ONLY when the `screenshot_test.dart` driver's `onScreenshot` callback is registered. The standard `test_driver/integration_test.dart` driver has no `onScreenshot`, so the wraps silently no-op (no failure pixels written) under the production runner.
- The parallel runner (`run_ui_tests_parallel.bat`) uses the production driver and additionally relies on Windows `start "Worker"` + `git worktree add` to spawn parallel workers. Those Windows-specific commands silently no-op in the orchestrator's MSYS2/Bash sandbox, so the runner returns exit 0 without actually running anything. The orchestrator therefore CANNOT use the parallel runner during the build cycle — it must invoke `flutter drive` directly per test file.

The parallel runner is intended for the post-build pack (Phase 9 onward, after the wraps are removed). Until then: foreground `flutter drive` per file is the only way to actually exercise the tests AND get failure pixels.

**Foreground invocation pattern (canonical):**

```bash
# Reset state ONCE per category before invoking
taskkill /F /IM chromedriver.exe 2>&1 || true
taskkill /F /FI "WINDOWTITLE eq Dart Games*" 2>&1 || true
for /d %D in ("%LOCALAPPDATA%\Temp\flutter_tools.*") do rmdir /S /Q "%D" 2>&1
rm -rf temp_screenshots/failures/*

# Start backend server in background (port 9008 for gladiator_arena per
# docs/testing/ui-automation.md port table)
cd server && dart run bin/server.dart --port 9008 --data-dir ../ui_test_data &

# Start chromedriver in background (port 4444 — flutter drive default)
chromedriver/chromedriver-win64/chromedriver.exe --port=4444 &

# Run each test file individually (sub-agent loops through every *.dart in
# integration_test/[GAME_NAME_SNAKE]/<subdir>/ except _helpers.dart)
flutter drive \
  --driver=test_driver/screenshot_test.dart \
  --target=integration_test/[GAME_NAME_SNAKE]/<subdir>/<test_file>.dart \
  -d chrome \
  --dart-define=SERVER_PORT=9008 \
  --web-browser-flag=--start-maximized \
  --browser-dimension=1920x1080 \
  --web-browser-flag=--no-restore-last-session
```

**Sub-agent prompt template:**

> Run the UI automation tests for the **[GAME_NAME_DISPLAY]** game and report results. Use the FOREGROUND `flutter drive` per-file invocation pattern (NOT the parallel runner — see skill Phase 8 STEP 5 driver-choice note for why).
>
> **Pre-flight:**
> 1. `taskkill /F /IM chromedriver.exe 2>&1 || true`
> 2. `taskkill /F /FI "WINDOWTITLE eq Dart Games*" 2>&1 || true`
> 3. Wipe `%LOCALAPPDATA%\Temp\flutter_tools.*`
> 4. Clear `temp_screenshots/failures/`
> 5. Start backend server background: `cd server && dart run bin/server.dart --port 9008 --data-dir ../ui_test_data`
> 6. Start chromedriver background on port 4444
>
> **Test loop:**
> For each subdirectory in `integration_test/[GAME_NAME_SNAKE]/` (in skill-mandated order: visual_validation, menu_and_settings, add_player, navigation, gameplay, pause_modal, results_screen, save_resume, edit_score, play_to_complete), for each `*_test.dart` file (skip `_helpers.dart`):
>
> ```
> flutter drive \
>   --driver=test_driver/screenshot_test.dart \
>   --target=integration_test/[GAME_NAME_SNAKE]/<subdir>/<test>.dart \
>   -d chrome --dart-define=SERVER_PORT=9008 \
>   --web-browser-flag=--start-maximized --browser-dimension=1920x1080 \
>   --web-browser-flag=--no-restore-last-session
> ```
>
> Capture exit code + look for "All tests passed!" / "Some tests failed:" / "Failure Details:" in output.
>
> **For each failing test:**
> - Note the test file path
> - Read the failure stack trace from flutter drive output
> - List any failure screenshots in `temp_screenshots/failures/` (path + size)
>
> **Hung-process safety:** if a single `flutter drive` invocation runs longer than 5 minutes, KILL it (taskkill chromedriver + close test windows) and mark the test FAILED with a "TIMEOUT" reason.
>
> **Tear down:** kill chromedriver, kill backend server.
>
> **Report back:**
> - Total tests attempted
> - Pass/fail count broken down by subdirectory
> - For each failure: test path + error message excerpt + failure screenshot path (if captured)
> - Total runtime
>
> **Hard rules:**
> - Do NOT attempt to fix failing tests — only report them. Orchestrator triages root causes.
> - Do NOT use the parallel runner.
> - Do NOT skip individual tests. Every test must be attempted.
> - Do NOT kill chrome.exe globally — only chromedriver.exe and test windows by title.

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

### Failure-screenshot wrap removal (mandatory once Gate 4 passes)

The `UITestHelpers.runWithFailureScreenshot` wraps in every UI test in the new game's pack were build-phase aids — they let the orchestrator inspect failure pixels during Phase 7 iteration. Now that Gate 4 has passed, the wraps are no longer needed: tests are stable, the runner uses `test_driver/integration_test.dart` (no `onScreenshot`), and the wrap would be inert there anyway. Removing the wraps also matches the form every other game's tests use, eliminating per-test boilerplate.

**Trigger:** Gate 4 = PASS in this phase. (If Gate 4 has not yet passed, the wraps stay — they may be needed for the next iteration.)

**Delegate to Sonnet sub-agent:**

> You are completing the failure-screenshot wrap removal for the **[GAME_NAME_DISPLAY]** game.
>
> **Read first:**
> - One existing test file in `integration_test/[GAME_NAME_SNAKE]/<any subdir>/<any>_test.dart` to confirm the current wrap pattern.
>
> **Tasks:**
> 1. For every `*_test.dart` file under `integration_test/[GAME_NAME_SNAKE]/` (excluding `_helpers.dart` files), unwrap the `UITestHelpers.runWithFailureScreenshot(tester, '<name>', () async { <body> })` call:
>    - Remove the `await UITestHelpers.runWithFailureScreenshot(tester, '<name>', () async {` line
>    - Remove the matching closing `});` two lines from the end of the testWidgets body (or wherever the closure ends)
>    - Adjust indentation of the body so it sits at the original test level (typically 4 spaces less)
> 2. Save each file. Verify with `flutter analyze integration_test/[GAME_NAME_SNAKE]/`.
> 3. Run the parallel runner for the new game ONLY: `./run_ui_tests_parallel.bat [GAME_NAME_SNAKE]`. All tests must still pass — the unwrap is a pure mechanical change with no behavioral effect.
>
> **Hard rules:**
> - DO NOT modify any test logic. Only remove the wrap.
> - DO NOT remove the wrap from the smoke test at `integration_test/_smoke/failure_screenshot_smoke_test.dart` — it stays as a self-test artifact for the helper itself.
> - DO NOT modify `integration_test/shared/ui_test_helpers.dart` — the helper STAYS in shared so future game builds can use it again.
> - DO NOT commit. DO NOT push.
>
> **Report back:**
> - Count of files modified
> - `flutter analyze` result for the new game's integration_test tree
> - Parallel runner result (X/Y passing)
> - `git diff --stat` summary

After the sub-agent returns:
- Read 2-3 of the modified test files yourself to spot-check the unwrap
- Confirm the parallel runner result matches Gate 4's UI test count
- If the runner now reports failures the wraps were masking (unlikely but possible), STOP and analyze on the orchestrator

The helper itself (`UITestHelpers.runWithFailureScreenshot`) STAYS in `integration_test/shared/ui_test_helpers.dart` indefinitely. Future game builds will use it again during their own Phase 7. Only the per-test wraps are removed at this transition.

---

## Phase 10: Cross-Game Test-Coverage Audit

**Goal:** After all initial tests pass (Gate 4), audit the new game's test coverage against a strong-coverage peer game. Identify scenario gaps — particularly option × player-count combinations, miss paths, knockoff / bust / win edge cases, save/restore round-trips, edit-score replay scenarios, menu-level guards, and announcement precedence — that the peer covers but the new game doesn't. Get user approval, then close the gaps with new tests (and, if the audit surfaces dead code or unwired helpers in the announcement layer or elsewhere, wire or delete them per user decision).

**Model:** Orchestrator (Opus) for the audit, gap synthesis, and remediation plan; Sonnet sub-agent for implementing the new tests once the user approves.

**Why this phase exists:** Spec coverage (Phase 7) verifies every option in the spec has at least one test. AR-9 (Phase 11) verifies the new game LOOKS like the others in code shape and visuals. Neither catches *combinatorial* test gaps — "the peer game has 5 tests around DF bust edges; this game has 2" — and neither catches scenarios that the spec doesn't enumerate but emerge from the implementation (e.g., bust on dart 2 vs dart 3 freeze, multi-victim knockoff undo through edit-score, milestone announcement re-fire after knockoff). Real bugs hide there.

### Step 1: Pick the peer game

Pick the most-recently-built game that's *also* in the strong-coverage tier (Pirate's Grid, Clockwork Quest, or Gladiator Arena are reliable choices as of this writing). If the new game IS one of those, pick the previous strong-coverage game. Cite the peer in the orchestrator report.

Avoid picking a game whose mechanics diverge wildly from the new game — e.g., don't compare Pirate's Grid (2-player grid game) against an N-player race-to-target game. The audit will produce false positives in the gap list.

### Step 2: Build a feature inventory from CODE (not docs)

**This step runs entirely on the orchestrator. Do not delegate.** The spec and project docs are NOT the source of truth here — they describe intent, not the as-built behavior. Read:

- `lib/providers/[GAME_NAME_SNAKE]_provider.dart` — every public method, every branch, every guard
- `lib/models/[GAME_NAME_SNAKE]_game.dart` — every field, computed property (e.g., `isShieldRound`), serialization
- `lib/screens/games/[GAME_NAME_SNAKE]/*.dart` — every dart-event branch, every announcement call, every state-tracking field (e.g., milestone-transition flags)
- `lib/services/[GAME_NAME_SNAKE]_announcement_helper.dart` — every method (including methods that are DEFINED but never CALLED — those are dead code candidates), the precedence chain in `pickAndAnnounceMoment`
- `lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart` — winner selection logic, per-dart payload

Produce a written feature inventory. Group by: options, edge cases per option, per-dart outcomes, turn-end transitions (commit / bust / knockoff / win / skip / timer-expiry), announcement triggers (lifecycle + per-dart + milestone), save/restore fields, and per-player-count behavior (clamp ceilings, layout breakpoints).

### Step 3: Inventory existing test coverage

For each test file under:
- `test/models/[GAME_NAME_SNAKE]_*` and `test/providers/[GAME_NAME_SNAKE]_*`
- `test/screens/games/[GAME_NAME_SNAKE]/*`
- `integration_test/[GAME_NAME_SNAKE]/*` (every subdirectory)

…list every test (group + name is enough). For each item in the Step 2 feature inventory, mark whether at least one test exercises it. Mark not just by code-path-touch but by *meaningful assertion* — a test that throws a dart through the code but doesn't assert anything specific to the option/branch under audit doesn't count.

### Step 4: Inventory the peer's coverage

Same exercise on the peer game's test tree. Specifically capture:
- Provider/model game-logic test groups (number of tests per group)
- Save/restore tests (count, what fields/scenarios)
- Announcement tests (lifecycle, precedence, stacking limits, milestone tests)
- UI test subfolders (`gameplay/`, `menu_and_settings/`, `edit_score/`, `save_resume/`, `play_to_complete/`, `results_screen/`, `visual_validation/`, `pause_modal/`, `navigation/`)
- Per-player-count UI coverage (which counts have dedicated tests)
- Menu-level guard tests (`start_disabled_*`)
- Any game-specific test kinds (mark as N/A for the new game if the mechanic doesn't apply)

### Step 5: Diff and produce the gap list

Cross-reference the two inventories. For each kind of test the peer has, ask:
1. Does the new game have an equivalent test? (file-level)
2. Is the coverage *breadth* comparable? (e.g., does the new game's "knockoff edges" cover the same edge cases as the peer's?)

Pay particular attention to:

- **Option × player-count matrix:** for each option combination (e.g., DF on/off × ShieldRound on/off × SpeedPlay on/off) × {2, 3, …, 8} players, are there meaningful combinations the new game doesn't exercise that the peer does? Don't fabricate combinations the spec doesn't justify — flag only the ones where the peer has explicit coverage.
- **Miss / "no score" paths:** every miss outcome (single miss, all-3 miss, partial-turn miss after a near-bust setup) under each option combo. Check that the relevant audio announcement triggers and the stat side-effects (totalDartsThrown / totalTurns) are asserted.
- **Knockoff edge cases:** at exact target, during shield round, with partial-turn darts, with DF bust short-circuit, simultaneous-tie (multi-victim), self-knockoff (if possible by the rules).
- **Speed-Play timer boundaries** (if the game has a timer): expiry mid-turn vs between darts vs after dart 3, interaction with pause/takeout, interaction with knockoff/bust/edit-score.
- **Double-Finish (or equivalent finish-rule) boundaries:** prospective bust on dart 1 vs 2 vs 3, exact-target without finisher, exact-target with finisher, overshoot revert, interaction with knockoff and shield rules.
- **Save/restore round-trips:** every option + mid-state combination. Mid-turn save/resume with each option active. Specifically check fields the peer tests but the new game doesn't (e.g., a `*TimeRemaining` field that round-trips).
- **Edit-score replay:** every win/bust/knockoff side-effect undo. Multi-victim knockoff undo specifically (single-victim alone is insufficient).
- **Announcement precedence:** is the full precedence ladder exercised? Are stacking limits asserted? Does any milestone announcement (e.g., entering near-victory zone) fire on state transition and NOT re-fire while in zone?
- **Menu-level guards:** `start_disabled_*` tests for 0 / 1 player. Per-option toggle on AND off tests (not just "on" or "off" separately).

For each gap, record:
- Gap ID (numbered)
- What's missing (one sentence)
- Why it matters (one sentence — what bug class it would catch)
- Suggested test file path(s) + test name(s)
- Phase 1 (non-UI) or Phase 3 (UI)?

### Step 6: Identify dead code surfaced by the audit

While building the Step 2 inventory, if any method in the announcement helper (or other game-specific service) is DEFINED but NEVER CALLED from any screen or service, flag it. Examples to watch for: `announceDoubleRange`, `announceNearVictory`, `announceComboBreaker`, etc. — methods that look like complete wiring but were left orphaned during the original build.

For each piece of dead code:
- Cite the file:line where it's defined
- Grep the repo for callers — confirm zero callers outside tests/mocks
- Propose: wire it up (with state-transition gating to avoid re-firing) **OR** delete it

This is a user decision per item — surface it in the Step 7 report, do not unilaterally delete or wire.

### Step 7: Produce the audit report (orchestrator → user)

Structure:

```
## 1. Feature inventory (from code, not spec)
[bullet list grouped by option / system / state-transition]

## 2. Existing [GAME_NAME_DISPLAY] coverage
[citing test files + group counts]

## 3. Peer comparison: [PEER_GAME_NAME]
[short summary of peer coverage + what peer covers that new game doesn't]

## 4. Concrete gap list
[numbered: ID, what's missing, why it matters, suggested file + test name, phase]

## 5. Dead code surfaced
[if any: file:line, current state, proposed action]

## 6. Recommended remediation plan
[two phases: Phase 1 (non-UI) + Phase 3 (UI), estimated counts]
```

Cap report at ~1500 words. Cite `file_path:line_number` everywhere it helps.

### USER APPROVAL GATE

> "I've finished the cross-game coverage audit. [N1] Phase 1 (non-UI) gaps and [N2] Phase 3 (UI) gaps identified. [N3] dead-code items flagged.
>
> Full report above. Should I proceed to remediate? You can:
> - Approve Phase 1 + Phase 3 wholesale
> - Approve Phase 1 only (defer UI tests to later)
> - Reject any specific gap as 'won't fix' (cite gap ID + reason)
> - Decide each dead-code item: wire / delete / leave"

**Do NOT proceed past this gate without explicit user approval.** The user may say "approve all gaps but defer dead-code decision" — in that case, run remediation for the gaps only.

### Step 8: Remediation (after approval)

For each approved gap, delegate test authoring to a Sonnet sub-agent. Group gaps by file when possible so the sub-agent edits each file once:

**Sub-agent prompt template (non-UI gaps):**

> You are closing test-coverage gaps surfaced by the cross-game audit for **[GAME_NAME_DISPLAY]**.
>
> **Read first:**
> - The audit report (above)
> - `test/providers/[GAME_NAME_SNAKE]_provider_game_test.dart` (or the relevant existing test file) — to learn the exact helper functions (`_makeProvider`, `_forcePlayer`, `_dart`, `_miss`, etc.) and the existing test-naming convention
> - The provider/model code paths cited in the gap descriptions
>
> **Tasks:**
> 1. For each gap in the list below, add ONE test that exercises the specific behavior:
>    [LIST OF GAPS WITH IDs, NAMES, EXPECTED ASSERTIONS]
> 2. Tests must follow the existing file's helper conventions — don't introduce new helpers unless absolutely necessary.
> 3. Tests must assert SPECIFIC behavior (not just "no crash") — every assertion has a `reason:` argument citing the gap.
> 4. Run `flutter test [FILE_PATH]` after writing each batch — all tests must pass before moving on.
> 5. Report `git diff --stat` summary and the new total test count for the file.
>
> **Hard rules:**
> - DO NOT touch test files for other games.
> - DO NOT modify shared helpers unless every existing usage still works.
> - DO NOT commit. DO NOT push.

**Sub-agent prompt template (UI gaps):** see Phase 7 patterns. Same principles: one testWidgets per file (parallel runner constraint), `_helpers.dart` delegates, shared helpers in `integration_test/shared/`, every key in `lib/constants/test_keys.dart`.

### Step 9: Re-run Gate 4 after remediation

Once all approved gaps are closed:
- Run `flutter test` — all non-UI tests must still pass (including the newly added)
- Run `cd server && dart test` — server tests still pass
- Run the parallel UI runner for ONLY the new game: `./run_ui_tests_parallel.bat [GAME_NAME_SNAKE]` — all UI tests pass (including newly added)

If anything regressed:
- The orchestrator analyzes (do not delegate root-cause analysis)
- Dispatch a corrective Sonnet sub-agent with the specific failure
- Re-run Gate 4 until clean

### GATE 4-bis: Coverage-Closed Simultaneous Pass

Same shape as the original Gate 4 (Phase 9), now including the new tests:

```
Gate 4-bis: Simultaneous Pass after Coverage Audit
  Spec coverage audit:    [PASS/FAIL]
  Visual validation:      [PASS/FAIL]
  UI automation tests:    [PASS/FAIL] — X/Y passing  (was X'/Y')
  Flutter non-UI tests:   [PASS/FAIL] — X/Y passing  (was X'/Y')
  Server tests:           [PASS/FAIL]
  New tests added:        Phase 1 [N1], Phase 3 [N2]
  Dead-code resolved:     [N3 wired / N4 deleted / N5 left as-is per user]
  OVERALL:                [PASS/FAIL]
```

After Gate 4-bis passes, proceed to Phase 11 (Documentation and Definition of Done). The Phase 11 doc updates MUST reflect the new test counts (don't paste in the pre-audit numbers — pull from the actual test run output).

### Adversarial Review AR-Coverage: Audit Self-Check

Before declaring the audit complete, the orchestrator performs one more pass:

> "I now re-read the audit report I produced in Step 7 against the file changes I made in Step 8.
>
> For each gap I claimed to close: did I actually write a test that asserts the specific behavior cited? Or did I write a vague smoke test that 'touches the code path' without asserting the gap?
>
> For each dead-code item: did the user's decision get applied byte-for-byte, in both `.claude/skills/...` and `skills/...` if applicable?
>
> For each new test: does it follow the existing file's naming convention and helper usage, or did the sub-agent invent something inconsistent?
>
> AR-Coverage result: [PASS / FAIL]
> If FAIL: dispatch corrective sub-agent and re-run."

---

## Phase 11: Documentation and Definition of Done

**Goal:** Create all game documentation, update project files, verify Definition of Done.

**Model:** Sonnet sub-agent for documentation file authoring + CLAUDE.md / testing docs updates; orchestrator (Opus) for AR-8 + Gate 5.

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

---

## Accumulated Build Quality Rules

These rules were learned from post-build refinement sessions on shipped games. Each one was absent from an initial build and required manual correction after delivery. All applicable rules are enforced in AR-4 item (pp).

---

### 1. Character Randomization (games with multiple interchangeable characters)
If a game has more characters than players and assigns one per player, shuffle all characters at game-screen `initState` time rather than hardcoding by player index. Pattern (identical to Reef Royale):
```dart
late List<String> _characterPaths;

@override
void initState() {
  super.initState();
  final allChars = [
    'assets/games/[GAME_NAME_SNAKE]/characters/Char1.png',
    // ... every character ...
  ]..shuffle();
  _characterPaths = allChars.take(playerCount).toList();
  // ...
}
```
Use `_characterPaths[playerIndex]` everywhere character images are needed (game screen, results screen). The results screen does not share screen state with the game screen, so if the results screen hard-codes character paths it will show different characters than the game screen used.

---

### 2. Shape-Following Character Glow
`BoxShadow` on a Container creates a **rectangular** glow that includes the transparent areas of the PNG. For character images with transparency, use `ImageFiltered` + `ColorFiltered(BlendMode.srcIn)` positioned just outside the character bounds:
```dart
import 'dart:ui' as ui;

SizedBox(
  width: charSize, height: charSize,
  child: Stack(
    clipBehavior: Clip.none,
    fit: StackFit.expand,
    children: [
      if (isActive)
        Positioned(
          left: -(charSize * 0.10), right: -(charSize * 0.10),
          top:  -(charSize * 0.10), bottom: -(charSize * 0.10),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: charSize * 0.07, sigmaY: charSize * 0.07),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(glowColor.withOpacity(0.85), BlendMode.srcIn),
              child: Image.asset(characterPath, fit: BoxFit.contain),
            ),
          ),
        ),
      Image.asset(characterPath, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.person, color: glowColor, size: charSize * 0.7)),
    ],
  ),
)
```
`BlendMode.srcIn` colors only the non-transparent pixels of the image; the blur then spreads that colored silhouette outward.

---

### 3. Per-Player Controls Belong in the Player Column, Not the AppBar
Dart indicators (D1/D2/D3) and the Skip Turn button are per-player controls — they belong in the active player's display column, not in the AppBar. AppBar actions should contain only global controls (DartboardConnectionInfo, ResumeGameButton).

---

### 4. Dart Indicator Color Logic — Track Hit Status at Throw Time
Segment strings alone cannot distinguish "dart hit a game target" from "dart hit a valid dartboard number not in the target set." Track `wasMatched` at throw time in screen state:
```dart
List<bool> _currentTurnHits = [];
String? _lastTurnPlayerId;

// In _handleDartThrow, BEFORE processDartThrow:
if (_lastTurnPlayerId != playerId) {
  _currentTurnHits = [];
  _lastTurnPlayerId = playerId;
}
_currentTurnHits = [..._currentTurnHits, wasMatched];

// Clear in _handleTakeoutFinished() and in the skip-turn callback.
```
Pass `dartHits: _currentTurnHits` to the active player's column; use `dartHits[i]` to decide player-color vs neutral-color per slot.

---

### 5. All Results Badge States Must Be Implemented
Never leave the loser badge as an empty transparent container. Implement WIN, LOSS, and DRAW explicitly:
```dart
isMatchDraw ? 'DRAW' : isWinner ? 'WIN' : 'LOSS'
```
Use a muted fill (e.g., `bloodRed.withOpacity(0.25)`) for LOSS — visible but not harsh.

---

### 6. Use Icon Widgets, Not Emoji, for Player-Colored Indicators
Emoji (🚩, ⚓, ⚙, etc.) render in fixed platform colors that `TextStyle.color` cannot override. Use `Icon(Icons.flag, color: playerColor)` anywhere the indicator color is semantically meaningful (e.g., different flag colors per player). Icon shadows work identically to Text shadows:
```dart
Icon(
  Icons.flag,
  color: playerFlagColor,
  size: 22,
  shadows: const [
    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
  ],
),
```

---

### 7. Text Readability on Busy Backgrounds — 4-Corner Shadow Outline
A single drop shadow only helps from one direction. For text over background images, use a 4-corner outline (zero blur radius) so the text is readable regardless of which part of the image is behind it:
```dart
shadows: const [
  Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
  Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
  Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
  Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
]
```
Apply to: AppBar titles, player names, stat labels, and any other colored text over a background image. Also works on `Icon.shadows` (same syntax).

---

### 8. Settings + Selected Player Persistence on "Change Settings" Navigation
The "Change Settings" navigation MUST pass the previous game's settings AND selected player IDs as constructor parameters to the menu screen. Do NOT rely on `provider.currentGame` surviving the navigation — it may be null by the time the new screen mounts.

**Menu screen constructor** — add optional parameters for every setting and for selected player IDs:
```dart
class [Game]MenuScreen extends StatefulWidget {
  final TargetDifficulty? initialDifficulty;
  final int? initialBestOf; // etc. for each spec option
  final List<String>? initialSelectedPlayerIds;
  const [Game]MenuScreen({super.key, this.initialDifficulty, ..., this.initialSelectedPlayerIds});
}
```

**Menu `initState`** — prefer widget params, then `provider.currentGame`, then defaults:
```dart
_difficulty = widget.initialDifficulty ?? lastGame?.targetDifficulty ?? TargetDifficulty.easy;
```
After `clearSelection()` in `addPostFrameCallback`, re-select previous players:
```dart
if (widget.initialSelectedPlayerIds != null) {
  for (final id in widget.initialSelectedPlayerIds!) {
    final player = playerProvider.allPlayers.where((p) => p.id == id).firstOrNull;
    if (player != null) playerProvider.selectPlayer(player, maxPlayers: N);
  }
}
```

**Results screen `_changeSettings`** — read from provider before navigating:
```dart
void _changeSettings() {
  final game = context.read<[Game]Provider>().currentGame;
  Navigator.pushAndRemoveUntil(context,
    MaterialPageRoute(builder: (_) => [Game]MenuScreen(
      initialDifficulty: game?.targetDifficulty,
      // ...other settings...
      initialSelectedPlayerIds: game?.playerIds,
    )),
    (route) => route.isFirst,
  );
}
```

---

### 9. Randomize Grid Targets (Grid-Based Games)
For games with targeting grids, target numbers MUST be randomized from the full eligible range each game — never hardcoded. The generator MUST accept `Random? random` for testability:
```dart
import 'dart:math';

static List<List<CellTarget>> generate(TargetDifficulty difficulty, {Random? random}) {
  final rng = random ?? Random();
  final pool = List.generate(20, (i) => i + 1)..shuffle(rng);
  final nums = pool.take(9).toList(); // 9 for Easy/Medium; 8 + bull-center for Hard
  // ...
}
```
Hardcoded layouts (e.g., `[20,18,16 / 19,17,15 / 14,12,10]`) mean every game is identical and players memorize the grid after one session.

---

### 10. Play-to-Complete: Steal / Takeover Infinite Loop Prevention
When a game has steal or takeover mechanics (player A can take player B's claimed cell/territory), the play-to-complete strategy MUST:
1. Designate a fixed winner upfront — always `game.playerIds[0]`
2. Have all non-winners return `null` from `getNextThrow` (deliberate miss every dart)
3. Have the winner target only EMPTY cells — never steal from opponents

Both (2) and (3) are required. Without them, P1 steals P2's cell → P2 steals it back on the next turn → infinite loop. The strategy comment must document this explicitly.

---

### 11. Test Keys for Runtime-Dynamic Values
When a UI element displays a value determined at runtime (e.g., a randomized target number, a computed score), add a widget key to that element so tests can query it without going through the provider:
```dart
Text(
  targetLabel,
  key: [Game]GameKeys.gridCellTargetLabel(row, col),
  // ...
)
```
Expose the value in `ProviderHelpers` as well:
```dart
static int get[Game]CellTargetNumber(WidgetTester tester, int row, int col) =>
    get[Game]Provider(tester).currentGame!.grid[row][col].target.number;
```

---

### 12. `completeGameToVictory` Must Read Actual Target Values
The `completeGameToVictory` helper MUST read actual target values from the provider at runtime — never hardcode numbers that assume a fixed grid layout. Include a `throwForCellTarget` dispatch helper:
```dart
import 'package:dart_games/models/[GAME_NAME_SNAKE]_game.dart';

Future<void> throwForCellTarget(WidgetTester tester, CellTarget target) async {
  switch (target.requirement) {
    case CellRequirement.bull:
      await DartThrowHelpers.throwBullseyeViaMock(tester);
    case CellRequirement.tripleOnly:
      await DartThrowHelpers.throwDartViaMock(tester, target.number, multiplier: 'triple');
    case CellRequirement.doubleOnly:
    case CellRequirement.doubleOrTriple:
      await DartThrowHelpers.throwDartViaMock(tester, target.number, multiplier: 'double');
    case CellRequirement.any:
      await DartThrowHelpers.throwDartViaMock(tester, target.number);
  }
}
```
P2 always misses in `completeGameToVictory` — this is safe even with steal mode ON (see Rule 10).

---

### 13. Responsive Layout — Use LayoutBuilder for Game Boards
Fixed-size game board elements (character images, grid cells, board tracks) that sit beside other fixed-size elements in a Row will overflow on different screen sizes. Use `LayoutBuilder` to compute proportional sizes from available width:
```dart
LayoutBuilder(builder: (context, constraints) {
  final availW = constraints.maxWidth;
  final gridW = availW * 0.40; // grid takes 40% of width
  final cellSize = (gridW - 18.0) / 3.0; // 3×3 grid, 3px margin each side
  final charColW = (availW - gridW) / 2.0;
  // ...
})
```
Note: any margin/padding on the grid container must be subtracted from `availW` before computing character column widths — failing to do so causes a pixel overflow equal to the total horizontal margin.

---

### 14. Background Texture Image Opacity
Background texture images (`opacity: AlwaysStoppedAnimation(0.3)`) at 30% are often invisible against a dark overlay. Use 0.50–0.65 for textures meant to add visual interest, or higher if the image is a primary visual element. The `errorBuilder: (_, __, ___) => const SizedBox.shrink()` pattern silently hides missing images — verify the file actually exists at the specified path.

---

### 15. Tests must include inline `[DIAG]` reason strings on navigation/findsOneWidget assertions
Headless `-d web-server` mode does NOT pipe app stdout into `flutter drive`'s log. When a `findsOneWidget` fails, the failure block in the per-test log is *all we get* — no `print()`s, no progress markers, no audio queue trace. Without diagnostic info embedded in the failure itself, every iteration costs a full re-run.

Any assertion that depends on navigation having completed (post-tap, post-pop, after `pushReplacement` / `pushAndRemoveUntil`) MUST include an inline diagnostic in its `reason:` string built from already-imported `ElementFinders` methods.

**Inline at the call site — never via a new shared helper.** New shared methods have repeatedly hit "Member not found" in headless compile and block the test from running at all. Use the test's existing imports.

```dart
final diag = '[DIAG after-NEW-VOYAGE '
    'menuStart=${ElementFinders.get[GameName]StartButton().evaluate().length} '
    'gameSkip=${ElementFinders.get[GameName]SkipTurnButton().evaluate().length} '
    'resultsPlayAgain=${config.getPlayAgainButton().evaluate().length} '
    'homeCarnival=${ElementFinders.getCarnivalDerbyCard().evaluate().length} '
    'resumeModal=${ElementFinders.getResumeGameModalOverlay().evaluate().length}]';
expect(ElementFinders.get[GameName]StartButton(), findsOneWidget,
    reason: 'Should be on menu after NEW VOYAGE. $diag');
```

Apply to: every nav-back test, every tap-then-expect pair, every results-screen and modal action. Build it in *during initial test authoring*, not after a failed run.

---

### 16. `tester.tap` requires `ensureVisible` before it for any button inside a `SingleChildScrollView`
In headless chromedriver mode (`-d web-server`), `tester.tap` only registers a click on widgets in the visible viewport. Buttons below the fold are silently un-tappable — the tap is a no-op and the test stays exactly where it was.

The results screen wraps action buttons (NEW VOYAGE / PORT HOME / SET SAIL AGAIN — or the equivalent named buttons for this game) in a `SingleChildScrollView`. With a 1080-tall viewport and a 420px winner avatar + headline + stats card, the action buttons fall off-screen. Same applies to Save Modal Save and Resume Modal Resume buttons.

**Rule:** ANY shared helper that taps a button living inside a `SingleChildScrollView` (results-screen actions, save/resume modal buttons) must `ensureVisible + pump` first:
```dart
await tester.ensureVisible(button);
await tester.pump();
await tester.tap(button);
```
Apply this to `clickPlayAgain`, `clickChangeSettings`, `clickSelectDifferentGame` etc. in `shared/results_helpers.dart` AT INITIAL AUTHORING. Any inline tap on a results-screen / modal button in test bodies needs the same.

**Home-screen game cards are also a `SingleChildScrollView`.** As the GAMES list grew past 6 entries, bottom-row cards started landing offscreen at the default 1366×768 viewport. Direct `tester.tap(config.getGameCard())` was a silent no-op for those cards. Use the shared helper:
```dart
await UITestHelpers.tapGameCard(tester, config);
// (does ensureVisible + pump + tap + PumpSequences.navigation internally)
```
NEVER use `await tester.tap(config.getGameCard())` directly — it works at the moment a game is added but starts failing silently once enough other games are added that the new game's card lands below the fold. AR-6 grep enforces this: `grep -rE 'tester\.tap\(config\.getGameCard\(\)\)' integration_test/` (excluding `ui_test_helpers.dart` which references the deprecated pattern in docs) must return nothing.

---

### 17. Save/Resume tests that tap *Resume* must use the in-game save flow, not `preSaveGame`
`preSaveGame(GameSaveConfig.foo())` writes a placeholder `gameState = {'_marker': 'test'}`. When a test taps Resume, the menu calls `provider.restoreGame(savedGame)` → `[GameName]Game.fromJson(savedGame.gameState)` which immediately casts a required field (`json['grid'] as List<dynamic>` for grid-based games, etc.) and crashes. The screen then renders with `_currentGame == null` and crashes again — observed as "Multiple exceptions (2)" with no further detail in the headless log.

**Rule:** Reserve `preSaveGame` for tests that *only verify the resume modal appears* in the saved-games list. For any test that actually taps Resume:
```dart
// Set up + save via the in-game flow (real toJson() lands in gameState):
await setupAndStartGame(tester, config, playerNames: ['Alice', 'Bob']);
await throwDartViaMock(tester, someTarget);
await UITestHelpers.tapGameScreenBackButton(tester, config);
final saveButton = ElementFinders.getSaveGameModalSaveButton();
await tester.ensureVisible(saveButton);
await tester.pump();
await tester.tap(saveButton);
await PumpSequences.navigation(tester);

// Look up the savedId we just created:
final savedGames = await SaveGameService().loadSavedGames('[GAME_NAME_SNAKE]');
final savedId = savedGames.first.id;
// Now selectSavedGameTile + tap Resume can succeed.
```

---

### 18. The Resume modal's Resume button is disabled until a tile is selected
`ResumeGameModal._buildButtons` wires `onPressed: hasSelection ? () { ... } : null` where `hasSelection = _selectedGameId != null`. The user must tap a saved-game tile first to populate `_selectedGameId`. Tests that go straight to `tap(resumeButton)` are tapping a disabled button — silent no-op, modal stays visible.

**Rule:** Every test that taps Resume must first call:
```dart
await UITestHelpers.selectSavedGameTile(tester, savedId);
```
*Then* `ensureVisible + tap` the Resume button. Document with a comment so future readers know why the tile-tap is required.

---

### 19. `_startGame` must use `Navigator.push`, NEVER `pushReplacement` — AND register `.then((_) => _checkForSavedGames())`
`pushReplacement` removes the menu route from the stack. After "back from game" or "Save modal Save" both pop one route, the user lands on Home, not Menu. Tests that expect "back-from-game returns to menu with settings preserved" (a standard pattern across all games) fail because the menu is gone.

**Rule (push, not pushReplacement):**
```dart
void _startGame() {
  // ...startGame(...)
  Navigator.push(   // NOT pushReplacement
    context,
    MaterialPageRoute(builder: (_) => const [GameName]GameScreen()),
  ).then((_) => _checkForSavedGames());   // ← MANDATORY
}
```
Game→Results uses its own `pushReplacement` (game route is consumed). NEW VOYAGE / Change Settings on Results uses `pushAndRemoveUntil((r) => r.isFirst)` to push a fresh menu and discard everything below. Both flows still work correctly with the menu staying on the stack during gameplay.

**Rule (refresh `_hasSavedGames` after the game pops):** BOTH `_startGame` AND `_resumeGame` MUST register `.then((_) => _checkForSavedGames())` on the `Navigator.push`. The AppBar's conditional `ResumeGameButton` (rendered when `_hasSavedGames == true`) only shows after the menu's `_hasSavedGames` flag flips to true — which requires re-running the saved-games API check after the game-screen pops back. Without the callback, a user who saves their game via SaveGameModal returns to a menu where the resume button stays hidden, even though a saved game now exists.

**Why:** Pirate's Grid shipped with this asymmetry — `_resumeGame` had the `.then` but `_startGame` did not. Five canonical save_resume tests (`resume_button_color_when_enabled_test`, `resume_button_enabled_after_save_test`, `resume_button_hidden_after_resume_test`, `resume_button_shows_modal_test`, `resume_modal_start_new_game_test`) failed because their setup goes save → return → expect ResumeGameButton, and the button was never added to the AppBar. The fix was a one-line addition to `_startGame`. The asymmetry was caught only when the canonical 16-file save_resume pack was added; the pre-existing 6-sub-test file didn't exercise the in-game save flow that depends on this callback.

**How to apply:** AR-4 audit must grep `_startGame` and `_resumeGame` in every menu and confirm both push calls have `.then((_) => _checkForSavedGames())`. Reference: monster_mash menu lines 976-979 (`_startGame`) + 993-998 (`_resumeGame`); lunar_lander menu lines 116-121 + 136-139; carnival_horse_race menu (`_startGame` and `_resumeGame`). Pirates Grid menu lines 113-116 + 138-145 (after fix).

---

### 20. `_resetTurnForPlayer` (edit-score replay) must undo *all* win side-effects, including match-level
When the original turn caused a round-win that promoted to a match-win, `_applyRoundResult` already incremented `roundsWon`, set `matchWinnerId`, set `state = GameState.finished`, and set `gameEndTime`. If the reset only clears round-level fields (`winnerId` / `winningLine` / `isDraw`), `provider.hasWinner` (which reads `matchWinnerId != null || isMatchDraw`) still returns true, AND `processDartThrow` rejects the replayed segments via the `!isGameActive` early-return guard. The edit silently does nothing.

**Rule:** Capture pre-reset state BEFORE clearing round-level fields, then undo match-level side-effects when the turn caused them:
```dart
// Capture BEFORE clearing winnerId/isDraw:
final thisTurnWonRound  = game.winnerId == playerId;
final thisTurnWonMatch  = game.matchWinnerId == playerId;
final thisTurnDrewMatch = game.isMatchDraw && !thisTurnWonMatch;

// ... existing reset of winnerId/winningLine/isDraw, dart counters, cell undo ...

if (thisTurnWonRound) {
  game.roundsWon[playerId] = ((game.roundsWon[playerId] ?? 0) - 1).clamp(0, 99999);
}
if (thisTurnWonMatch || thisTurnDrewMatch) {
  game.matchWinnerId = null;
  game.isMatchDraw = false;
  game.state = GameState.playing;
  game.gameEndTime = null;
}
```

---

### 21. `processDartThrow` silently drops darts after `state = GameState.finished` — edit dialog tests must compensate
Provider's `processDartThrow` early-returns on `if (_currentGame == null || !isGameActive) return;`. After a Bo1 win, follow-up Miss throws don't make it into `currentTurnDartSegments`. When the edit-score dialog opens, it sees `initialSegments=['S{n}']` (only the winning dart). `_parseScore` returns `{ring: null, number: null}` for darts 2 and 3. The dialog's validation then fails: Save button stays disabled until every dart has a non-null ring.

**Rule:** Edit-score "remove winner" tests must explicitly set every dart in the dialog, not just the winning one:
```dart
await EditScoreHelpers.setDart1(tester, 'Miss');
await EditScoreHelpers.setDart2(tester, 'Miss');   // even if originally a Miss
await EditScoreHelpers.setDart3(tester, 'Miss');   // — provider dropped it after the Bo1 win
await updateScore(tester);
```
Document this in the test with a comment so future readers know why darts 2 and 3 are being set.

---

### 22. Edit-score helper `_parseSegment` must accept all common Miss representations
Score-display widgets render Miss as `'-'`, `'—'`, or empty depending on configuration. If `_parseSegment` only recognizes literal `'Miss'`, callers passing the displayed string get an `ArgumentError: Invalid segment format`. The error gets swallowed mid-tap and the Save button stays disabled — silent failure that's hard to diagnose.

**Rule:** Author `_parseSegment` (in BOTH `integration_test/shared/edit_score_helpers.dart` AND `test/shared/edit_score_helpers.dart` per rule 26) to accept the union of representations:
```dart
final trimmed = segment.trim();
if (trimmed.isEmpty
    || trimmed == '-'
    || trimmed == '—'
    || trimmed.toLowerCase() == 'miss'
    || trimmed.toLowerCase() == 'm') {
  return {'ring': 'Miss', 'number': null};
}
```
Also accept lowercase `d`/`t` in the regex prefix. And `ensureVisible` before every ring-button and number-button tap inside the dialog (rule 16 applies here too).

---

### 23. `PlayToCompleteStrategy.getNextThrow` must NEVER return `null` for a "deliberate miss"
The auto-play runner does `if (dart == null) break;` — null is its STOP signal. For multi-player games where one player must miss every dart (to designate the auto-play winner — see rule 10), returning null breaks the auto-play loop on the first miss-turn, leaving the game stuck and the test timing out.

**Rule:** Return a miss-shaped `SimulatedThrow` for deliberate misses:
```dart
if (currentPlayerId != designatedWinnerId) {
  return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
}
```
Match the pattern in `target_tag_strategy.dart` (which throws a "neutral" non-targeted number for non-winner turns). Never use `return null` to mean "miss" — the runner can't tell the difference.

---

### 24. Player column needs an inner `LayoutBuilder` to clamp character size by actual column height
The outer game-area `LayoutBuilder.constraints.maxHeight` is what's visible to the layout root, but by the time the player Column resolves layout inside `Expanded(Row(...))`, it receives only ~75% of that — AppBar (a 35pt title can push to ~100px) + Row crossAxis distribution + padding eat the difference. Computing `charSize` against the outer constraint produces values that overflow the inner column.

**Rule:** Wrap `_buildPlayerColumn`'s body in a `LayoutBuilder` and clamp `charSize` against `columnConstraints.maxHeight`, with a reserve that varies with active state AND with whether speedPlay is on:
```dart
return LayoutBuilder(builder: (context, columnConstraints) {
  final reserveH = isActive
      ? 220.0 + (game.speedPlay ? 56.0 : 0.0)   // +56 for the 36pt timer + spacing
      : 80.0;
  final maxByH = (columnConstraints.maxHeight - reserveH).clamp(0.0, double.infinity);
  final charSize = math.min(desiredCharSize, maxByH);
  return Column(...);
});
```
The OUTER LayoutBuilder should provide a `desiredCharSize` derived from width only; the inner LayoutBuilder is responsible for the height clamp.

---

### 25. UI test color assertions must compare RGB bytes, not `Color.value`, on Flutter web
`Color.value` is deprecated in Flutter 3.27+, and on Dart-to-JS its int representation can flip negative for high-bit ARGB values (sign-bit issue). `0xFFCD7F32` may compare as `-3342030`, breaking equality checks against the literal even when the color is correct.

**Rule:** Compare RGB bytes (always 0–255 ints):
```dart
return color != null
    && color.red   == 0xCD
    && color.green == 0x7F
    && color.blue  == 0x32;
```
Apply this to every visual-validation test that asserts on a widget's border, background, or text color.

---

### 26. Every shared helper that compiles in both contexts MUST stay byte-identical between `test/shared/` and `integration_test/shared/`
When the two drift, non-UI tests pass while UI tests fail with "Member not found" against the same-named class — the symbol is in one file but not the other, and the resolution depends on which test type is running. Drift happens silently and is hard to diagnose without reading both files.

**The set of mirrored helpers is dynamic, not enumerated.** Past versions of this skill listed "12 mirrored shared helpers" by name. That list went stale (a 13th, `pause_modal_helpers.dart`, was added at some point without the list being updated; `failure_screenshot_helper.dart` was nearly added as a 14th before being merged into `ui_test_helpers.dart`). Any rule that depends on a specific count is wrong by construction. The actual rule: for every `*.dart` file present in BOTH `integration_test/shared/` and `test/shared/`, the two copies MUST be byte-identical. Files present in only one directory (e.g. `mock_api_helpers.dart` and `player_test_utils.dart` in `test/shared/` only — they import packages non-UI tests have but UI tests don't, OR have widget-only dependencies the other way around) are intentionally non-mirrored and excluded from the parity check.

**Rule:** Whenever a Sonnet sub-agent is asked to add a method or function to a shared helper that exists in both directories, the prompt MUST instruct it to apply the IDENTICAL change to the other file in the same edit pass. Whenever a sub-agent CREATES a new shared helper, the prompt MUST decide up front whether the helper compiles in both contexts:
- **If yes** (no `package:integration_test` import, no widget-tree-only types, etc.), create it in BOTH directories from the start.
- **If no** (e.g. uses `IntegrationTestWidgetsFlutterBinding`, `WidgetTester`, etc.), create it ONLY in the directory that can compile it.

**Verification command (use this exact form — do NOT enumerate by name):**
```bash
diff -rq integration_test/shared test/shared 2>&1 | grep "differ" || echo "OK: all mirrored helpers byte-identical"
```
The `diff -rq` output emits one line per pair that differs (`Files X and Y differ`). The `grep "differ"` filter strips the expected `Only in test/shared: <file>` lines for non-mirrored helpers. If the grep finds anything, it's a parity violation that must be fixed before the build can proceed. AR-4 and AR-6 audits use this command directly, not a hardcoded list.

**Caveat — flutter drive web compile cache:** brand-new files under `integration_test/shared/` are silently ignored by the web compile cache (commit `4d1377e`). When a UI test imports a brand-new shared file, the compile fails with `org-dartlang-app:/...File not found` even though `dart analyze` and disk reads confirm the file exists. Workaround: add the new functionality as a static method on an existing long-lived helper class (e.g. `UITestHelpers`) instead of creating a new shared file. The `UITestHelpers.runWithFailureScreenshot` helper was placed inside `ui_test_helpers.dart` for exactly this reason — see `failure_screenshot_helper.dart` in commit `3cafc83` (deleted) for the pattern that didn't work.

---

### 27. Randomized game targets — every dart-throwing test must read the target at runtime
When the game randomizes targets per session (rule 9), tests that hardcode dart numbers (`throwDartViaMock(tester, 20)`) hit the wrong cell or no cell at all. The lookup pattern is required everywhere a test wants to deliberately hit a specific cell.

**Rule:** Add `get[GameName]CellTargetNumber(tester, row, col)` (or equivalent) to `integration_test/shared/provider_helpers.dart` AT INITIAL TEST AUTHORING when targets are randomized. Add a `throwForCellTarget(tester, target)` dispatch helper that reads the cell's target requirement (e.g. `CellTarget` for grid games) and chooses the right multiplier (`single` / `double` / `triple` / `bull`). Use these in every gameplay test. Sync to `test/shared/provider_helpers.dart` per rule 26.

```dart
// Helper in integration_test/shared/provider_helpers.dart:
static int get[GameName]CellTargetNumber(WidgetTester tester, int row, int col) {
  final grid = get[GameName]Grid(tester);
  return grid![row][col].target.number;
}

// In tests:
final t02 = ProviderHelpers.get[GameName]CellTargetNumber(tester, 0, 2);
await throwForCellTarget(tester, provider.currentGame!.grid[0][2].target);
```

---

### 28. Pause Modal canonical 20-test pack (7 menu + 8 gameplay + 5 results) is mandatory
A "minimal" pause modal pack of 1 testWidget per file misses the modal-stacking edge cases (pause-over-RemoveDartsModal, pause-over-SaveGameModal, EditScoreDialog auto-closes on disconnect, RemoveDartsModal still visible after reconnect) that are the actual bug-prone seam between the dartboard layer and per-screen overlays. These cases ONLY exist in the full 20-test pack.

**Why:** Pirate's Grid shipped with 3 testWidgets (1 per file). A cross-game test-count audit weeks later showed every other game had 20 (Carnival Derby, Target Tag, Monster Mash, Reef Royale, Clockwork Quest, Lunar Lander). The gap was invisible inside the "I wrote pause tests" claim — only counting tests across games surfaced it.

**How to apply:** In Phase 7, the `pause_modal/` subdirectory's three files MUST contain exactly 7, 8, 5 testWidgets respectively (canonical names listed in Phase 7 Step 7A's `pause_modal/` bullet). The pack is mirrored 1-for-1 from `integration_test/monster_mash/pause_modal/*` with finder substitutions only — no game-specific test additions/omissions. AR-6 audit check (m) verifies the count.

---

### 29. Save/Resume canonical 16-file pack (one testWidget per file) is mandatory
The "16 separate files, one testWidget each" structure is not a stylistic preference — it's the canonical helper pack used by the shared `SaveResumeHelpers` to map cleanly onto the user-flow surface. Collapsing into one file with multiple sub-tests OR shipping with fewer than 16 file names elides specific edge cases (resume-button-color-when-enabled, resume-button-hidden-after-resume, resume-modal-start-new-game, resume-modal-delete-individual, resume-modal-delete-all, resume-resave-overwrites).

**Why:** Pirate's Grid shipped with 1 file containing 6 sub-tests. Lunar Lander shipped with 6 separate files. Both missed 10 of the 16 canonical edge cases. The 3 "real-flow" tests (resume_game_loads_screen, resume_resave_overwrites, resume_auto_deletes_on_completion) are the *only* ones that catch `[GameName]Game.fromJson` regressions on actual restore — without all three, only the metadata-list happy path is verified.

**How to apply:** Phase 7's `save_resume/` subdirectory MUST contain the 16 files listed in Phase 7 Step 7A's `save_resume/` bullet, each with exactly 1 testWidget. The 3 real-flow files MUST use the in-game save flow (Rule 17) since `preSaveGame`'s placeholder gameState crashes restore. AR-6 audit check (n) verifies the file count and per-file testWidget count.

---

### 30. `test/providers/[game]_provider_game_test.dart` is mandatory — NOT optional, NOT replaced by screen-level tests
Every game except Lunar Lander and Pirate's Grid (both shipped without it, both caught only post-launch) has a dedicated `test/providers/[game]_provider_game_test.dart` with 44–50 pure-provider tests. The screen-level `test/screens/games/[game]/[game]_game_test.dart` tests via the screen wrapper and inherits the screen's coupling; the provider-level file isolates `processDartThrow` / `skipTurn` / win detection / turn advancement / `_resetTurnForPlayer` / option side-effects so regressions surface clearly when the screen layer changes.

**Why:** A screen-level test that passes after a provider regression is common — the screen often masks provider-level bugs by re-rendering reasonable state from stale data. Provider-isolated tests fail loudly. The two layers catch different classes of bugs.

**How to apply:** Phase 3 file list now requires this as file #4 (alongside model, provider, screen-level test). Minimum 40 tests, with required groups: initial state, `processDartThrow` per option/difficulty, turn advancement, win detection, per-option side-effects, round/match transitions, `_resetTurnForPlayer` undo (Rule 20), randomized targets (if applicable), `endGame` + `resumedSavedGameId`. AR-3 audit check (e) verifies file existence and ≥ 40 tests.

---

### 31. Per-option-value test coverage — one functional + one visual test per spec Section 7 value
A common failure pattern: spec Section 7 lists an option with N values (e.g., Difficulty: Easy/Medium/Hard); the implementer writes ONE test (typically Easy or default) and assumes the "option logic" is covered. The remaining N-1 values ship with zero functional UI coverage. Provider tests prove the option's logic; UI tests prove the option is wired through menu → screen and renders the expected behavior under the real frame loop.

**Why:** Pirate's Grid shipped with `plant_flag_easy_test.dart` and `plant_flag_medium_test.dart` but NO Hard test, NO Best Of 5 test, NO Speed Play timer-expires test. Three Section 7 values had zero functional UI coverage. Spec coverage audits passed because each option had "a test"; the per-VALUE gap was missed.

**How to apply:** In Phase 7 Step 7A, build the option-value coverage table (Section 5c) BEFORE writing tests. For every Section 7 row × every distinct value, plan one functional gameplay test file. For every option that has a *visible* effect (badge, color, glow, text), additionally plan one visual_validation test (Section 5d). AR-6 audit check (o) verifies the matrix is complete.

Test-naming conventions:
- Functional: `<option>_<value>_<behavior>_test.dart` (e.g., `difficulty_hard_corner_triple_required_test.dart`) or `<behavior>_<option>_<value>_test.dart` (e.g., `plant_flag_hard_test.dart`)
- Visual: `<option>_badges_test.dart` (groups Easy/Medium/Hard sub-tests) or `<element>_<state>_test.dart` (e.g., `cell_flag_colors_test.dart`, `winning_row_glow_test.dart`)

---

### 32. Visual-validation tests must assert APPEARANCE, not just EXISTENCE
A visual_validation test that only checks `findsOneWidget` for a spec-Section-10 element is incomplete. The spec says "X is rendered as Y" — your test must assert Y (text content, RGB color, border properties, icon presence), not just that X exists.

**Why:** Pirate's Grid spec Section 10B says "Winning cells get Treasure Gold pulsing glow + sparkle overlay" — no test asserted the glow color. The spec says "P1 cells get Blood Red border glow, P2 cells get Sea Foam Teal border glow" — no test asserted the colors. The spec says "Round tracker shows P1 wins in Blood Red, P2 wins in Sea Foam Teal" — only widget existence was tested. Six visible spec elements shipped with logical-only assertions and zero visual checks.

**How to apply:** When authoring a visual_validation test, for each assertion ask: "If the screen rendered this element with the WRONG color/text/icon/border, would my test still pass?" If yes, add the appearance assertion using RGB byte comparison (Rule 25), `find.descendant` for inner Text content, or BoxDecoration introspection for borders/shadows. AR-6 audit check (l) builds the visual-element coverage matrix; check (o) extends it to per-option-value visuals.

---

### 33. Test-coverage audits must be grounded in IMPLEMENTATION, not spec aspiration
The spec describes what the game *should* render; the screen code describes what the game *does* render. These diverge constantly: a designer simplifies during build (animal characters in place of a rocket icon), a feature is deferred (no "Round Complete" overlay yet), or a section was rewritten without updating the spec. A coverage audit that maps spec → tests without verifying implementation produces three classes of finding mixed together — and only one is a real test gap.

**Why:** A Lunar Lander coverage audit run from the spec alone produced 5 visual_validation test recommendations (rocket icon position, flame trail, ORBIT/MOON markers, tick marks, "CRASH!" overlay) for elements that did not exist in `lunar_lander_game_screen.dart`. The screen renders animal character images on a Flame Orange descent line — a deliberate design pivot. Writing those 5 tests would have produced 5 failing tests, not 5 closed gaps.

**Rule:** Every spec element being audited must be classified by reading the actual code:
- **Implemented + Tested** → no action
- **Implemented + Not tested** → real test gap; write the test
- **Not implemented** → NOT a test gap; surface as a separate "implement vs. update spec" decision to the user

**How to apply:** before proposing any test addition, grep the screen/provider/test_keys for the spec keyword. If the keyword is not in the code, the gap is a spec/code divergence — do not generate a test prompt for it. AR-6 audit check (l) enforces this for visual elements; the same principle applies to options, behaviors, and any other spec claim.

---

### 34. Menu screens must guard the player section with `playerProvider.isLoading`
`PlayerProvider._selectedPlayers` is shared global state that persists across games. The menu's post-frame `clearSelection()` runs AFTER the first paint, so without a loading guard the user briefly sees a flash of the previous game's players in the "Selected" column before the post-frame callback wipes them. On a slow `loadPlayers()` round-trip (cold start, slow server) the flash can last 100–500ms and is clearly visible.

**Why:** Pirate's Grid, Lunar Lander, Target Tag, and Clockwork Quest all shipped without this guard and exhibited the flash. Carnival Derby, Monster Mash, and Reef Royale had the guard from the start and behaved correctly. The asymmetry was caught only when a user reported "the previously selected players show briefly and then get unselected" on PG/LL — every other game looked empty from the start because the spinner masked the 1-frame initial paint with stale state.

**Rule:** Every menu screen MUST wrap its main content (the LayoutBuilder/Row containing left+right panels) in a `Consumer<PlayerProvider>` that returns a centered `CircularProgressIndicator` while `playerProvider.isLoading` is true:
```dart
Consumer<PlayerProvider>(
  builder: (context, playerProvider, child) {
    if (playerProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder( /* or Row */
      builder: (context, constraints) { ... },
    );
  },
),
```

The post-frame callback in `initState` (which calls `loadPlayers()` → sets `_isLoading=true` → notifies → loads → `_isLoading=false` → `clearSelection()`) takes over the rendering window between first paint and load completion. The Consumer rebuilds during that window, the spinner replaces the layout, and the user sees "spinner → empty list" instead of "stale list → empty list".

**How to apply:** in Phase 4 (Screens), the menu screen sub-agent must include this guard. AR-4 audit row should grep `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart` for `playerProvider.isLoading` and `CircularProgressIndicator` — both must be present in the menu's build tree. Reference: monster_mash menu lines 208-228, reef_royale menu lines 198-213.

---

### 35. Real background image used in EVERY wireframe + EVERY screen
The mockups must reference the actual `[GameName]-Background.png` asset on every screen — menu, game, results — via `<img>` or CSS `background-image: url(...)`. CSS gradients or solid fills as a "stand-in" silently teach the wireframe sub-agent that the background is generic, and the same omission then carries into the Flutter screens.

**Why:** Pirate's Grid Stage A wireframe used a CSS parchment-style gradient as the menu background; the actual user-provided `PiratesGrid-Background.png` is a fully illustrated pirate scene. The discrepancy wasn't caught until late visual validation, by which time UI elements had been laid out without an overlay budget for the busy art. Recurring across at least 3 game builds.

**How to apply:** Phase 2 staged approval gates — the orchestrator's AR-2 review for each stage must `grep -c "[GameName]-Background\|[GameName]-Bg" temp_wireframes/[GAME_NAME_SNAKE]/<stage>.html`. Must report ≥ 1 hit per HTML. AR-1 (Phase 1) also adds a background-image suitability check: read the image, classify as TEXTURE (suitable backdrop) vs ILLUSTRATED SCENE (will compete with UI), surface to user as an overlay-budget decision before Phase 2 starts.

---

### 36. Game UI fills full screen height; dartboard emulator is a transparent OVERLAY
The dartboard emulator section only renders when `!dartboardProvider.isConnected`; in production gameplay (board connected) the game content has the FULL screen height. Wireframes that reserve vertical space for the emulator (treating it as a `Column[gameContent, dartboardEmulator]` sibling) propagate a too-short content area into the Flutter screens, which then overflow at the headless 1366×768 viewport.

**Why:** Pirate's Grid wireframes laid out the gameplay screen with the emulator as an inline child, eating ~150-200px of vertical height. When the screen was implemented in Flutter, the player column / grid clamped against this reduced height; cellSize was wrong, character size was wrong, RenderFlex overflowed by 76px. Multiple round-trip fixes (`_buildPlayerColumn` inner LayoutBuilder, speedPlay reserve, grid centering) addressed the symptoms but the wireframe model had been wrong from the start.

**How to apply:** Phase 2 Stage B requires the wireframe to draw `gameContent` at `width: 100%; height: 100%` and the dartboard emulator as `position: absolute; bottom: 0` (or a `Positioned(bottom: 0)` Stack child OUTSIDE the body Stack — sibling of Scaffold). The `position: absolute` model mirrors the actual Flutter widget tree and prevents the wireframe from baking in a phantom height reservation. AR-2 review checks the wireframe HTML for `position: absolute; bottom` on the emulator block.

---

### 37. Wireframes must validate at the headless test viewport (1366×768)
Wireframes designed at desktop monitor sizes (1920×1080+) look great in the browser preview but overflow at the parallel runner's default headless Chrome viewport. The screenshot test then captures a clipped/overflowed state that the orchestrator must triage as a layout bug — usually requiring screen code changes after the fact.

**Why:** PG wireframes were authored at desktop dimensions and looked clean in browser preview. The actual screenshot tests captured a 1366×768 viewport showing 76px column overflow, off-center grid, oversized winner character. Each was a separate fix-and-recapture cycle.

**How to apply:** Phase 2 every wireframe HTML wraps content in `<div style="width: 1366px; height: 768px; overflow: hidden; ...">` for the visual review. Inside this wrapper, layout primitives (% widths, `min/max` clamps, flex/grid) MUST adapt without introducing horizontal scroll, clipped buttons, or content overflow. AR-2 review opens the HTML at exactly 1366×768 in dev tools and confirms no overflow indicators.

---

### 38. UI tests wrap their bodies in `UITestHelpers.runWithFailureScreenshot` during the build phase
When a UI test fails the only artifact available in the standard text log is a stack trace — no screen state, no DOM, no rendered pixels. Authors who add screenshot capture retroactively (after a failure) waste an iteration cycle: failed run → inspect log → instrument → re-run. Building the failure capture into every test from initial creation removes that cycle and turns the first failed run into an actionable diagnostic.

**Why:** Multiple PG debug rounds (rounds 2-7 of the post-build refinement) consisted entirely of "test fails → add diagnostics → re-run". Each round cost 5-15 minutes of test execution time. The user explicitly requested that diagnostic instrumentation be included from initial creation so the first failed run produces a screenshot the orchestrator can read instead of an opaque "Multiple exceptions (2)".

**Why build-phase-only:** the wraps add per-test boilerplate that's noise once tests are stable. The production runner uses `test_driver/integration_test.dart` which has no `onScreenshot` callback — the wrap would be inert there anyway, but its presence still adds visual clutter. Removing the wraps at the Phase 9 transition aligns the new game's tests with every other game's tests in form.

**How to apply:**
- **During build (Phase 7 iterative authoring):** every test in the new game's pack wraps its body in `UITestHelpers.runWithFailureScreenshot(tester, '[GAME_NAME_SNAKE]_<subdir>_<test_basename>', () async { /* body */ })`. Tests run via `flutter drive --driver=test_driver/screenshot_test.dart --target=<test> -d chrome --dart-define=SERVER_PORT=<port> --browser-dimension=1366x768`. Failure PNGs land in `temp_screenshots/failures/<sanitized-test-name>_<timestamp>.png`.
- **At Phase 9 transition (after Gate 4 passes):** the "Failure-screenshot wrap removal" step in Phase 9 dispatches a Sonnet sub-agent to unwrap every test in the new game's pack. The helper itself stays in `integration_test/shared/ui_test_helpers.dart` — only the per-test wraps are removed. Future game builds will use the helper again during their own Phase 7.
- **Helper location:** `UITestHelpers.runWithFailureScreenshot` (a static method on `UITestHelpers` in `integration_test/shared/ui_test_helpers.dart`). The helper is part of `UITestHelpers` rather than a standalone file because brand-new files under `integration_test/shared/` are silently ignored by flutter drive's web compile cache (documented in commit `4d1377e` and Rule 26).
- **Driver:** the `test_driver/screenshot_test.dart` driver has the `onScreenshot` callback that writes PNG bytes to disk (with `mkdir -p` for subdirectory paths). The default `test_driver/integration_test.dart` driver does NOT have `onScreenshot` — that's intentional, since post-build tests don't need it.
- **Verification:** `integration_test/_smoke/failure_screenshot_smoke_test.dart` is a deliberately-failing test that exercises the helper. Lives outside any game directory so neither runner picks it up. Invoke directly via `flutter drive` after a Flutter SDK upgrade or driver change to confirm the mechanism still works.
- **AR-4 audit during build:** every `*_test.dart` under `integration_test/[GAME_NAME_SNAKE]/` (excluding `_helpers.dart` and the smoke test) MUST contain `UITestHelpers.runWithFailureScreenshot`. AR-4 enforces this until Gate 4 passes; after Gate 4, AR-4 enforces the OPPOSITE (no wraps in any test).

---

### 39. UI tests authored iteratively: screenshot first, then 1 per category easiest-to-hardest
Authoring all UI tests in one batch and running them all at once produces a wall of failures sharing the same root causes (missing ensureVisible, hardcoded grid targets, missing in-game save flow, etc.). The orchestrator then debugs one category at a time across many files instead of fixing the root once and replicating.

**Why:** PG had 7+ debugging cycles (commit titles "Round 2/3/4/5/6 fixes ...") because all 47 UI tests were authored upfront. Each round fixed a single bug class across dozens of files. The user requested that future builds author one test per category at a time, run it, fix the root, then replicate.

**How to apply:** Phase 7 Step 7A sub-rule 1.6 specifies the order of categories (visual_validation screenshot test → menu_and_settings → add_player → navigation → gameplay → pause_modal → results_screen → save_resume → edit_score → play_to_complete) and the per-category loop (author one → run → fix → replicate). The orchestrator MUST resist the temptation to delegate "write all tests in parallel" to a single sub-agent batch.

---

### 40. Screenshot test for timer-driven UI states must freeze the timer
Screenshot test entry that captures a state involving an active `Timer.periodic` (Speed Play countdown, animation loop) deadlocks: pumping `pump(Duration)` on a continuously-firing timer never settles. Past failure: PG screenshot test halted at #12 of 15 ("game_speed_play_timer transition"). The orchestrator waited 4 minutes before killing — wasted iteration time.

**How to apply:** Phase 8 STEP 1 imposes a 25-second per-screenshot progress timeout (down from 60s). For the timer-driven scene specifically: (a) freeze the timer before capturing — set the screen state to a fixed timer value via a `provider.setSpeedPlayTimerForTest(...)` hook if exposed, OR (b) capture immediately on the same frame the timer was started (no `pump(Duration)`), OR (c) skip that visual state and document it in the spec coverage report as a known gap. The screen and provider may need a test hook (`@visibleForTesting void setTimerForCapture(int seconds) { ... }`) added in Phase 4 to support this without exposing private state production-side.

---

### 41. Cross-game parity audit — grep all 6 existing screens before creating the 7th
Three production bugs in the last two months followed the same shape: 5 or 6 of the 6 existing games' screens implemented some pattern; the new (7th) game's screen omitted it. Each was caught only post-launch by a user observing the inconsistency, not by AR review.

**Past failures matching this shape:**
- **Cross-game selection leak (commit `d96c19f`)** — 5 of 6 menus called `playerProvider.loadPlayers()` then `playerProvider.clearSelection()` in their `addPostFrameCallback`. Lunar Lander did not. Result: selecting players in CD then opening LL left those players already selected. Caught after 6 menus had shipped.
- **`isLoading` spinner guard (commit `d96bac2`)** — 3 of 7 menus (CD, MM, RR) wrapped their main content in `Consumer<PlayerProvider>` returning `CircularProgressIndicator` while loading. TT, CQ, LL, PG did not. Result: brief flash of stale selection on each of those 4 menus. Caught after 7 menus had shipped, when a user reported the flash on PG.
- **`.then((_) => _checkForSavedGames())` after `_startGame` (commit `042d791`)** — 6 menus had this callback on BOTH `_startGame` and `_resumeGame`. PG had it on `_resumeGame` only — `_startGame` was missing it. Result: 5 canonical save_resume tests failed because the AppBar's conditional `ResumeGameButton` never appeared after the in-game save flow. Caught when the canonical 16-file save_resume pack ran for the first time on PG.

In every case, the omission was invisible to the new game's tests in isolation; only cross-game comparison surfaced it.

**Rule:** AR-4 (Phase 4 review) MUST execute a parity grep for every shared pattern before approving the screens. The audit:

1. **Enumerate each lifecycle hook** (initState, post-frame callbacks, dispose, addPostFrameCallback bodies, button onTap handlers, Navigator.push call sites) in EVERY existing game's three screens (`menu_screen.dart`, `game_screen.dart`, `results_screen.dart`).
2. For each method/handler, run `grep -n '<canonical-line>' lib/screens/games/*/[gN]_<screen>.dart` across ALL games — check the new game's file is in the result list. Examples:
   - `grep -n 'playerProvider.loadPlayers' lib/screens/games/*/[g]_menu_screen.dart`
   - `grep -n 'playerProvider.clearSelection' lib/screens/games/*/[g]_menu_screen.dart`
   - `grep -n 'playerProvider.isLoading' lib/screens/games/*/[g]_menu_screen.dart`
   - `grep -n '_checkForSavedGames()' lib/screens/games/*/[g]_menu_screen.dart` — and verify it appears AFTER both `_startGame`'s push AND `_resumeGame`'s push
   - `grep -n '\.then((_)' lib/screens/games/*/[g]_menu_screen.dart` — every Navigator.push from a menu should have a `.then` callback
3. **For every grep, the new game's file MUST appear in the output.** Any omission is a parity violation surfaced to the user as a corrective sub-agent dispatch BEFORE the screens are accepted into Phase 5.
4. **Add new patterns to the parity grep list** as they're discovered. The list is intentionally append-only — every recurrence-prevention rule (Rules §8, §19, §34, §41 itself) adds a new grep line.

**How to apply:** AR-4 audit must include a "Cross-game parity grep" section listing every grep line and the new game's name in each result. If any grep returns zero hits for the new game, AR-4 fails and the orchestrator dispatches a corrective sub-agent. This rule is the meta-protection: every individual rule (§8 player persistence, §19 _checkForSavedGames, §34 isLoading guard) gets enforced via the parity grep, even if the individual rule's "How to apply" section drifts out of date.

---

### 42. Every new game registers a `GameMetadata` entry in the filter registry
The home-screen filter bar reads `lib/constants/game_filter_registry.dart` to decide which cards to render given the user's selections. A new game whose card is added to `home_screen.dart` but whose registry entry is missing will:
- Show in the unfiltered view (because home_screen falls back to "show all" when the registry lookup returns null)
- Be invisible in EVERY filtered view (because no metadata = no match)
- Trigger the orphan-bucket check in `test/models/game_metadata_test.dart` if a filter value loses its only game

This is exactly the kind of asymmetry Rule §41's parity audit catches — the new game's id should appear in `home_screen.dart`'s `games` list AND in the registry's `_all` list AND in `test/models/game_metadata_test.dart`'s `expectedIds` set. Any of those three missing is a parity violation.

**Rule:** Phase 4 step 7a (Add the game card) is followed immediately by step 7b (Register filter metadata). Both happen in the SAME edit pass — the card and the registry entry are added together so they can't drift.

**How to apply:** AR-4 grep adds:
- `grep -n "'[GAME_NAME_SNAKE]'" lib/screens/home_screen.dart` — must match (the card's `gameId`)
- `grep -n "gameId: '[GAME_NAME_SNAKE]'" lib/constants/game_filter_registry.dart` — must match (the registry entry)
- `grep -n "'[GAME_NAME_SNAKE]'" test/models/game_metadata_test.dart` — must match (the `expectedIds` Set)
All three must hit. If any returns zero, AR-4 fails. Update `test/models/game_metadata_test.dart`'s `expectedIds` Set in the same change to keep the registry-coverage test passing.

**Adding a new filter criterion** (rare but supported):
1. Add a new enum to `lib/models/game_metadata.dart` and a field on `GameMetadata`.
2. Update EVERY existing entry in `GameFilterRegistry` to set the new field.
3. Add a new `FilterCriterion` enum value.
4. Add a dropdown in `lib/widgets/game_filter_bar/game_filter_bar.dart`.
5. Add `HomeKeys.filter<New>Button` and `filter<New>Option` in `lib/constants/test_keys.dart`.
6. Add a UI test in `integration_test/home_screen/filter_bar/`.
7. Add an OR-within-criterion case to `test/models/game_metadata_test.dart`.

The `matchesFilters` switch must cover every `FilterCriterion` — if a new criterion is added without a switch case, Dart's exhaustive-switch analyzer fails the build. That's the compile-time backstop.

---

### 43. Parallel runner worktree setup is FAIL-LOUD; existence check before workers spawn
The parallel UI runner clones the repo into one git worktree per worker so each worker has an isolated `build/` and `.dart_tool/`. If any worktree fails to create, that worker runs `flutter drive` in a non-existent directory and every test in its pack fails with `the system cannot find the path specified` — but the swallowed-error pattern (`>nul 2>&1` on `git worktree add`) masks the real cause.

**Why:** A user's UI run produced 27 failures across 4 games (target_tag, lunar_lander, pirates_grid, reef_royale). All test logs ended after the runner's "Worktree: ..." prefix line — no compile output, no test output, just "FAILED". Investigation showed `git worktree list` had only the main repo registered: `git worktree add` had failed silently for 6 of 9 workers, leaving the runner pressing on with workers pointed at empty paths. The worktree creation loop's `_wt_ok=0` check existed but didn't catch every failure mode (e.g., when leftover dirs from a prior run blocked rmdir → blocked `git worktree add` because destination exists → errorlevel propagation through nested IFs got confused).

**Rule:** `run_ui_tests_parallel.bat` worktree setup follows four invariants:
1. **Errors go to a log, not /dev/null.** Replace every `git worktree <op> ... >nul 2>&1` with `... >> "!_WT_LOG!" 2>&1` (where `_WT_LOG = !_PARALLEL_DIR!\worktree_setup.log`). When a `git worktree add` fails, the script prints the worker name, points at the log, and aborts.
2. **Prune metadata before cleanup.** A `git worktree prune` runs BEFORE the rmdir loop. Without this, stale `.git/worktrees/<name>` metadata pointing at deleted directories will make subsequent `git worktree add` fail with "fatal: '<path>' already exists" even though the dir was removed.
3. **Pre-flight kill of orphaned test processes.** Before the cleanup, kill leftover `chromedriver.exe` and `flutter_tester.exe` processes (blanket-safe — test-only) and port-scoped `dart.exe` instances bound to ports 9001-9020 (so we don't accidentally kill the user's IDE-launched dart server on a different port). A previous run that was force-killed leaves orphaned processes that hold worktree files open, blocking rmdir, and bind test ports — preventing the new run's setup. Past failure: a parallel run produced 8+ leftover chromedriver.exe processes that blocked all subsequent worktree creation.
4. **Existence check before workers launch.** After the creation loop, verify every expected worktree project dir contains a `pubspec.yaml`. If any are missing or incomplete, abort with the worker name(s) printed — workers MUST NOT spawn pointed at missing paths.

**Plus:** if rmdir leaves any leftover dir in `_WORKTREE_BASE` (because a prior chromedriver/dart process STILL has files locked despite the pre-flight kill), surface it loudly with the dir name and a hint about killing leftover processes before re-running.

**Absolute path for `_WORKTREE_BASE`:** the variable is computed as `!_SCRIPT_DIR!\integration_test_output\parallel\worktrees`, NOT a relative path. Past failure: relative `_WORKTREE_BASE` worked for `git worktree add` (called from the bat's cwd) but flutter sub-processes inherited a different cwd and `flutter pub get` printed "The system cannot find the path specified." for every worker. Absolute paths remove that variable.

**How to apply:** verify the runner has all four invariants:
```bash
grep -c '>> "!_WT_LOG!" 2>&1' run_ui_tests_parallel.bat   # must be > 0 (errors logged)
grep -c 'git worktree prune' run_ui_tests_parallel.bat   # must be ≥ 2 (before AND after rmdir)
grep -c 'taskkill /F /IM chromedriver' run_ui_tests_parallel.bat  # must be > 0 (pre-flight kill)
grep -c 'pubspec.yaml' run_ui_tests_parallel.bat         # must be > 0 (existence check)
grep '_WORKTREE_BASE=' run_ui_tests_parallel.bat | grep -c '_SCRIPT_DIR'  # must be > 0 (absolute path)
```

---

### 44. PlayerListPanel widget choice — extract in Phase 0, brief every Phase 2 sub-agent
Tiki Golf was the first team-game build under this skill. Its initial Stage A wireframe was authored against `DualPlayerListPanel` conventions (two side-by-side AVAILABLE / SELECTED panes) because the Phase 4 prompt template heavily documents DualPlayerListPanel layout rules. The spec actually called for `TeamPlayerListPanel` (a single scrolling list — Target Tag pattern). Reviewer caught it; corrective sub-agent had to redo the panel.

**Two widgets, two layouts. Cite which one the spec uses BEFORE wireframing:**
- **`TeamPlayerListPanel`** (Target Tag, Tiki Golf, any future team-mode game) — SINGLE scrolling player list with header row (count chip + ADD PLAYER button), per-row selected/unselected accent borders. Selected players sort to the top. In Manual team mode, each selected row gets a trailing team-crest icon and the team-assignment boxes appear BELOW the list.
- **`DualPlayerListPanel`** (Carnival Derby, Reef Royale, Clockwork Quest, Lunar Lander, Monster Mash, Pirate's Grid) — two side-by-side AVAILABLE / SELECTED panes with players moved between them. Specific recipe: `availableContainerMargin: EdgeInsets.zero`, `selectedContainerMargin: EdgeInsets.zero`, `listGap: 4`. The recipe is documented in detail in the Phase 4 prompt template's DualPlayerListPanel section.

**Phase 0 Step 8 must extract the widget choice from spec Section 1 ("Player List Pattern" row in the Overview table)** and propagate it as a sub-agent prompt placeholder `[PLAYER_LIST_WIDGET]` so the Phase 2 Stage A prompt knows which layout to author.

**The DualPlayerListPanel-specific recipe (`availableContainerMargin: zero, selectedContainerMargin: zero, listGap: 4`) DOES NOT apply to TeamPlayerListPanel.** Do not cite or apply it when the spec uses TeamPlayerListPanel.

**How to apply:** when extracting the player-panel widget choice in Phase 0, save it to memory (or `temp_wireframes/<game>/asset_paths.md` carry-forward decisions) so every later Phase 2 / Phase 4 sub-agent gets a literal reference to the correct widget name in its prompt's "Read first" section. AR-4 audit (pp) gains an extra grep: `grep -c 'TeamPlayerListPanel\|DualPlayerListPanel' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart` — exactly one of those must appear, matching the spec.

---

### 45. TeamPlayerListPanel is single-column regardless of player count
At 16 selected players (Team mode max), Tiki Golf's initial wireframe sub-agent assumed the list was "too long" for one column and switched to a 2-column CSS grid. Target Tag uses a single scrolling column even at its own max player count; the underlying widget renders one column.

**Rule:** the TeamPlayerListPanel's scrollable list is ALWAYS a single vertical column with `overflow-y: auto` for long lists. Do NOT switch to a 2-column grid at high player counts. Match the underlying widget's `ListView.builder` shape exactly (`team_player_list_panel.dart:243-292`).

**How to apply:** Phase 2 Stage D Team variants. When authoring `menu_team_random_<N>p.html` for N ≥ 12, the player list is still `display: block` (or `display: flex; flex-direction: column`) inside a scrollable container. AR-2 review adds a check: `grep -c 'grid-template-columns' temp_wireframes/<game>/menu_team_*.html` — only the settings-grid (`1fr 1fr`) should match; any grid on the player list is a violation.

---

### 46. Team-mode menu: team-assignment boxes stack BELOW the player list
Initial Tiki Golf wireframe placed the team-assignment boxes alongside the player list in a horizontal `flex-direction: row` panel body. Target Tag stacks them vertically — player list on top, then an "Assign Teams" caption, then the team boxes below. Reference: `lib/widgets/player_list_panel/team_player_list_panel.dart:109-136` (`_buildFixedHeightLayout`) which uses a `Column` with the team boxes as the LAST children after the player list.

**Rule:** in Team + Manual mode wireframes, the player-panel body is `flex-direction: column`. Inside (top → bottom): (a) header row with count + ADD PLAYER button; (b) scrollable player list with `max-height: ~160-180px` so it doesn't push team boxes off-screen; (c) "Assign Teams" caption (Boogaloo 14pt with 4-corner text-shadow); (d) the row of 4 team-assignment boxes as `display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; flex-shrink: 0`. The panel body uses `overflow: visible` so children aren't clipped.

**How to apply:** Phase 2 Stage D Team+Manual prompt template includes this layout explicitly. AR-2 grep: in any `menu_team_manual_*p.html`, `grep -c '"player-panel-body"' file | column-flex` must match. AR-4 grep on the Phase 4 menu screen: `grep -c 'crossAxisAlignment.*start\|Column(' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart` near the player-panel block must show a single-column structure.

---

### 47. Team-assignment box content: ONLY crest + player count (no team name, no player-name chips)
Initial Tiki Golf team boxes contained crest + team name + a list of player-name chips. Reviewer wanted: just the crest (focal point) + a count caption ("N players"). Player NAMES live on the player tiles as trailing team-crest icons — that's the Target Tag-style visual mapping between players and teams.

**Rule:** each team-assignment box in Team+Manual mode contains ONLY:
- Team crest (~56–64 px circular)
- Player count caption: "N players" (Boogaloo 14pt Sand White with 4-corner text-shadow)

DO NOT render the team name text inside the box. DO NOT render player-name chips inside the box. When a player is selected AND assigned to a team in Manual mode, the team's crest renders as a SMALL trailing icon on the player tile in the main player list — that's the only place where the player-to-team mapping is visible.

Box CSS pattern:
```css
.team-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 6px;
  border: 1px solid rgba(255,255,255,0.20);
  border-radius: 8px;
}
.team-crest-large { width: 56px; height: 56px; border-radius: 50%; overflow: hidden; }
.team-player-count { font-family: var(--font-display); font-size: 14pt; color: var(--sand-white); text-shadow: <4-corner outline>; }
```

**How to apply:** Phase 2 Stage D Team+Manual prompt template specifies this layout. Phase 4 menu-screen sub-agent renders the actual widget the same way; the TeamPlayerListPanel widget's `_buildTeamAssignmentBoxes` (`team_player_list_panel.dart:613`) already follows this convention internally. AR-2 review: in any `menu_team_manual_*p.html`, `grep -c '"team-name\|"team-player-chip' file` must be 0 in the HTML (CSS definitions kept as `display: none` for backward compatibility are fine).

---

### 48. Mode-dependent maxPlayers cap — solve in Phase 0, surface to Phase 4
Tiki Golf specs `maxPlayers: 16` for the `TeamPlayerListPanelConfig.tikiGolf()` but Solo mode caps at 4 and Team mode caps at 16. The default widget reads a single `config.maxPlayers` for the count chip ("N/16 selected") which is wrong in Solo. This is a recurring spec/widget mismatch for any game whose Solo and Team modes have different caps.

**Rule:** when the spec has different player-count caps per mode (Solo vs Team), surface it in the Phase 0 build plan as a Phase 4 implementation decision. Two valid implementation paths:
- **Preferred:** add `maxPlayersSoloMode: <N>` to `TeamPlayerListPanelConfig`; the widget reads the mode-appropriate value for the header count chip + `selectPlayer(maxPlayers:)` call.
- **Alternative:** menu screen overrides the cap via a screen-level intermediary that gates `selectPlayer` based on the current mode flag.

Wireframes must show the mode-appropriate cap in the count chip: `N/4 selected` in Solo wireframes, `N/16 selected` in Team wireframes. The asset_paths.md manifest captures the implementation decision so Phase 4 picks it up.

**How to apply:** Phase 0 Step 8 spec-extraction adds: "Player-count caps per mode — extract from Overview / spec Section 1 / Section 7. If Solo and Team caps differ, record both AND record the implementation-path decision (config-knob preferred) in the asset_paths.md manifest." AR-3 gains: verify the count-chip rendering path reads the mode-appropriate cap in the menu screen unit tests.

---

### 49. Team gameplay screen: transparent Teams panel; logo + score only; no team names
Tiki Golf spec Section 10B described per-team boxes with team-color bg + 2px Lagoon Blue border for the active team. Reviewer wanted simpler: no boxes at all (transparent), no team names; each team shows just the crest + the running team score below it. Active team distinguished only by a left-edge accent + a faint bg tint.

**Rule:** the left-side Teams panel on the game screen (Team mode only):
- 160px wide, transparent background, no border on the panel container
- "TEAMS" header at top (optional — many specs omit this)
- One row per configured team, each row shows:
  - Team crest at 56×56 (slightly larger because it's the only visual identifier)
  - Team's running ± par score below the crest (Boogaloo 18pt Bold; Lagoon Blue under par / Sand White even / `#FF8C42` over par)
- Active team: `border-left: 3px solid var(--lagoon-blue)` + `background: rgba(0,180,216,0.10)` (slight tint). Inactive teams: `opacity: 0.60`, no other decoration.
- NO team names anywhere. NO per-team boxes/borders/bg fills.

Reference: `temp_wireframes/tiki_golf/game_team_early_8p.html` is the canonical example.

**How to apply:** Phase 2 Stage D Team gameplay prompt template includes this spec. Phase 4 menu-screen sub-agent implements the panel the same way. AR-4 audit: read the game screen and verify the Teams panel renders zero team-name text widgets (only crest + score), zero per-team Container backgrounds, only the active-team's left-edge accent.

---

### 50. Team gameplay scorecard: ONLY the current team's players (Solo-style)
Tiki Golf spec Section 10B described a multi-team scorecard with team primary rows + collapsed teammate sub-rows. Reviewer simplified: the scorecard shows ONLY the 1–4 players on the CURRENT team using the SAME layout as Solo mode. Team-level totals live in the Teams panel; the scorecard is per-player for the active team.

**Rule:** in Team mode, the game-screen scorecard renders one row per player on the currently-throwing team (max 4 rows). Headers and per-cell styling are IDENTICAL to Solo mode (H1–H9 + Total, current player's row highlighted with Lagoon Blue tint + left-edge accent + Lagoon Blue name). DO NOT render team primary rows. DO NOT render teammate sub-rows for other teams. DO NOT render best-ball-contributing dot indicators.

Above the scorecard, add a small caption naming the active team (e.g., "Sharks scorecard" Boogaloo 14pt Sand White with 4-corner text-shadow) so the user knows which team's data is shown.

**How to apply:** Phase 2 Stage D Team gameplay prompt template specifies this exact pattern. Phase 4 game-screen sub-agent builds the scorecard with a `currentTeamPlayerIds` selector and renders one row per id. AR-4 audit: `grep -c 'team-primary-row\|team-sub-row' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart` must be 0 (no nested team/sub-row rendering); the scorecard structure matches Solo.

---

### 51. Team results screen: 2-column team-blocks + internal-scroll scorecards
Tiki Golf spec Section 10C described a single wide scorecard. Reviewer wanted: each team gets its own mini-scorecard block, blocks arranged in 2 columns (4 teams → 2+2, 3 teams → 2+1, 2 teams → 1+1, 1 team → centered). Plus the scorecards area must scroll internally so the action buttons stay visible at the bottom of the 1366×768 viewport.

**Rule:** team-mode results screen replaces the single wide scorecard with a 2-column team-blocks layout. Each team-block contains:
- Team crest 64×64 at the top
- Team name caption below (Boogaloo 16pt Sand White; Lagoon Blue for the winning team)
- Mini-scorecard table (headers + per-player rows + a best-ball total footer row)
- Winning team's block has a `border: 2px solid var(--lagoon-blue)` and Lagoon Blue team total

**Distribution rule:** left-to-right, 2 teams per column when possible.
- 4 teams → col1: Teams 1+2; col2: Teams 3+4
- 3 teams → col1: Teams 1+2; col2: Team 3
- 2 teams → 1 per column
- 1 team → single-column centered

**Scroll rule:** wrap the team-blocks columns in a `.scorecards-scroll` container with `flex: 1; min-height: 0; overflow-y: auto`. The action buttons sit OUTSIDE this container (last child of `.main-area`) with `flex-shrink: 0` so they stay pinned at the bottom of the canvas. Winner card stays at the top with `flex-shrink: 0`.

**Heading text:** "GOLDEN TIKI CHAMPIONS!" (plural — team mode) vs "GOLDEN TIKI CHAMPION!" (singular — solo). The Dart screen branches on `gameMode` to pick the right text. Pluralize equivalents for non-golf games (CHAMPS / WINNERS / etc.).

**How to apply:** Phase 2 Stage D Team results prompt template includes the 2-column distribution rule + the scrollable container. Phase 4 results-screen sub-agent renders the same structure. AR-4 audit: `grep -c '"scorecards-scroll\|overflow-y' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart` ≥ 1 in team-mode branch; action buttons live in a Row that is a sibling of (not nested inside) the scroll container.

---

### 52. Random N-of-M team-crest selection — wireframe varies, Phase 4 implements
When a spec calls for "N team crests picked at random from a pool of M" (M > N), this is a runtime randomization akin to Reef Royale's creature shuffle.

**Rule for wireframes (Phase 2 Stage D):** pick N specific crests for the wireframe to demonstrate one valid distribution. Don't always use the first N from the spec — vary across mode-variant files so a reviewer sees that any random subset is valid. Include a code comment near the team-crest rendering: `<!-- In production, N of the M available crests are randomly picked per game; this wireframe shows one such pick. -->`. Capture the random-pick rule for Phase 4 in `temp_wireframes/<game>/asset_paths.md`.

**Rule for Phase 4 implementation:** the provider's game-construction (model factory) calls `crests..shuffle(Random())..take(N)` and stores the picked list on the game model (e.g., `List<String> teamCrestPaths` length N, frozen after construction). Resume restores the same list from saved-game JSON. Mirror Reef Royale's `lib/models/reef_royale_game.dart:206-236` creature-assignment pattern.

**How to apply:** Phase 2 Stage D prompt template includes the random-pick wireframe convention. Phase 3 model+provider prompt cites the shuffle pattern. Non-UI test for the model: "two consecutive constructions produce different `teamCrestPaths` ordering across N≥20 fresh games (statistical sanity)" — same approach as Reef Royale Random Reefs test #38.

---

### 53. Random team-distribution table — full-table coverage tests are mandatory
Tiki Golf's spec Section 5 defines a deterministic `randomDistribution(N)` table mapping selected-player count → team count + sizes, with special-case rules (N=8 → [4,4] instead of [2,2,2,2]; N≥12 → T=4). Naive heuristics ("minimize team count" or "minimize team size") do NOT reproduce the table.

**Rule:** any game whose Team-mode spec defines a deterministic team-count + sizes table from player count MUST:
1. Implement the function as `randomDistribution(int N)` (or equivalent) in the provider returning `{int teamCount, List<int> sizes}`
2. Author a full-table non-UI test that iterates every N in the spec's table and asserts the returned (team count, sorted-sizes multiset) matches the spec row exactly
3. Author a UI test (in `integration_test/<game>/team_setup_test.dart` or equivalent) that for every N in the table: selects N players, taps TEE OFF in Random mode, then asserts the resulting team count + sorted sizes match the spec
4. Hard-code every special-case row explicitly in the algorithm (don't rely on a single heuristic to produce the table)

**How to apply:** Phase 3 prompt template adds a mandatory "Random Distribution Coverage" test group. AR-3 audit reads the spec table, counts rows, verifies the non-UI test file iterates all rows. AR-6 audit verifies the UI test file iterates all rows.

---

### 54. Shared TeamAssignmentDialog already exists — wire keys, don't reinvent
The Target Tag implementation of `TeamAssignmentDialog` at `lib/widgets/player_list_panel/team_assignment_dialog.dart` is already shared infrastructure for Team+Manual mode. The TeamPlayerListPanel widget calls into it directly via `_showTeamSelectionDialog`. Any new Team-mode game reuses this dialog wholesale — there's no game-specific TeamAssignmentDialog config factory required.

**Rule:** in Phase 4 menu screen, wire the dialog's keys through `TeamPlayerListPanel` parameters:
- `teamDialogContainerKey: [GAME_NAME_PASCAL]MenuKeys.teamDialogContainer`
- `teamDialogDropdownKey: (id) => [GAME_NAME_PASCAL]MenuKeys.teamDialogDropdown(id)`
- `teamDialogCancelKey: [GAME_NAME_PASCAL]MenuKeys.teamDialogCancel`

Add these three keys to `[GAME_NAME_PASCAL]MenuKeys` in `lib/constants/test_keys.dart`. Do NOT author a new dialog. Do NOT create a `TeamAssignmentDialogConfig.[gameName]()` factory method.

**How to apply:** Phase 4 prompt template under "Create config factory methods" already lists every shared widget config method — explicitly exclude `TeamAssignmentDialogConfig` from the list for Team-mode games (only the keys need to be added). AR-4 audit: verify the keys are wired correctly when `_isManualTeamMode == true`.

---

### 55. Invisible-placeholder pattern for "neighbor previews" of the current item
When a UI shows "neighbors of the current item" (e.g., Tiki Golf's previous/next hole previews on the gameplay screen, or any future game that previews adjacent pieces/positions/players), use invisible-but-width-preserving placeholders for slots without valid neighbors. This keeps the central item stationary as the user progresses through the list, instead of shifting horizontally when previews appear/disappear at the edges.

**Rule:** for any "current item ± N neighbors" UI:
```css
.item-preview { display: flex; align-items: center; flex-shrink: 0; }
.item-preview.outer { width: 140px; }
.item-preview.inner { width: 182px; }   /* +30% from outer per Tiki Golf precedent */
.item-preview.empty {
  visibility: hidden;                    /* preserves layout width but renders nothing */
}
```

Empty placeholders match the natural slot width (outer vs inner) so the row's flex distribution doesn't shift. Use `align-items: center` for vertical-center alignment of neighbors against the (larger) central item. Use `justify-content: space-between` for screen-spanning distribution.

**How to apply:** Phase 2 Stage B / Phase 4 game-screen prompt templates cite this pattern when the spec includes neighbor previews. AR-4 audit: read the game screen and verify empty-slot Container widths match valid-slot Container widths so the central item stays centered.

---

### 56. Menu option boxes: label-left + control-right on one row, vertically centered
Past games and the Tiki Golf v1 build laid out each settings-grid option box as a vertical `Column[Label, SizedBox(8), ControlRow]` with `minHeight: 110`. The user consistently asked for this to be redone as a one-row layout: label on the left, control on the right, vertically centered inside the box. The minHeight constraint also reads as too tall.

**Rule:** every option box in the menu screen settings grid renders as `Row(MainAxisAlignment.spaceBetween, crossAxisAlignment.center, [Label, Control])`. The outer box is a `Container(padding: 12h/8v)` with the box's background/border. Wrap the Row in `Center(child: ...)` so the content is vertically centered inside the box. DO NOT set a fixed `minHeight` — let the box size to its content. All boxes in a row will naturally share the same height via `IntrinsicHeight(Row(Expanded(box)...))` on the parent.

**Canonical pattern:**
```dart
Widget _buildSettingsBox({required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(/*bg + border + radius*/),
    child: Center(child: child),  // vertically center label + control
  );
}
// Each box content:
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [Text('Label', style: labelStyle), controlWidget],
)
```

For boxes with a conditional secondary control (e.g., team-count dropdown that only appears in a sub-mode), prefer to omit the secondary entirely (Rule §67) rather than nest it in the box.

**How to apply:** Phase 4 menu-screen sub-agent prompt template — add this as the canonical option-box layout. AR-4 audit greps: each `_buildXxxBox` method must contain `MainAxisAlignment.spaceBetween` AND `crossAxisAlignment: CrossAxisAlignment.center` somewhere in the Row, AND must NOT contain `minHeight:` in the SettingsBox wrapper.

---

### 57. Menu option label and control text should be within 2pt of each other
Tiki Golf v1 had labels at 14pt and toggle text at 14pt; after the polish iteration the user wanted labels at 22pt and toggle/dropdown text at 20pt — a 2pt hierarchy difference. Old versions with 6-8pt size differences between label and control read as inconsistent.

**Rule:** in the settings grid, option labels (e.g., "Game Mode", "Max Strokes", "Mulligan") and their controls' visible text (toggle segment text "SOLO"/"TEAM", dropdown selected value, toggle on/off labels) should be within 2pt of each other. Labels can be the slightly larger of the two for hierarchy.

**Recommended sizes for menu screens using display fonts (Boogaloo/Bangers/Rye):**
- Option label: 22pt
- Toggle segment text + dropdown text: 20pt
- Toggle on/off labels (OFF / ON): 20pt
- Inline subtitle (e.g., "1 do-over per player" in parens): 14pt Nunito (Rule §66)

For games using more neutral display fonts, use the same 22/20 split and tune visually.

**How to apply:** Phase 4 menu-screen sub-agent prompt template defaults to label 22 / control 20. AR-4 audit: every menu-screen option-box file should have label fontSize and control fontSize within 2pt of each other.

---

### 58. How-To-Play / left panel: top-align with the first option row (don't stretch full-height)
By default a `Row` with `crossAxisAlignment: stretch` (the default for many layouts) makes both columns fill the parent's height. The how-to-play panel on the left then stretches to canvas height, while the right panel's first option row starts at `y = padding-top`. The visible top of the green container ends up ABOVE the visible top of the first option box — visually jarring.

**Rule:** the menu's main-content Row uses `crossAxisAlignment: CrossAxisAlignment.start`, so the left panel doesn't auto-stretch. Wrap the left panel in `Padding(EdgeInsets.only(top: <right-panel-padding-top>, left: <small-left-inset>))` so the green container's top edge aligns with the first option box's top edge.

**Canonical pattern (Tiki Golf reference):**
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start, // top-align both columns
  children: [
    SizedBox(
      width: constraints.maxWidth * 0.437,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16),
        child: _buildLeftPanel(),
      ),
    ),
    Expanded(child: _buildRightPanel(...)),
  ],
);
// _buildLeftPanel is a Container with EdgeInsets.all(16) padding so its
// content has the same equal top + bottom inset.
```

**How to apply:** Phase 4 menu-screen sub-agent prompt template specifies this. AR-4 audit: confirm `crossAxisAlignment: start` on the menu's main-content Row AND a Padding wrapper on the left panel sized to match the right panel's padding-top.

---

### 59. Horizontal gap between left and right panels — 8px sweet spot (16px is too generous)
Tiki Golf v1 used `EdgeInsets.all(16)` on the right panel, which combined with the left panel's right edge gave a visible 16px gap between the two panels. The user asked for that gap to be halved.

**Rule:** the right panel uses asymmetric padding `EdgeInsets.fromLTRB(8, 16, 16, 16)` (8px on the left side facing the left panel; 16px on the other three sides). This halves the inter-panel gap while preserving the visible right and bottom margins.

**How to apply:** Phase 4 menu-screen sub-agent prompt template specifies this for the right panel container. AR-4 audit: read the right panel's outer Container `padding` and confirm `fromLTRB(8, 16, 16, 16)` (or equivalent asymmetric with `left < right`).

---

### 60. Right-panel section gaps — 8px between sections (16px reads too airy)
Tiki Golf v1 had `SizedBox(height: 16)` between settings-grid ↔ player-panel and between player-panel ↔ TEE-OFF button. The user wanted these halved.

**Rule:** the vertical gaps between major sections inside the right panel (settings grid, player panel, primary button) default to **8px**. Use 16px only when there's a deliberate visual-break reason (e.g., separating ungrouped content categories).

**How to apply:** Phase 4 menu-screen sub-agent prompt template specifies `SizedBox(height: 8)` between sections. AR-4 audit: grep `SizedBox(height: 16)` in the menu screen — should appear only inside the left panel (between How-To-Play headers and body) if at all.

---

### 61. TeamPlayerListPanel header indent: use the `headerPadding` config, NEVER wrap the panel in Padding
The `TeamPlayerListPanel` widget returns `Expanded(child: Column(...))` when `useFixedHeight: false`. `Expanded` requires a **direct** Flex (Row/Column) parent — any intermediate widget (Padding, Container, Transform, Align) between Expanded and its Flex parent triggers `Incorrect use of ParentDataWidget` at runtime. This bit the Tiki Golf build twice during the polish iteration.

**Rule:** to indent the player panel's HEADER (the "Available Players" label + count chip + ADD PLAYER button) relative to the panel's list rows, use the shared widget's `headerPadding: EdgeInsetsGeometry?` config field. The widget wraps `_buildHeader`'s Row in a Padding only when the field is set. **DO NOT wrap `TeamPlayerListPanel` itself in any non-Flex widget** (Padding, Container with margin, Align, Transform, etc.) — it will break at runtime when `useFixedHeight: false`.

If you need to indent the entire panel (rows AND header), you have two options:
- Set `useFixedHeight: true` (returns Column, not Expanded — Padding wrapping then works) AND override the panel's `soloListHeight` / `teamListHeight` so the content fits in the available vertical space.
- OR change the menu screen's outer right-panel padding so the entire right-panel content shifts inward.

**Canonical pattern (Tiki Golf reference):**
```dart
// In <Game>PlayerListPanelConfig factory:
headerPadding: const EdgeInsets.symmetric(horizontal: 12),

// In the menu screen — DO NOT do this:
//   Padding(child: TeamPlayerListPanel(useFixedHeight: false, ...))  ← runtime crash
// Just pass the panel directly:
TeamPlayerListPanel(config: <Game>PlayerListPanelConfig.<game>(), useFixedHeight: scrollable, ...)
```

**How to apply:** AR-4 audit greps `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart` for `Padding` wrapping `TeamPlayerListPanel(`. Any such match is a runtime-crash risk — replace with `headerPadding` (header-only indent) or `useFixedHeight: true` (whole-panel indent via outer wrapper).

---

### 62. Suppress the "Team Assignment" label above team boxes when it's redundant
By default the shared `TeamPlayerListPanel` renders the `config.teamAssignmentLabel` text ("Assign Teams" or similar) above the team-assignment boxes in Manual mode. When the team-badge images themselves clearly communicate "these are the teams", the label is redundant and just adds vertical space.

**Rule:** the shared config has `showTeamAssignmentLabel: bool` (default true). Games where the team badges are self-explanatory should set it to `false`. When false, both the label AND its surrounding 16px/8px SizedBox spacers are skipped.

**How to apply:** Phase 4 menu-screen sub-agent prompt template includes the option. AR-4 audit: for any new game with team mode, surface to the user during build review: "should the 'Team Assignment' label above the team boxes be hidden?" — set `showTeamAssignmentLabel: false` if the user says yes.

---

### 63. Allow team-box chrome to be transparent for a clean badges-only look
The shared `TeamPlayerListPanel` wraps each team crest in a `Container` with `teamBoxBackgroundColor` + `teamBoxBorderColor` + `teamBoxActiveBorderColor`. These add visual chrome around each badge. For games where the crest images are detailed enough to stand on their own (e.g., circular crests with rope borders, full-bleed images), the Container chrome competes with the artwork.

**Rule:** set all three team-box color config fields to `Colors.transparent` to render the badges with no container chrome. The active-team visual cue can come from other places (a left-edge accent on the active team's parent row, a glow on the badge image via `BoxShadow` or `ImageFiltered`, or a 2px translucent border via a different config) — see Rule §49 for the canonical Teams-panel transparent treatment.

**Canonical pattern (Tiki Golf reference):**
```dart
teamBoxBackgroundColor: Colors.transparent,
teamBoxBorderColor: Colors.transparent,
teamBoxActiveBorderColor: Colors.transparent,
teamBoxSize: 84.0,   // can size larger when no chrome competes
```

**How to apply:** Phase 4 prompt template suggests this for games where the crests are visually self-sufficient. AR-4 audit: when reviewing the team-mode setup screen, the user should be asked "do the team-box backgrounds and borders feel necessary?" — if no, set all three to transparent.

---

### 64. Heavy-descender display fonts (Boogaloo, Bangers, etc.) need line-height tightening on home-card labels
Boogaloo, Bangers, and similar handwritten/casual display fonts have heavier descenders than the more uniform fonts used by other games (Fredoka, Luckiest Guy, Cinzel, etc.). On the home-screen game card, the label's baseline sits visually lower than peer-game labels — the descender pushes the rendered text down within its line box, even when the SizedBox spacer above is shrunk.

**Rule:** for games using Boogaloo, Bangers, Pirata One, or other heavy-descender display fonts on the home-screen card, apply BOTH of these tweaks to align the label baseline with peer games:
1. Reduce the SizedBox between the icon and the label (default 8px → 3px for Boogaloo, 6px for Pirata One)
2. Tighten the TextStyle line-height with `height: 0.6` (or similar < 1.0) to compress the line box and shift the rendered glyphs up

**Canonical pattern (Tiki Golf reference):**
```dart
// In the SizedBox conditional in home_screen.dart:
height: title == 'Tiki Golf' ? 3 : <peer-game-default>,
// In the TextStyle conditional:
GoogleFonts.boogaloo(
  fontSize: <size>,
  fontWeight: FontWeight.bold,
  color: ...,
  height: 0.6,   // tightens the line-box so text sits higher
),
```

**How to apply:** Phase 4 home-card sub-agent prompt template includes this tweak for any game whose Style section uses a heavy-descender font. AR-4 audit: open the home screen at full resolution and verify the game's label baseline visually aligns with at least 2 peer-game labels (or the user reports it does).

---

### 65. AppBar title size for branded display fonts — 28-34pt (default 20pt is too small)
Default Material AppBar `titleStyle` is ~20pt. For games that use a branded display font (Boogaloo, Bangers, Cinzel, Rye, Pirata One) for the AppBar title, 20pt reads as cramped and undersells the game's visual identity. The user consistently asked Tiki Golf's titles bumped from 20pt → 28pt → 34pt over multiple iterations.

**Rule:** for the AppBar title on EVERY new game's three screens (menu / game / results), use **28-34pt** when the spec uses a branded display font. Pick a size by font weight:
- Heavier display fonts (Bangers, Pirata One, Rye): 28pt
- Medium-weight display fonts (Boogaloo, Cinzel, Cinzel Decorative): 32-34pt
- Light/condensed display fonts (Fredoka, Orbitron): 24-28pt

**How to apply:** Phase 4 prompt template for menu/game/results screen authors specifies the AppBar title at 28-34pt by default. AR-4 audit: read the three AppBar titles and verify fontSize ≥ 24 when the font is a Google Fonts display font.

---

### 66. Inline parenthetical subtitle (RichText) instead of below-row subtitle
When an option box needs a one-line clarifying subtitle (e.g., "Mulligan" with "1 do-over per player"), the user prefers the subtitle inline next to the label as a smaller parenthetical, rather than on a separate row below the option's primary row. The inline pattern keeps the box height matching the other options' boxes.

**Rule:** for option boxes that need a clarifying subtitle, use `RichText` with two TextSpans:
- Primary label at the full option-label size (e.g., 22pt Boogaloo)
- Parenthetical subtitle at a smaller body-font size (e.g., 14pt Nunito with 0.75 opacity)

**Canonical pattern (Tiki Golf Mulligan box reference):**
```dart
Flexible(
  child: RichText(
    overflow: TextOverflow.visible,
    text: TextSpan(children: [
      TextSpan(
        text: 'Mulligan ',
        style: GoogleFonts.boogaloo(fontSize: 22, color: ..., shadows: ...),
      ),
      TextSpan(
        text: '(1 do-over per player)',
        style: GoogleFonts.nunito(fontSize: 14, color: ...withOpacity(0.75)),
      ),
    ]),
  ),
),
```

DO NOT use a separate Column[PrimaryRow, SizedBox, SubtitleText] — that makes the box taller than its peers in the same settings row.

**How to apply:** Phase 4 menu-screen sub-agent prompt template suggests this pattern when a spec includes per-option clarifying text. AR-4 audit: any option box with both a primary label and a clarifying subtitle should use RichText inline, not Column + Text below.

---

### 67. Inline secondary controls — consider removing them entirely if a sensible default exists
Tiki Golf v1 had a "Teams: [4 ▾]" inline dropdown inside the Game Mode option box, shown only in Team + Manual mode. The user removed it entirely, accepting a default of 4 teams. The control was visually noisy and added little value when the user can always manage team membership by which slots they fill.

**Rule:** for inline secondary controls that appear conditionally (only in a sub-mode) AND have a sensible default value AND can be worked around via other UI (e.g., the user picks team assignments which implicitly determines team count), surface to the user during build review: "is this secondary control needed, or should we default it and remove the UI?" Often the answer is "remove" — fewer controls = cleaner menu.

When removing: KEEP the underlying state variable in the screen (it's still used downstream by the provider/game) and DEFAULT it to a sensible value. Just remove the UI that exposed it.

**How to apply:** Phase 4 prompt template, when authoring an option box that has a conditional secondary control inside it, instructs the sub-agent to flag the secondary control as a removal candidate. AR-4 audit: when the user is reviewing the menu screen visually, ask if any conditional secondary controls feel necessary; remove them if the answer is no.

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
1. Sub-agent must update BOTH `test/shared/` AND `integration_test/shared/` for every helper that exists in both directories. Verify with `diff -rq integration_test/shared test/shared 2>&1 | grep "differ"` — must return empty. Files present in only one directory (e.g. `mock_api_helpers.dart`, `player_test_utils.dart`, `sector_parser.dart` in `test/shared/` only) are intentionally non-mirrored and excluded.
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
