---
name: game.perf-audit
description: Audits the Dart Games codebase for Flutter/Dart performance and code-quality opportunities. Reads the catalog of anti-patterns, scans the codebase, prioritizes findings, builds an implementation plan, and waits for explicit user approval before applying any changes. Repeatable — invoke whenever you want a fresh sweep.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, TaskCreate, TaskUpdate, TaskList, TaskGet, WebSearch, WebFetch
---

You are auditing the Dart Games Flutter + Dart Shelf monorepo for performance and code-quality opportunities. You will produce a structured report with prioritized findings and a concrete implementation plan. **You will NOT modify any production code or tests until the user explicitly approves a subset of the findings.**

## Hard rules — do NOT violate

1. **Phases 1–4 are read-only for production code.** No `Edit` / `Write` calls to production code or tests. The only files you may write before approval are: (a) the plan file at `docs/perf-audits/<yyyy-mm-dd>-<scope>.md` (required output of Phase 3), (b) `TaskCreate`/`TaskUpdate` records.
2. **Phase 4 is a mandatory stop.** Print a concise summary referencing the plan file, ask the user which findings to apply, and **end your turn**. Do not auto-proceed to Phase 5.
3. **Phase 5 only fires AFTER explicit user approval** like "approve all", "approve #1, #3", or "do #2". A vague affirmation ("ok", "go") is acceptable only if you have already explicitly enumerated the items being approved in the immediately prior message.
4. **The plan file is the source of truth.** Phase 3 MUST write a complete plan file (with full per-finding game-code impact + test impact for both UI and non-UI tests) before Phase 4 prints to chat. Phase 5 MUST re-read the plan file at start and update its `Implementation log` as work proceeds. Chat summaries are throwaway; the plan file survives context truncation and serves as the audit-history record committed to git.
5. **Test impact analysis is mandatory.** Every Phase 3 plan section MUST fill in the "Test impact" subsection with concrete `file:line` citations or explicit "None". This includes BOTH UI tests (`integration_test/`) and non-UI tests (`test/`, `server/test/`). Do not write "see above" or leave subsections blank.
6. **`game.build` skill impact analysis is mandatory.** Every Phase 3 plan section MUST fill in the "`game.build` skill impact" subsection. If a finding's pattern would otherwise be reintroduced by the next new game, the rule MUST be enshrined in `skills/game.build/SKILL.md` as part of Phase 5 — and the proposed text MUST be present in the plan file when the user reviews it. Mark "None" only when the test in the template (single-game tweak, server-only, etc.) genuinely fails. The audit's value compounds across future games ONLY when game.build absorbs the lessons.
7. **`game.build` skill rule reuse:** all changes from Phase 5 must still respect the project's existing rules — outer-Stack modal pattern, `context.watch` in build, no `floatingActionButton:` on Scaffold, etc. Read `skills/game.build/SKILL.md` if you're unsure whether a proposed change conflicts with an existing rule.
8. **Test gate:** any code change in Phase 5 must keep `flutter test` at the documented pass count (currently 1297/1297 Flutter non-UI + 178 server) — plus any new tests added per the plan — and `flutter analyze` introducing zero new errors.
9. **Scope guardrail:** this skill audits performance and code-quality. It does NOT do design changes, feature additions, refactors-for-style-only, or test additions unless they're tied to a performance finding.

---

## Input

```
/game.perf-audit                          # full codebase sweep
/game.perf-audit lunar_lander             # scope to one game
/game.perf-audit network                  # scope to one anti-pattern category
/game.perf-audit lib/screens/games/...    # scope to a specific path
```

If no argument is given, sweep the full codebase.

---

## Phase 1: Discovery (read-only)

Run the discovery battery below. For each anti-pattern category, record findings as a structured list with `file:line`, the offending snippet (short, ≤5 lines), and which catalog entry it matches.

**Use parallel sub-agents** to speed up discovery — split by category (Network / Compute / Render / DB / Test). Each subagent does its own greps and reads, then reports back with a list of citations. Combine the results.

Use `Grep` for the searches; only `Read` files when you need a few lines around a citation to confirm the pattern is real.

### Anti-pattern catalog

These categories cover the patterns most likely to hide wins in a Flutter + Dart Shelf monorepo. Each entry lists the search heuristic and the typical fix.

#### A. Network — N+1 / sequential calls

