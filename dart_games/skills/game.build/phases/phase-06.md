<!-- game.build Phase 6 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 6: Save/Resume and Data Migration

**Goal:** Verify save/resume is fully wired, decide on migration needs, write the remaining serialization tests.

**Model:** **Tier 0** (orchestrator) for migration decision + wiring verification; **Tier 3** (Sonnet) for serialization + save/restore tests; **Tier 0** runs Gate 2. **After test authoring:** run **[Playbook §10 — Test-smell reviewer]** on the new save/restore tests.

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
