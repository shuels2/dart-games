<!-- game.build Phase 9 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 9: Simultaneous Pass Verification

**Goal:** Confirm all five completion conditions are true at the same time, including the spec coverage audit and server tests.

**Model:** **Tier 0** (orchestrator) — verification only.

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