| ID | Pattern | Search heuristic | Typical fix |
|----|---------|------------------|-------------|
| N1 | API call inside a loop | `Grep` for `for (.*in.*players` followed by `apiClient` / `await` within ~10 lines | Add a batch endpoint; collect args in a list; one server roundtrip |
| N2 | Sequential `await`s on independent calls | `Grep` for `await .+;\s*\n\s*await ` in `.dart` (multiline). Inspect each pair — if neither depends on the other's result, batch with `Future.wait([a, b])` | `Future.wait([fa(), fb()])` |
| N3 | Per-player `updatePlayerStats` (project-specific) | `Grep` for `updatePlayerStats` and check call sites in `_results_screen.dart` files. If called once per player, that's an N+1 candidate | Add `POST /api/v1/players/stats/batch` accepting `[{id, stats}, …]`; update results screens to call once |
| N4 | Repeated single-key fetches | `Grep` for `await .+\.get<.*>\(` calls in close proximity that fetch by id from same collection | Single multi-id endpoint or in-memory cache |
| N5 | Polling / status-check loops | `Grep` for `while.*await Future.delayed` and `Timer.periodic` | Coalesce intervals, exponential backoff, or move to event-driven (websocket/stream) |

#### B. Compute — unnecessary work

| ID | Pattern | Search heuristic | Typical fix |
|----|---------|------------------|-------------|
| C1 | Expensive derivations recomputed every `build()` | Read each game/results screen's build; flag `.sort(`, `.where(...).toList()`, `.map(...).toList()` chains that take ≥3 collections or ≥3 sequential operations and don't depend on widget state. | Memoize via `ValueNotifier`/`Selector`/late-init cache. For lists that don't change often, compute in provider and cache via getter. |
| C2 | Redundant provider lookups in build | `Grep` per file: more than ~5 `provider.X()` method calls in the same `build()` method. | Capture once at top of build (`final game = provider.currentGame; final players = ...;`) and reuse. |
| C3 | List-search where a Map would do | `Grep` for `.firstWhere(.*=>.*\.id ==` patterns called repeatedly with same list. | Build a `Map<String, Player> byId = ...` once; do `byId[id]`. |
| C4 | `notifyListeners()` chains | `Grep` for `notifyListeners()` and check whether any provider call site fires it 3+ times in close succession (e.g. updating multiple players one at a time). | Coalesce: do all mutations, then call once. |
| C5 | Synchronous JSON / image work on UI thread | `Grep` for `jsonDecode(` / `Image.memory(` / `Image.asset(` directly called in build hot paths or inside `_handle*` callbacks that fire frequently. | Move to `compute()` / isolate / pre-decoded cache. |

#### C. Render — Flutter widget rebuilds

| ID | Pattern | Search heuristic | Typical fix |
|----|---------|------------------|-------------|
| R1 | Missing `const` on widgets | `Grep` for `BoxDecoration(` / `EdgeInsets.all(` / `TextStyle(` / `SizedBox(` without a leading `const ` token where args are all literals. | Add `const` so Flutter short-circuits the rebuild for that subtree. (Cite the Flutter perf docs.) |
| R2 | Overly broad `context.watch` | `Grep` for `context.watch<X>()` in `build()` then check whether the build only uses ONE field from the provider. If so it rebuilds on every notify, even unrelated changes. | Switch to `context.select<X, T>((x) => x.field)` or wrap that field consumer in a `Selector`/`Consumer` subtree. |
| R3 | `setState({})` empty / oversized | `Grep` for `setState\(\(\) \{\}\)` (literally empty) or `setState(...)` blocks that touch state used by a sibling subtree only. | Move state down to the smallest widget that uses it; or use a localized `ValueNotifier`. |
| R4 | `Opacity` with non-zero values inside animation/build | `Grep` for `Opacity(`. Flag any inside an `AnimationController.addListener` or `AnimatedBuilder.builder`. | Replace with `AnimatedOpacity` or `FadeTransition`. (Per Flutter perf docs.) |
| R5 | Missing `RepaintBoundary` around animated subtrees | `Grep` for `AnimatedBuilder(` / `AnimationController(` and check whether the animated subtree is wrapped. Look at game screens with continuous animations (Carnival Derby string lights, MM lightning, RR confetti). | Wrap the animated widget in `RepaintBoundary` so its repaints don't dirty the rest of the tree. |
| R6 | Missing lazy builders | `Grep` for `ListView(` (non-builder), `GridView(` (non-builder), `Column(children: [for...])` with potentially-large lists. | Switch to `.builder` constructors. |

