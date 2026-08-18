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

## STEP ZERO: check for an interrupted build

Before reading anything else, check for
`temp_build_state/[GAME_SNAKE]/build_state.json`.

**If it exists, this is a RESUME.** Do not start over.

1. Read it. Re-verify each recorded gate with its cheap check — the branch
   exists, the recorded files exist, `flutter test` passes for the game's test
   directories. A gate that no longer verifies is downgraded to not-done.
2. Print a resume report: phase and step reached, gates verified vs downgraded,
   user approvals already given, and (if in Phase 8) the open-issue list with
   per-issue fix attempts.
3. Confirm the resume point with the user, then continue from there.

Restarting a build that got to Phase 7 wastes hours and re-asks approvals the
user already gave. The state file exists so that never happens; the only reason
to ignore it is if the user explicitly asks for a clean rebuild (in which case
delete the directory first).

If no argument is provided, ask the user for the spec file path.

$ARGUMENTS

---

# PIPELINE: 12 Phases (0–11), 7 Gates (5 Hard + 2 Approval), 10 Adversarial Reviews

You MUST execute phases in order. You MUST NOT skip phases. You MUST NOT proceed past a gate until it passes. You MUST execute every adversarial review checkpoint and report the findings before continuing.

At the start of each phase, print:
```
=== Phase X of 11: [Phase Name] ===
Gates passed: X/5 (+ X/2 approvals) | ARs completed: X/10
```

---

## Model Strategy (Multi-Tier Architecture)

This skill runs as an **orchestrator** on the parent model (intended
to be Opus) and delegates work to a **tiered fleet** of sub-agents
via the Agent tool, plus optional deterministic multi-agent
pipelines via the Workflow tool. Choose the tier that fits the
stage; do NOT burn Opus tokens on mechanical work, and do NOT put
Sonnet on cross-cutting judgment.

**See `reference/playbook.md`** for the concrete patterns (Workflow orchestration, adversarial
+ perspective-diverse verify, judge panel, prior-art briefing,
worktree isolation, structured output schemas, background UI runs,
corrective re-audit rule, Artifact dashboards, Python font tool,
Definition-of-Done schema). Every `[Playbook §N]` reference in this
skill and in the phase files points into that file.

### Tier reference

> **`effort` is NOT an Agent-tool parameter.** The Agent tool takes
> `model`, `subagent_type`, `isolation`, `run_in_background` and
> `prompt` — nothing else. `effort` exists only on `agent()` INSIDE a
> Workflow script. Where a tier below names an effort level, that
> applies when the stage runs inside a Workflow; a plain `Agent` call
> gets the model's default. Passing `effort` to the Agent tool is an
> input-validation error, not a silent no-op.

- **Tier 0 — Orchestrator (this thread — Opus):** every phase
  decision, every gate decision, "fix code or update tests?"
  judgment, all AR synthesis, root-cause analysis. Never delegated.
- **Tier 1 — Opus sub-agent (`{model: 'opus'}`):** independent AR
  verification, adversarial-verify skeptics (3× parallel), Phase 8
  Step 2 perspective-diverse visual-review lenses (3× parallel),
  Phase 2 Stage A wireframe judge, cross-file semantic critique. Use
  when INDEPENDENCE + judgment quality matter more than cost.
- **Tier 2 — Sonnet sub-agent (`{model: 'sonnet'}`), high effort where
  the stage runs in a Workflow:** test-smell reviewer, prior-art
  briefing synthesis, hard structural refactors. Reasoning that Sonnet
  CAN do, but only when it is given room.
- **Tier 3 — Sonnet sub-agent (`{model: 'sonnet'}`), default:** most
  implementation work (screens, providers, UI test files, wireframe
  HTML/CSS, announcement helpers, save/restore serialization). The
  workhorse.
- **Tier 4 — Sonnet sub-agent, low effort inside a Workflow:** simple
  grep-audit stages in AR-4 pipelines, structured-data extraction from
  prose reports, pubspec updates. Cheapest useful tier. As a plain
  Agent call this is just Tier 3; consider `{model: 'haiku'}` instead
  for genuinely mechanical greps.
- **Tier 5 — `Explore` agent type (`subagent_type: 'Explore'`):**
  read-only surveys — prior-art discovery, spec section maps, "which
  existing games use pattern X?", cross-game code recon. Ships with
  its own optimized model choice; do NOT specify one.

### Structural tools

- **Workflow tool — REQUIRES EXPLICIT USER OPT-IN.** A workflow can
  spawn dozens of agents and spend a large number of tokens, so it may
  only be launched when the user has actually asked for it (the
  keyword "ultracode", "use a workflow"/"fan out agents" in their own
  words, or a skill they invoked that says to). Do NOT start one just
  because a stage below would benefit. If a phase would be materially
  better as a workflow, say so, give a rough cost, and ask.
  When opted in: replace serial multi-item work (AR-4's 34 checks,
  Phase 4's 3 screen files, Phase 7's UI-test subdirectories) with a
  `pipeline([items], stage1, stage2)` that streams items through
  stages without a barrier. Reserve `parallel(thunks)` for barriers
  where dedupe / synthesis genuinely needs ALL results together.
