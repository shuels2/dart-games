<!-- game.build Phase 0 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

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
7. **Build the spec section map.** Grep the spec for `^#{2,3} ` headings — **NOT** `^## \d+\.` — and produce a table mapping the heading text → the actual section number for THIS spec.

   > **Why the looser pattern.** Two spec templates are in circulation. The
   > modern one has `## 14. Definition of Done` (a numbered H2). The legacy one
   > nests `### Definition of Done` inside §14 as an UNNUMBERED H3, which
   > `^## \d+\.` cannot see. 13 of the 27 specs in `docs/research/games/` are
   > the legacy shape. When the section map misses the Definition of Done,
   > **Gate 5 silently degrades to verifying nothing and the build still
   > reports success.** `test/meta/spec_lint_test.dart` enforces this and
   > enumerates the current offenders.

   Required entries:
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
   - "Definition of Done" — at EITHER heading level. If the spec has
     none at all (9 specs do not), say so explicitly in the Phase 0
     report and treat Gate 5 as BLOCKED rather than passed.
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
9b. **Write the build-state file** — `temp_build_state/[GAME_SNAKE]/build_state.json`.
    TaskCreate state is session-scoped; this file is not. A crashed or
    compacted session that cannot read this file has to restart from Phase 0,
    which is how a half-built game gets rebuilt from scratch.

    ```json
    {"game": "candy_cascade",
     "branch": "candy-cascade-dev",
     "spec": "docs/research/games/tier1/candy-cascade.md",
     "section_map": {"Game Options & Settings": 7, "Screen Designs": 10},
     "phase": 4,
     "step": "AR-4",
     "gates": {"gate1": "PASS@<sha>", "gate1_5": "PASS@<sha>"},
     "approvals": {"phase0": true, "stageA": true, "stageB": false},
     "phase8": {"cycle": 0, "screenshots_clean": [], "open_issues": []}}
    ```

    Rewrite it at every gate, every AR, every user approval, and every Phase-8
    cycle boundary. Also write the spec digests from step 8 to
    `temp_build_state/[GAME_SNAKE]/spec_digest/*.md` (options, screens, assets,
    tests, section_map) instead of only holding them in context: sub-agent
    prompts then reference a 10KB digest file rather than re-reading a 160KB
    spec, and a restart loses nothing.
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