#### D. DB — Server / SQLite

| ID | Pattern | Search heuristic | Typical fix |
|----|---------|------------------|-------------|
| D1 | Per-row INSERT/UPDATE in a loop | `Grep` `server/lib/routes/` for `for (.*in...)` containing `db.execute(` or `prepare(`. | Wrap in a single `db.transaction((tx) { ... })`; use multi-row INSERT (`INSERT INTO X (a,b) VALUES (?,?), (?,?), ...`). 70% improvement per SQLite docs. |
| D2 | Re-prepared statements | `Grep` `server/lib/` for repeated `db.prepare(` calls with same SQL inside a route handler. | Hoist the prepared statement to module-level or per-request cache. |
| D3 | Missing indexes | `Grep` `server/lib/database/migrations/` for `CREATE TABLE` statements; cross-reference with `WHERE` filters in `routes/`. Any frequent WHERE column without a matching index is a candidate. | Add index in next migration version. |
| D4 | `SELECT *` over wide tables | `Grep` `server/lib/routes/` for `SELECT \*`. Where the route only uses 2–3 columns, list them explicitly. | Explicit column list. Minor but adds up. |
| D5 | Missing `WAL` / pragmas | Read `server/lib/database/database.dart` and check for `PRAGMA journal_mode = WAL`, `PRAGMA synchronous = NORMAL`. If absent, those are the standard high-throughput settings. | Add the pragmas at DB open. |

#### E. Memory — leaks and lifecycles

| ID | Pattern | Search heuristic | Typical fix |
|----|---------|------------------|-------------|
| M1 | Missing `dispose()` for controller | `Grep` for `AnimationController(`, `TextEditingController(`, `ScrollController(`, `FocusNode(`, `StreamSubscription` declared as state field. Verify each is disposed in `dispose()`. | Add `controller.dispose();` to `dispose()`. |
| M2 | Listener never removed | `Grep` for `.addListener(` in `initState` / async helpers; verify a matching `.removeListener(` in `dispose`. | Mirror addListener with removeListener in dispose. |
| M3 | `Timer` / `Future.delayed` not cancelled | `Grep` for `Timer.periodic(` / `Future.delayed(` in widgets where the callback uses `if (mounted)` — if dispose runs first, the timer keeps firing. | Hold a reference to the `Timer`; cancel in dispose. |
| M4 | Closure leaks via captured state | Flag any `Future.delayed(...)` that references a long-lived widget tree object captured by closure if the outer object outlives the widget. (Heuristic — review only; subtle.) | Reduce closure captures; use weak refs / mounted checks. |

#### F. Tests — runtime / brittleness

| ID | Pattern | Search heuristic | Typical fix |
|----|---------|------------------|-------------|
| T1 | Full game playthroughs in setup | `Grep` `integration_test/*/results_screen/_helpers.dart` for loops in `completeGameToVictory`. If the test only needs `provider.hasWinner == true`, set state programmatically. | Add a `ProviderHelpers.setXProviderToVictoryState(...)` test helper that mutates state directly, skipping the gameplay loop. |
| T2 | `pumpAndSettle` in continuous-animation contexts | `Grep` integration tests for `pumpAndSettle()`. The CLAUDE.md rule already forbids it on game screens with continuous animations; flag any new usage. | Replace with explicit `pump(Duration(...))`. |
| T3 | Long sleeps in tests | `Grep` for `Duration(seconds: ` ≥ 5 in tests. Often these can be tighter. | Tighten where the underlying delay is shorter. |
| T4 | Repeated provider lookups | `Grep` tests for `ProviderHelpers.getXProvider(tester)` called 3+ times in the same test. | Capture once per test. |

#### G. App startup & assets