- **Plain fan-out without a Workflow:** issue several `Agent` calls in
  ONE message and they run concurrently. This is the default way to
  parallelise (Phase 8 STEP 2's three review lenses, Step 7B's
  coverage-audit sources) and needs no opt-in.
- **`isolation: 'worktree'`:** for parallel sub-agents that all
  MUTATE files (Phase 2 judge-panel wireframe authors, Phase 4
  parallel screen authors). Each agent gets its own worktree; the
  orchestrator merges the winning branch back.
- **Structured output schemas:** `agent(prompt, {schema: FINDINGS_SCHEMA})`
  forces a typed return. Every AR sub-agent returns
  `{items: [{row, status: 'PASS'|'FAIL', evidence, file, line}]}`
  for deterministic aggregation.
- **Artifact tool:** render an HTML dashboard for cross-game
  AR-Coverage findings (Phase 10) so the user can visually verify
  coverage in seconds.
- **`run_in_background: true`:** for 3h+ UI test runs. Fire the
  runner and keep working; a completion notification arrives when it
  exits, so there is no need to poll on a timer. `ScheduleWakeup` is
  for `/loop` self-pacing, not for waiting on a background command
  that already notifies.
- **Freeze the tree during a UI run.** `flutter drive` compiles what
  is on disk WHEN EACH FILE LAUNCHES, so editing `lib/` mid-run makes
  later files compile a half-edited codebase and produces failures
  that match nothing in the committed code. Either stop editing for
  the duration or run from a git worktree pinned to a commit — which
  is what `run_ui_tests_parallel.bat` does.

### Where each tier applies (per-phase quick reference)

| Phase | Stage | Tier |
|---|---|---|
| 0 | Spec analysis, section map, build plan | Tier 0 |
| 1 | Asset verification, pubspec, branch | Tier 3 |
| 1 | Adversarial Review AR-1 (asset spot-check) | Tier 0 |
| 2 | Wireframe Stage A (judge panel of 3 in worktrees) | Tier 3 × 3 parallel + Tier 1 judge |
| 2 | Wireframes Stages B–D | Tier 3 |
| 2 | AR-2 wireframe completeness | Tier 0 |
| 3 | Models, provider, core tests | Tier 3 |
| 3 | AR-3 options coverage | Tier 0 |
| 4 | Prior-art briefing (before authoring) | Tier 5 (Explore) |
| 4 | 3 screen files (parallel worktrees, one per file) | Tier 3 × 3 parallel |
| 4 | AR-4 Integration Audit (Workflow pipeline over 34 rows) | Tier 4 grep + Tier 1 synthesis |
| 5 | Announcement stacking design | Tier 0 |
| 5 | Sound + announcement implementation | Tier 3 |
| 5 | AR-5 stacking verification | Tier 0 |
| 6 | Serialization + save/restore tests | Tier 3 |
| 6 | Migration decision | Tier 0 |
| 7 | UI test files + shared helper sync | Tier 3 |
| 7 | Test-smell reviewer on new test files | Tier 2 |
| 7 | Spec coverage audit (loop-until-dry) | Tier 0 |
| 7 | AR-6 spec coverage matrix | Tier 0 |
| 8 | Step 0 font parity ribbons + Python analysis | Tier 3 for `flutter drive`; Tier 0 for iteration |
| 8 | Step 1 screenshot capture | Tier 3 |
| 8 | Step 2 visual evaluation (3 lenses parallel) | Tier 1 × 3 parallel |
| 8 | Step 4 fixes | Tier 3 |
| 8 | Steps 5/7 test runs | Tier 3 (`run_in_background` for long ones) |
| 8 | AR-7 visual sign-off | Tier 0 |
| 8 | AR-10 font parity | Tier 0 |
| 9 | Simultaneous pass verification | Tier 0 |
| 10 | Cross-game coverage audit | Tier 0 |
| 10 | Step 8 test authoring for gaps | Tier 3 |
| 10 | AR-Coverage (self-check + Artifact dashboard render) | Tier 0 for synthesis; Tier 4 for HTML template fill |
| 11 | Documentation, CLAUDE.md, testing docs | Tier 3 |

### Cost discipline

Every sub-agent call is billed. Rules of thumb:

- Default to Tier 3 unless the stage explicitly asks for judgment or
  independence.
- Tier 4 is 40–60% cheaper on grep-heavy audits — use it for AR-4
  pipeline stages where each stage does one `grep` + one boolean
  check.
- Tier 1 is ~4× the cost of Tier 3 per token. Reserve it for the
  ARs, judge panels, and perspective-diverse visual review — never
  for implementation.
