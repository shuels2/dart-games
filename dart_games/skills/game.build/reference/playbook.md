# APPENDIX: Expanded Capability Playbook

These 13 patterns are referenced by phase steps and AR blocks
throughout this skill via `[Playbook §N]`. Each is self-contained
and specifies the model tier + tool choice + expected impact.

---

## §1 — Workflow orchestration for AR-4 (and any multi-item AR)

**Problem:** AR-4 has 34+ integration-audit rows. Running them
sequentially on the orchestrator burns tokens and wall-clock time.

**Pattern:** Use the Workflow tool to rewrite the whole AR as a
`pipeline([rows], grepStage, verifyStage)` where each row streams
through both stages independently.

**Model tiers:**
- `grepStage`: **Tier 4** (Sonnet + `effort: 'low'`). Each row's grep
  + boolean check is mechanical — cheap fast agents are perfect.
- `verifyStage`: **Tier 1** (Opus) OR **Tier 2** (Sonnet + `effort:
  'high'`) depending on how much semantic reasoning the row needs.
  E.g., `(v)` outer-Stack modal pattern check needs Opus; `(cc)`
  sound file naming convention is Tier 4.
- Synthesis (aggregating findings): **Tier 0** (orchestrator).

**Skeleton:**
```javascript
export const meta = {
  name: 'ar-4-integration-audit',
  description: 'AR-4 Integration Audit for [GAME_NAME]',
  phases: [{title: 'Grep'}, {title: 'Verify'}, {title: 'Synthesize'}],
}
const ROWS = [
  {id: 'a', prompt: '...', tier: 'low'},
  {id: 'b', prompt: '...', tier: 'low'},
  // ... through (yy)
]
const findings = await pipeline(
  ROWS,
  row => agent(row.prompt + '\n\nGrep this row and report matches',
                {label: `grep:${row.id}`, phase: 'Grep',
                 effort: row.tier === 'low' ? 'low' : 'high',
                 schema: GREP_RESULT_SCHEMA}),
  (grep, row) => agent(row.verifyPrompt + '\n\nGrep found:\n' +
                        JSON.stringify(grep) +
                        '\n\nJudge PASS / FAIL with evidence.',
                       {label: `verify:${row.id}`, phase: 'Verify',
                        model: row.tier === 'high' ? 'opus' : undefined,
                        effort: 'high',
                        schema: FINDING_SCHEMA}),
)
return findings.filter(Boolean)
```

**Expected impact:** 5–10× wall-clock speedup on AR-4; structured
findings feed AR-Coverage cleanly; per-row cost tightly controlled
by tier.

## §2 — Adversarial verify (3× skeptic panel) for "recurring miss" categories

**Problem:** Rules labelled "Recurring miss" in AR-4 (RESPONSIVE
layout, background image render, ChangeNotifier disposed, no
auto-navigate on winner, batch stats update) have historically
slipped past single-reviewer audits. Cost of a miss = hours of
downstream debugging.

**Pattern:** For each finding on a recurring-miss row, spawn 3
INDEPENDENT skeptics whose default answer is REFUTED. Only pass if
≥2 confirm.

**Model tier:** **Tier 1** (Opus sub-agent, `{model: 'opus'}`) for
each skeptic. Independence is what matters here; Opus judgment
quality is the whole point.

**Skeleton (inside Workflow):**
```javascript
const skeptics = await parallel(Array.from({length: 3}, (_, i) => () =>
  agent(`Try to REFUTE this AR-4 finding: "${finding.summary}"
         Default to refuted=true unless evidence is airtight.
         Cite the file and line that PROVES it.
         Lens ${i}: ${LENSES[i]}`,
        {model: 'opus', schema: VERDICT_SCHEMA})))
const confirms = skeptics.filter(Boolean).filter(s => !s.refuted).length
if (confirms < 2) finding.status = 'REFUTED_BY_SKEPTIC_PANEL'
```

Where `LENSES = ['grep-evidence-only', 'read-the-actual-code',
'trace-the-runtime-symptom']` — different framing yields different
misses caught.

**Expected impact:** Catches subtle regressions AR-4 currently lets
slip. Especially valuable for the "Recurring miss:" categories the
skill already documents.

## §3 — Perspective-diverse Phase 8 Step 2 visual evaluation

**Problem:** Phase 8 Step 2 (screenshot evaluation) currently has one
orchestrator reading N screenshots against a checklist. Focus bias
means one reviewer misses subtle issues.

**Pattern:** Fan out 3 orchestrator-model reviewers with distinct
lenses; any lens's flag counts. This does NOT violate the "visual
judgment stays on the orchestrator" rule — all 3 lenses ARE the
orchestrator model.

**Model tier:** **Tier 1** (Opus, `{model: 'opus'}`) for each lens.

**Lenses:**
- Lens A — Layout: overflow, clipping, spacing consistency,
  alignment, viewport fit.