| ID | Pattern | Search heuristic | Typical fix |
|----|---------|------------------|-------------|
| S1 | Synchronous file I/O in `main()` / `initState` | `Grep` `lib/main.dart` and `*_screen.dart` for `File(`, `await File(...).readAsString()` outside `compute(`. | Move to background isolate or lazy-load. |
| S2 | Heavy widgets built before splash dismisses | Read `lib/main.dart` flow; flag any expensive provider construction or DB call in the synchronous main. | Defer to first-frame callback. |
| S3 | Uncompressed / oversized images | `Bash` `du -h assets/` and list any single asset > 500 KB. Cross-reference with `Image.asset(...)` callers — if displayed at < its native resolution, it's wasted bytes. | Compress, generate 1x/2x/3x variants, or use `cacheWidth`/`cacheHeight`. |
| S4 | `google_fonts` runtime fetch failures | Already mitigated in `run_ui_tests*.bat` (round 5 retry). Flag if any new font is added that fetches at runtime — pre-bundle it. | Add font asset to `pubspec.yaml`; remove `google_fonts` import for that font. |

---

## Phase 2: Categorize & prioritize

For each finding from Phase 1, produce a row with:

- **ID** — short identifier (e.g. `N3-1`, `R1-3`)
- **Category** — one of the catalog letters above
- **Title** — one-line summary
- **Citations** — `file:line` ranges
- **Impact** — High / Medium / Low (justify in a sentence: estimated wall-clock or memory savings)
- **Effort** — Small (< 1h) / Medium (1–4h) / Large (> 4h, multi-file or schema change)
- **Risk** — Low / Medium / High (touches public API? changes DB schema? affects all games?)
- **Migration cost** — single edit / per-game / requires data migration

Then rank: top opportunities are **High impact + Small effort + Low risk**. Surface those first.

Concretely:

```
Priority bucket A (top): Impact=H, Effort=S, Risk=L     → recommend now
Priority bucket B:        Impact=H, Effort=M, Risk=L|M  → recommend with plan
Priority bucket C:        Impact=M, Effort=S, Risk=L    → batch as quick wins
Priority bucket D:        Impact=L OR Risk=H            → noted, defer unless asked
```

Discard pure noise (low-impact, high-effort, high-risk) unless the user explicitly asked for it.

---

## Phase 3: Build implementation plan + WRITE PLAN FILE

For each finding the audit will RECOMMEND (Phase 2 buckets A/B/C), produce a concrete plan section in the report. **The plan section template below is mandatory — every subsection must be filled in (or explicitly marked "None") for every finding. The "Test impact" subsection is REQUIRED, not optional, and MUST cover both UI and non-UI tests.**

### Per-finding template (mandatory)

