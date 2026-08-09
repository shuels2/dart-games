<!-- game.build Phase 10 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 10: Cross-Game Test-Coverage Audit

**Goal:** After all initial tests pass (Gate 4), audit the new game's test coverage against a strong-coverage peer game. Identify scenario gaps — particularly option × player-count combinations, miss paths, knockoff / bust / win edge cases, save/restore round-trips, edit-score replay scenarios, menu-level guards, and announcement precedence — that the peer covers but the new game doesn't. Get user approval, then close the gaps with new tests (and, if the audit surfaces dead code or unwired helpers in the announcement layer or elsewhere, wire or delete them per user decision).

**Model:** **Tier 0** (orchestrator) for audit + gap synthesis + remediation plan; **Tier 3** (Sonnet) for implementing new tests once user approves. **After test authoring:** **[Playbook §10 — Test-smell reviewer]**. **AR-Coverage output:** render an HTML matrix via **[Playbook §13 — Cross-game Artifact dashboard]** so the user sees "which games missed which check" visually.

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