- If you're spawning >10 agents in a phase, use Workflow's
  `pipeline()` not raw `Agent()` calls — deterministic execution and
  concurrency capping.
- Set `effort: 'low'` explicitly on obviously-simple stages; the
  runtime will save money.

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

### Universal Rule: AppBar Title Naming Convention

**This rule MUST be embedded in every sub-agent prompt that authors game screen files.**

Every game's three screen AppBar titles follow a fixed naming pattern.
Preserve the game's chosen case (ALL CAPS vs. Title Case) — don't
change how a game presents its own name — but the trailing phrase
IS standardized:

- **Menu screen** → `[Game Name] Game Setup`
  - ALL CAPS: `TIKI GOLF GAME SETUP`, `TREASURE DIVIDE GAME SETUP`, `CLOCKWORK QUEST GAME SETUP`
  - Title Case: `Carnival Derby Game Setup`, `Reef Royale Game Setup`, `Monster Mash Game Setup`

- **Gameplay screen** → `[Game Name]` OR a themed phrase
  - The gameplay title is game-flavored; it may be just the game name
    (`CLOCKWORK QUEST`, `PIRATE'S GRID`, `LUNAR LANDER`) OR add a
    themed phrase (`Carnival Derby Race`, `Target Tag Game On!`,
    `It's Monster Mashin' Time!`). Either is allowed; the spec
    dictates.

- **Results screen** → `[Game Name] Results`
  - ALL CAPS: `GLADIATOR ARENA RESULTS`, `TIKI GOLF RESULTS`, `TREASURE DIVIDE RESULTS`
  - Title Case: `Monster Mash Results`, `Reef Royale Results`, `Target Tag Results`
  - **NOT** `[Name] Game Over`, `[Name] Race Results`, or any other
    variant — those existed historically and were normalized to
    `[Name] Results` on 2026-07-11.

**All three titles must use IDENTICAL font family, fontSize, font
weight, letterSpacing, color, and shadow spec** — the ONLY diff
between menu / gameplay / results title `Text(...)` widgets is the
title string itself. Per-game visual details (Transform.translate
nudges for optical centering, shadow color) MUST also be applied
consistently across all three screens.

**Casing rule:** whatever case the game uses for its home-card label
(from `home_screen.dart`), it MUST use the SAME case in all three
AppBar titles. E.g. Monster Mash's home card says "Monster Mash" so
its AppBar titles are `Monster Mash Game Setup` / `Monster Mash
Results` (Title Case), NOT `MONSTER MASH GAME SETUP`.

**Test-string sync:** if the new game's UI tests reference the
AppBar title in any `find.text(...)` or `find.textContaining(...)`
assertion, those strings must exactly match the conventions above.
Any pre-existing test that hardcodes an older format is a bug to
fix as part of the naming pass — not an excuse to keep the old
title.

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

---

## Phase index — READ THE PHASE FILE BEFORE STARTING A PHASE

Each phase lives in its own file so this one stays readable. The phase
files are NOT optional reading and NOT summaries: they contain the
steps, the gates and the adversarial reviews. Read
`phases/phase-NN.md` when you reach phase NN, in full, before doing
any of its work.

| Phase | File | What it covers |
|---|---|---|
| 0 | `phases/phase-00.md` | Initialization and Spec Analysis |
| 1 | `phases/phase-01.md` | Asset Setup |
| 2 | `phases/phase-02.md` | Wireframe Mockups (Staged Approval) |
| 3 | `phases/phase-03.md` | Core Game Logic |
| 4 | `phases/phase-04.md` | Screens, UI, and Play-to-Complete |
| 5 | `phases/phase-05.md` | Announcement and Sound System |
| 6 | `phases/phase-06.md` | Save/Resume and Data Migration |
| 7 | `phases/phase-07.md` | UI Automation Tests, Spec Coverage Audit, and Mandatory Coverage |
| 8 | `phases/phase-08.md` | Visual Validation |
| 9 | `phases/phase-09.md` | Simultaneous Pass Verification |
| 10 | `phases/phase-10.md` | Cross-Game Test-Coverage Audit |
| 11 | `phases/phase-11.md` | Documentation and Definition of Done |

### Reference files

Read these when the phase that needs them says so.

| File | When |
|---|---|
| `reference/build-quality-rules.md` | **Before Phase 1, and again before every gate.** The accumulated rules and the NEVER list. |
| `reference/layout-constants.md` | **Phase 4, immediately after the screens are authored — the Layout Lint step.** |
| `reference/error-handling.md` | When any step fails or a gate is at risk. |
| `reference/font-parity.md` | Phase 8 Step 0 / AR-10. |
| `reference/playbook.md` | Every `[Playbook §N]` reference in any phase file. |

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
ARs completed:         10/10
```

Ask the user: "Would you like me to commit and create a PR?"

(Per `docs/deployment/git-workflow.md` and the universal hard rule in every sub-agent prompt: NEVER commit to master/main and NEVER push to remote without explicit user permission.)

---

---