- Lens B — Typography: hierarchy, readability, cap-height parity
  (per AR-10), color contrast, shadow legibility.
- Lens C — Brand: color palette adherence, character usage,
  spec-declared visual identity, consistency with existing pack.

**Skeleton:**
```javascript
const LENSES = [
  {name: 'layout', focus: 'overflow / clipping / spacing / alignment'},
  {name: 'typography', focus: 'hierarchy / readability / cap-height'},
  {name: 'brand', focus: 'palette / character usage / brand fit'},
]
const findings = await parallel(LENSES.map(lens => () =>
  agent(`Read every PNG in temp_screenshots/. For each screenshot,
         report any issue visible through the ${lens.name} lens:
         ${lens.focus}. Report as {screenshot, issue, severity,
         suggested_fix}. Empty array if no issues.`,
        {model: 'opus', schema: LENS_FINDINGS_SCHEMA})))
const all = findings.filter(Boolean).flat()
```

**Expected impact:** Catches issues one reviewer would overlook due
to focus bias. Especially high value for games with dense UI
(Clockwork Quest gears, Pirates Grid map, Treasure Divide islands).

## §4 — Judge panel for Phase 2 Stage A (menu wireframe)

**Problem:** Stage A is the biggest brand-direction decision. One
wireframe attempt → user disapproves → author again → repeat. Slow.

**Pattern:** Fan out 3 wireframe authors in worktrees (different
color / font / layout takes). Orchestrator judges (or shows the
user 3 options for a preference vote — user-facing judge).

**Model tiers:**
- Authors: **Tier 3** (Sonnet, 3× parallel, each in
  `isolation: 'worktree'`).
- Judge: **Tier 1** (Opus) OR the user directly if preference is
  ambiguous.

**Skeleton:**
```javascript
const takes = await parallel(TAKES.map(take => () =>
  agent(`Author a Stage A menu wireframe with this take: ${take.brief}.
         Follow the standard wireframe prompt otherwise.`,
        {label: `wireframe:${take.name}`,
         isolation: 'worktree'})))
// Judge / show to user
const winner = await agent(`Compare these 3 wireframe takes against
                            the spec's Visual Style section. Return
                            the take that best matches, and why.`,
                           {model: 'opus', schema: JUDGE_SCHEMA})
```

**Expected impact:** Hit the brand vibe on the first user review
instead of the second or third. Wall-clock cost of running 3
parallel wireframers = same as 1 sequential (worktrees are cheap
disk); user-time saved = 20–40 min per Stage A.

## §5 — Worktree-parallel Phase 4 screen authoring

**Problem:** Currently Sonnet authors menu + game + results screens
sequentially (~30–40 min). The 3 files are largely independent.

**Pattern:** Fan out 3 Sonnet sub-agents in parallel worktrees, one
per screen file. Cross-cutting files (`test_keys.dart`, `main.dart`,
`home_screen.dart`) stay on the orchestrator in a single sync stage
after the parallel authors return.

**Model tier:** **Tier 3** (Sonnet) × 3, `isolation: 'worktree'`.

**Sync stage:** **Tier 0** (orchestrator) merges the 3 worktrees +
manually edits the 3 cross-cutting files. No parallel mutation on
these; the orchestrator owns them.

**Skeleton:**
```javascript
await parallel([
  () => agent(MENU_SCREEN_PROMPT, {isolation: 'worktree',
                                    label: 'menu-screen'}),
  () => agent(GAME_SCREEN_PROMPT, {isolation: 'worktree',
                                    label: 'game-screen'}),
  () => agent(RESULTS_SCREEN_PROMPT, {isolation: 'worktree',
                                       label: 'results-screen'}),
])
// Orchestrator merges worktrees back, then edits test_keys.dart,
// main.dart, and home_screen.dart directly.
```

**Expected impact:** 2–3× wall-clock speedup on Task 5.

## §6 — Loop-until-dry for Phase 7 spec coverage

**Problem:** Current spec coverage does one exhaustive pass. Compound
gaps (options × player counts × modes) sometimes slip past.

**Pattern:** Repeat spec-coverage finders until K=2 consecutive
rounds return zero new gaps.

**Model tier:** **Tier 0** (orchestrator) each round — synthesis
work.

**Skeleton:**
```javascript
const seen = new Set()
let dry = 0
while (dry < 2) {
  const gaps = await agent(SPEC_COVERAGE_PROMPT,
                            {model: 'opus', schema: GAPS_SCHEMA})
  const fresh = gaps.filter(g => !seen.has(gapKey(g)))
  if (!fresh.length) { dry++; continue }
  dry = 0
  fresh.forEach(g => seen.add(gapKey(g)))
  // Author tests for each fresh gap (Tier 3)
  await parallel(fresh.map(g => () => agent(closeGap(g))))
}
```

