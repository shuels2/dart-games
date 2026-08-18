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

### Universal corrective-dispatch rule (per [Playbook §9])

**Every corrective sub-agent dispatch MUST be paired with a
re-audit of the SPECIFIC row / AR item that failed** — do not
trust the fix without re-verification. The re-audit runs at the
SAME model tier as the original verify stage (Tier 1 for critical
recurring-miss rows, Tier 2 or 4 for the rest). Pipeline shape:

```
[failing row] → [Tier 3 fix agent] → [re-verify at original tier]
```

If the re-verify still fails, ESCALATE to the orchestrator. Do NOT
dispatch a third sub-agent silently — that's the pattern that hides
partial-fix cascades. Two failed sub-agents on the same row means
the prompt is wrong OR the fix requires cross-cutting reasoning
only the orchestrator has.

### Structured findings across every AR

**Every AR sub-agent MUST return structured data via the
`FINDING_SCHEMA` from [Playbook §8]** — no more prose reports that
the orchestrator has to parse. Findings feed AR-Coverage directly
and render into the [Playbook §13] Artifact dashboard without
transformation.

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
- NEVER accept a sub-agent's screenshot verdict without looking yourself. Fanning out to parallel lens reviewers is encouraged (Playbook §3); skipping your own read of every screenshot is not. See Phase 8 STEP 2.
- NEVER delegate adversarial reviews to a Sonnet sub-agent — they are critique work and stay on Opus.
- NEVER skip `cd server && dart test` — the 178 server tests are mandatory at every gate that runs non-UI tests.
- NEVER skip the 4 mandatory navigation tests, the 3 mandatory results-screen tests, or the play-to-complete tests.
- NEVER use `(route) => false` in any Navigator call — use `(route) => route.isFirst` or `route.isFirst || route.settings.name == '/...'`.
- NEVER use Nunito font or Flame Orange (`#FF6B35`) in game-screen styling — those are container-app tokens.
- NEVER use game characters as player avatars.
- NEVER commit to master/main. NEVER push to remote without explicit user permission.