```
### [ID] [Title]

**Game code impact:**
- **Files (and line ranges):** explicit list — every file that will be edited
- **Currently:** ≤3-line snippet of the existing code at the primary citation
- **Proposed:** ≤5-line snippet of the replacement (or pseudo-code for larger changes)
- **Server change** (if applicable): route file + endpoint name + request/response shape
- **Migration version** (if DB schema change): next sequential after highest existing in `server/lib/database/migrations/`
- **Dependencies on other findings** (if any): "blocked by #N" / "should land before #N"

**Test impact (REQUIRED — both UI and non-UI):**

For each subsection, list specific `file:line` citations OR explicitly write "None". Do NOT leave a subsection blank or write "see above" — the plan file must be a self-contained source of truth.

- **Existing non-UI tests touched** (`test/`):
  - List each test file that exercises code paths affected by this finding.
  - Note whether each one passes unchanged or requires updates (and why).
- **Existing server tests touched** (`server/test/`):
  - Same format. "None" if no server change.
- **Existing UI/integration tests touched** (`integration_test/`):
  - Walk every screen/widget rendered by the affected files. List the integration test files that mount those widgets.
  - Note whether each one passes unchanged or requires updates.
- **Screenshot tests requiring re-validation** (`integration_test/*/visual_validation/` or `*_screenshot_test.dart`):
  - List test files whose screenshots could shift due to the change.
  - For pure rendering optimizations (e.g. `RepaintBoundary`), this should typically be "None" or marked low risk.
- **New tests required:**
  - Non-UI (`test/`): file paths + ≤1-line description per test, OR "None".
  - Server (`server/test/`): file paths + ≤1-line description per test, OR "None".
  - UI (`integration_test/`): file paths + ≤1-line description per test, OR "None".
- **Tests likely to BREAK without an update** (different from "touched" — these need code changes for tests to pass after the implementation):
  - List `file:line` citations OR "None".
  - Common gotchas: tests that mock the API and assert on call count (will break for batch-endpoint changes), tests that walk the widget tree looking for specific widget types like `Opacity` (will break if you swap to `FadeTransition`).

**`game.build` skill impact (REQUIRED — assess every finding):**

Future games are scaffolded by `/game.build`. If this finding introduces a pattern that future games should follow from day 1, the rule MUST be encoded in `skills/game.build/SKILL.md` (and its mirrored `.claude/` copy) — otherwise the next new game will reintroduce the same anti-pattern that this audit just removed.

For each finding, fill in BOTH lines (or explicitly mark "None"):

- **Pattern to enshrine in `game.build`:**
  - One-line description of the rule future games should follow (e.g. "When a game has a 'finish a game' flow that updates per-player stats, MUST use `apiClient.batchUpdatePlayerStats(...)` — not a per-player loop"), OR "None — game-internal optimization, no future-game implications".
- **Specific edits to `skills/game.build/SKILL.md` (and `.claude/skills/game.build/SKILL.md`):**
  - Section to update (cite by section heading, e.g. "Step 7: Wire results screen → API stats persistence").
  - Verbatim text snippet to add (1-3 sentences, in the same imperative voice as the rest of `game.build`).
  - Whether this should also be added to `game.build`'s AR-4 verification checklist (the section that grades a freshly-built game against project rules) — if YES, propose the AR-4 row text.
  - OR "None — no `game.build` rule to add for this finding".

When evaluating "should this become a `game.build` rule?", apply this test:
- ✅ YES if the finding is a pattern that EVERY game would otherwise reintroduce (e.g. modal layering, per-player API call structure, asset cacheWidth requirements).
- ✅ YES if the finding fixed a recurrent bug across multiple games (e.g. the round-5 `context.read` results-screen bug was fixed in 4 games — a `game.build` rule prevents the 7th game from hitting it).
- ❌ NO if the finding is a one-off tweak to a single widget or game (e.g. fix a math bug in Carnival Derby's scoring — not generalizable).
- ❌ NO if the finding is server-only and `game.build` doesn't generate server code paths affected by it.

**Estimated savings:** quantify (e.g., "1 RTT × 6 games × ~80ms = ~480ms cumulative" or "~30% rebuild count on game screen" or "~20 MB GPU memory" — pick the most relevant metric)
**Risk:** Low/Medium/High with one-line reason
**Migration:** if backwards-compat matters, describe the staged path
```

### Plan file output (REQUIRED — survives context truncation)

After producing all plan sections, **WRITE THE FULL REPORT TO A PLAN FILE** before printing anything to chat. The plan file is the SOURCE OF TRUTH for Phases 4 and 5. The summary printed in chat is for at-a-glance review only — the plan file contains the complete content that survives context truncation.

**Path:** `docs/perf-audits/<yyyy-mm-dd>-<scope>.md`

- `<yyyy-mm-dd>` is today's date (use `date /T` on Windows or check the system reminder for current date).
- `<scope>` is `full` (no scope arg), the game name (e.g. `lunar_lander`), the category letter (e.g. `network`), or a path-derived slug.
- If a plan file with that exact name already exists, append `-2`, `-3`, ... before the `.md` extension to avoid clobbering prior runs.
- Create the `docs/perf-audits/` directory if it doesn't exist.

**Plan file structure:**

```markdown
# Perf Audit Plan — <yyyy-mm-dd> [scope: full / <game> / <category>]

> **Status:** Phase 4 — awaiting approval
> **Approved findings:** (none yet — pending user reply)
> **Implementation log:** (none yet — Phase 5 not started)

## Summary
[copy of Phase 2 summary table]

## Bucket A — High impact, low effort, low risk (recommended)
[every Phase 3 plan section for bucket-A findings, full template above]

## Bucket B — High impact, medium effort
[every Phase 3 plan section for bucket-B findings]

## Bucket C — Quick wins
[every Phase 3 plan section for bucket-C findings]

## Bucket D — Deferred (low priority or high risk)
[one-line summaries; no full plan needed unless explicitly approved]

## Tests that MUST run after implementation
[derived from per-finding test impact: full suite + targeted UI re-runs]

## Approval prompt
[the Phase 4 prompt block — for reference]

## Implementation log (Phase 5)
[empty until user approves; Phase 5 fills in per finding: applied / deferred / skipped + date + commit SHA + notes]
```

**After writing the plan file**, the summary printed to chat in Phase 4 should reference the plan file path so the user knows where the source of truth lives.

---

## Phase 4: APPROVAL GATE — STOP HERE

By this point the plan file at `docs/perf-audits/<yyyy-mm-dd>-<scope>.md` exists with the full report. Print a CONCISE summary to chat (a one-line headline per finding + bucket counts) plus the approval prompt below — do not re-print the full per-finding plan in chat (it's in the file already).

```
═══════════════════════════════════════════════════════
APPROVAL NEEDED — pick which findings to apply

📄 Full plan: docs/perf-audits/<yyyy-mm-dd>-<scope>.md
   (review this file for the complete per-finding plan
    including game-code + test-impact analysis)

Reply with one of:
  • "approve all"             → implement everything in buckets A/B/C
  • "approve #1, #3, #5"      → implement only those IDs
  • "approve bucket A"        → implement only bucket-A items
  • "decline"                 → stop here, no changes
  • "modify #2: <details>"    → request a change to a specific item

I will NOT make any code changes until you reply.
═══════════════════════════════════════════════════════
```

**End your turn after this prompt.** Do NOT speculate, do NOT edit files, do NOT run tests.

If the user replies with "approve <subset>", proceed to Phase 5 ONLY for the approved items, working from the plan file.

---

## Phase 5: Implementation (only after approval)

The plan file at `docs/perf-audits/<yyyy-mm-dd>-<scope>.md` is the SOURCE OF TRUTH for everything Phase 5 does. Re-read it at the start of Phase 5 — do not rely on chat context, which may have been compressed.

1. **Read the plan file first.** Locate the approved findings (per the user's reply). Treat this file as authoritative for what to apply, what tests to add, and what existing tests are at risk.
2. **Update plan file header:** flip `Status` to `Phase 5 — implementing` and list the approved finding IDs under `Approved findings:` with the user's reply quoted.
3. Use `TaskCreate` to register one task per approved finding. Mark in_progress as you start each.
4. **For each approved finding** (in plan-file order, respecting any "blocked by #N" dependencies):
   - Apply edits (`Edit` / `Write`) per the plan's "Game code impact" section — small, reviewable diffs per file.
   - Add new tests per the plan's "Test impact → New tests required" section (non-UI + server + UI as listed). If the plan said "None" for a category, skip it.
   - Update existing tests per the plan's "Tests likely to BREAK without an update" section.
   - Run `flutter analyze` on the modified file(s). If any new errors appear, **stop and report — do not move to the next finding**.
   - Append an entry to the plan file's `Implementation log` section: `- [ID] applied — files: X, Y, Z; new tests: A, B; status: passed analyze`. (Mark `deferred` or `skipped` with reason if you couldn't apply.)
5. **After ALL approved findings are complete:**
   - Run the full `flutter test` suite. Confirm the count documented in the plan file's "Tests that MUST run" section (e.g. 1297/1297 Flutter non-UI tests still pass + any new tests added).
   - Run `cd server && dart test` if any server change was made (per plan: must stay 178/178 + any new server tests).
   - Run targeted UI re-runs from the plan's "Tests that MUST run" section (specifically the screenshot tests + critical integration tests for changed screens).
6. **Apply each approved finding's `game.build` skill impact** as a separate edit step BEFORE the final test run:
   - Re-read each approved finding's "`game.build` skill impact" subsection in the plan file.
   - For each finding where the subsection is NOT "None", apply the proposed text edit to BOTH `skills/game.build/SKILL.md` AND `.claude/skills/game.build/SKILL.md` (the dual-copy CLAUDE.md rule still applies).
   - If the subsection proposed an AR-4 verification row, add it to `game.build`'s AR-4 checklist.
   - Verify `diff -q skills/game.build/SKILL.md .claude/skills/game.build/SKILL.md` reports no differences.
   - Append a sub-bullet to the Implementation log entry: `  - game.build updated: <section>; AR-4 row added: yes/no`. If the finding had "None" for game.build impact, write `  - game.build update: N/A`.
   - Also update relevant docs (e.g. `docs/development/game-integration.md`, `docs/architecture/shared-systems.md`) when the same pattern is documented there.
7. Mark each task `completed` as you finish it.
8. **Finalize plan file:** flip `Status` to `Phase 5 — complete (<n> applied / <m> deferred)`. Each implementation-log entry should now have a commit SHA appended.
9. **Final report to chat:** per-finding diff summary, test counts, link to the now-complete plan file, any follow-up items deferred.

**Hard test rule:** if `flutter test` regresses, immediately reverse the most recent finding's edits, mark that finding `reverted` in the plan file's implementation log with the failure reason, and report. Do NOT proceed to the next finding while the suite is red.

---

## Sync rule (matches `game.build` pattern)

This skill exists in TWO places:
- `.claude/skills/game.perf-audit/SKILL.md` — locally installed, used by this Claude session
- `skills/game.perf-audit/SKILL.md` — project-tracked, committed to git

Both copies MUST stay byte-identical. When updating the skill (e.g. adding a new anti-pattern after a Phase-5 lesson learned), apply the SAME edit to both, OR `cp` one over the other. Verify with `diff -q` reporting no differences. Add the same rule to `CLAUDE.md`'s skill-sync section if not already present.

---

## Output style

The plan file (`docs/perf-audits/<yyyy-mm-dd>-<scope>.md`) is self-contained Markdown that the user can read top-to-bottom and act on, AND that survives context truncation as a permanent record. Sections in this order:

```
# Perf Audit Plan — <yyyy-mm-dd> [scope: full / <game> / <category>]

> **Status:** Phase 4 — awaiting approval | Phase 5 — implementing | Phase 5 — complete (<n> applied / <m> deferred)
> **Approved findings:** (none yet — pending user reply) | "<verbatim user reply>" → applied: [...]
> **Implementation log:** (see section at bottom)

## Summary
N findings. Buckets: A=<X>, B=<Y>, C=<Z>, D=<W>. Top 3 below.

## Bucket A — High impact, low effort, low risk (recommended)
[Full Phase 3 plan section per finding — including the mandatory Test impact subsection]

## Bucket B — High impact, medium effort
[Full Phase 3 plan section per finding]

## Bucket C — Quick wins
[Full Phase 3 plan section per finding (still requires test impact)]

## Bucket D — Deferred (low priority or high risk)
[One-line summaries; no full plan needed unless explicitly approved later]

## Tests that MUST run after implementation
- Suites: `flutter test` (target count), `cd server && dart test` (target count), `flutter analyze` (zero new errors)
- Targeted UI re-runs: enumerate the specific integration test files derived from the per-finding test impact (e.g. `integration_test/<game>/<area>/<test>_test.dart`)
- Targeted screenshot tests: enumerate any `*_screenshot_test.dart` whose output could shift

## Approval prompt
[The Phase 4 prompt block — for reference, so re-reading the plan recovers the original approval request]

## Implementation log (Phase 5)
[Empty until user approves; Phase 5 fills in per finding:
   - [ID] applied — files: X, Y, Z; new tests: A, B; commit: <SHA>; date: <yyyy-mm-dd>
   - [ID] deferred — reason: ...
   - [ID] reverted — reason: <test failure>; commit at revert: <SHA>
]
```

The chat summary printed in Phase 4 is a CONCISE pointer to the plan file — one-line per finding + the approval prompt — not a duplicate of the plan content.

Cite Flutter's official guidance ([Flutter perf best practices](https://docs.flutter.dev/perf/best-practices)) and SQLite docs ([SQLite Optimizations](https://www.powersync.com/blog/sqlite-optimizations-for-ultra-high-performance)) where the rationale isn't obvious — but don't pad the report with citations.

---

## Notes for future maintenance

- After each `/game.perf-audit` run, if you discover a NEW anti-pattern that wasn't in the catalog above, ADD it as a new row to the appropriate section (in BOTH skill copies). The catalog should grow over time.
- If a Phase-5 implementation reveals a deeper architectural rule (e.g. "all stats endpoints should be batched"), update `game.build`'s SKILL.md too so new games follow the rule from day 1.
- The `docs/perf-audits/` directory is a permanent audit-history record. Plan files there are committed to git so successive runs can read prior findings (especially the "deferred" sections of older plans) and the "Implementation log" sections to see what's already been applied.
- At the start of each run, glob `docs/perf-audits/*.md` and read the most recent 1-2 plans' "Implementation log" sections. Skip any code path that's marked `applied` recently — it's been covered. Re-flag any `deferred` items the user might want to revisit now that effort/risk balance has changed.