**Expected impact:** Catches compound edge cases a single pass
misses.

## §7 — Prior-art briefing via Explore agent

**Problem:** Sub-agents authoring wireframes / screens / tests
sometimes reinvent patterns that other games already established
cleanly.

**Pattern:** Before Phase 2 wireframes and Phase 4 screens, dispatch
an `Explore` agent to survey similar existing games and produce a
briefing: "for a game with X characteristics, existing pack uses
these patterns for colors/spacing/layout." Feed that briefing as
context into the authoring sub-agent.

**Model tier:** **Tier 5** (Explore) — ships with its own optimized
read-only model.

**Skeleton:**
```javascript
const priorArt = await agent(
  `Survey the existing games in lib/screens/games/ for a game
   with these traits: ${gameTraits}. Report per-topic:
   1. Color palette conventions used by similar games
   2. Menu screen layout patterns
   3. Game screen layout patterns
   4. Results screen layout patterns
   5. Common pitfalls to avoid
   Cite files/lines. Under 300 words.`,
  {agentType: 'Explore', label: 'prior-art'})
// Feed priorArt into the Phase 2/4 authoring prompt as context.
```

**Expected impact:** First-draft alignment with the pack. Fewer
approval iterations in Stage B/C/D.

## §8 — Structured output schemas

**Problem:** Sub-agents return prose. Orchestrator parses. AR
findings scatter across tool result bodies. AR-Coverage
aggregation is manual.

**Pattern:** Every AR sub-agent, every judge, every reviewer returns
structured data via `{schema: X}`.

**Schemas:**

```javascript
// Findings — used by every AR sub-agent
const FINDING_SCHEMA = {
  type: 'object',
  properties: {
    row: {type: 'string'},                        // e.g. 'yy'
    status: {enum: ['PASS', 'FAIL', 'NEEDS_FIX']},
    evidence: {type: 'string'},                   // grep output / cite
    file: {type: 'string'},                       // 'lib/.../foo.dart'
    line: {type: 'integer'},
    remediation: {type: 'string'},                // one-line fix hint
  },
  required: ['row', 'status'],
}

// Skeptic verdict — used by adversarial verify
const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    refuted: {type: 'boolean'},
    reasoning: {type: 'string'},
    counter_evidence: {type: 'string'},
  },
  required: ['refuted'],
}

// Judge — used by wireframe judge panel
const JUDGE_SCHEMA = {
  type: 'object',
  properties: {
    winner: {enum: ['A', 'B', 'C', 'NONE']},
    reasoning: {type: 'string'},
    graft_from: {type: 'array', items: {enum: ['A','B','C']}},
  },
  required: ['winner', 'reasoning'],
}

// Lens findings — Phase 8 Step 2 perspective-diverse review
const LENS_FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    lens: {enum: ['layout', 'typography', 'brand']},
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          screenshot: {type: 'string'},
          issue: {type: 'string'},
          severity: {enum: ['blocker', 'major', 'minor']},
          suggested_fix: {type: 'string'},
        },
      },
    },
  },
  required: ['lens', 'findings'],
}

// Definition-of-Done tracker — used by Phase 11 gate
const DOD_SCHEMA = {
  type: 'object',
  properties: {
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: {type: 'string'},                    // spec DoD item id
          description: {type: 'string'},
          status: {enum: ['DONE', 'PARTIAL', 'MISSING', 'N_A']},
          evidence_file: {type: 'string'},
          evidence_line: {type: 'integer'},
        },
        required: ['id', 'status'],
      },
    },
  },
  required: ['items'],
}
```

**Expected impact:** Deterministic post-processing; AR-Coverage
matrix is a `groupBy` away; Artifact dashboard renders directly
from structured data; DoD tracker prevents "which items did we
check?" moments at Phase 11.

## §9 — Corrective re-audit rule (universal)

**Problem:** When AR-N flags a gap and a corrective Sonnet
sub-agent is dispatched to fix it, we currently trust the fix
without re-verification. Sub-agents sometimes claim success on
partial fixes.

**Pattern:** After every corrective dispatch, re-run ONLY the
specific AR row that failed (not the whole AR). Use a Workflow
pipeline shape: `[finding] → [fix Sonnet] → [re-verify Opus sub-agent
on that row]`.

**Model tiers:**
- Fix: **Tier 3** (Sonnet).
- Re-verify: same tier as the original row's verify stage
  (Tier 1 or Tier 2 depending on the row).

**Rule:** If re-verify still fails, escalate to the orchestrator
(the sub-agent has failed twice on the same row). Do NOT dispatch
a third sub-agent silently.

**Expected impact:** Eliminates "sub-agent claimed success but the
AR still flags it" situations.

## §10 — Test-smell reviewer

**Problem:** Sonnet authors UI + non-UI tests; the AR checks that
tests EXIST but not that they meaningfully ASSERT. Tests that
`pumpAndSettle` and pass regardless of app state slip through.

**Pattern:** After every new test file is authored (Phase 3 model
tests, Phase 4 provider tests, Phase 7 UI tests), dispatch a
test-smell reviewer that scores the file on:
1. Every `testWidgets` has ≥1 `expect(...)` that would fail if the
   app broke.
2. No `expect(true, isTrue)` or `expect(1, 1)` no-op assertions.
3. Any `find.text(...)` targets a string the app actually renders
   (not a placeholder / error message the test itself set up).
4. No `pumpAndSettle()` inside a continuous-animation subtree
   (per project rule).
5. Test description matches actual behavior verified.

**Model tier:** **Tier 2** (Sonnet + `effort: 'high'`). Reasoning
about test quality is Sonnet-capable but non-trivial.

**Skeleton:**
```javascript
const testFiles = /* newly authored test files */
const smells = await pipeline(
  testFiles,
  file => agent(
    `Review this test file for smells: pumpAndSettle-and-pass,
     no-op expects, error-string dependencies, continuous-animation
     pumpAndSettle. Return {file, smells: [{lineno, type, severity}]}.
     Under 100 words per file.
     File: ${file}`,
    {effort: 'high', schema: SMELL_SCHEMA}),
  // Corrective stage: fix smells above severity threshold
  (smells, file) => smells.smells.filter(s => s.severity !== 'minor').length
    ? agent(`Fix these test smells in ${file}: ${JSON.stringify(smells)}`)
    : null,
)
```

**Expected impact:** Weak tests caught at build time, not weeks
later during a real regression.

## §11 — Background UI runs + ScheduleWakeup

**Problem:** Phase 8 Step 5 UI-test runs take 3–5 hours per game
category. The orchestrator idles waiting.

**Pattern:** Fire `./run_ui_tests_parallel.bat <category>` in the
background (Bash `run_in_background: true`). Immediately
`ScheduleWakeup(delaySeconds: 1200, ...)` to check in every
20 minutes. Between wakeups, the orchestrator can continue with
other Phase 8 work (e.g., running the font-parity ribbons for the
next game if we're in a multi-game batch, or writing docs).

**Skeleton (in a Phase 8 Step 5 delegation):**
```bash
# Background the run
./run_ui_tests_parallel.bat clockwork_quest > \
  integration_test_output/clockwork_quest_run.log 2>&1 &
```
Then in the skill orchestrator:
```
ScheduleWakeup(delaySeconds: 1200,
               reason: 'checking Clockwork Quest UI progress',
               prompt: '<original /loop prompt>')
```

**Expected impact:** Better wall-clock utilization. On a 12-game
batch this saves ~10 h of orchestrator idle time.

## §12 — Font ribbon Python analysis as a versioned tool

**Problem:** The Python pixel-analysis for the font ribbons is
currently an ad-hoc heredoc in the skill body. Inconsistent
between runs; not testable.

**Pattern:** Extract to `tools/font_ribbon_analyze.py` returning
JSON on stdout. Skill invokes via one Bash call.

**Model tier:** N/A (script). Orchestrator processes returned JSON.

**Skeleton:**
```bash
python tools/font_ribbon_analyze.py \
  --ribbon temp_screenshots/appbar_title_ribbon.png \
  --baseline "Target Tag" \
  --tolerance 3 > /tmp/ribbon_findings.json

# Orchestrator reads /tmp/ribbon_findings.json and iterates
# `overrideRecFs` on any game outside tolerance.
```

**Expected impact:** Consistent, testable measurement. Fewer
bespoke Bash edits per run.

## §13 — Cross-game AR-Coverage Artifact dashboard

**Problem:** Phase 10 AR-Coverage produces a text summary. Hard for
the user to see the "which games missed which check" pattern.

**Pattern:** Render an HTML matrix Artifact: rows = games,
columns = AR-4 items (a through yy), cells = PASS (green) / FAIL
(red) / N/A (grey). Uses the structured findings from §8.

**Model tier:** **Tier 4** (Sonnet + `effort: 'low'`) for template
fill; **Tier 0** (orchestrator) for the summary paragraph above the
matrix.

**Skeleton:**
```javascript
// 1. Orchestrator has arCoverageMatrix: {game: {row: status}}
// 2. Delegate HTML template fill
const html = await agent(
  `Render this cross-game AR-Coverage matrix as an HTML table.
   Green = PASS, red = FAIL, grey = N/A. Include a legend.
   Data: ${JSON.stringify(matrix)}`,
  {effort: 'low', schema: {type: 'string'}})
// 3. Orchestrator publishes via Artifact
```

Then invoke the Artifact tool with the returned HTML.

**Expected impact:** User sees coverage in seconds. Faster catch of
skipped rows across the game corpus.
