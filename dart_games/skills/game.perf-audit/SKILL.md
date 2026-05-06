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
8. **Test gate:** any code change in Phase 5 must keep `flutter test` at the count documented in CLAUDE.md or the plan file's "Tests that MUST run" section (most recently 1306/1306 Flutter non-UI + 190/190 server, after the 2026-05-05 audit) — plus any new tests added per the plan — and `flutter analyze` introducing zero new errors.
9. **Scope guardrail:** this skill audits performance and code-quality. It does NOT do design changes, feature additions, refactors-for-style-only, or test additions unless they're tied to a performance finding.
10. **Wave-gate rule (Phase 5):** between every dispatch wave the orchestrator runs `flutter test` (and `cd server && dart test` if any server file changed). If the suite goes red, do NOT dispatch the next wave. Identify which finding broke it (most-recent applied is the prime suspect), revert that finding only, mark `reverted` in the implementation log, and continue with the rest of the plan.

---

## Model Strategy (Two-Model Architecture)

This skill runs as an **orchestrator** on the parent model (intended to be Opus) and **delegates parallelizable work to Sonnet sub-agents** via the Agent tool. The orchestrator handles all reasoning, judgment, dependency analysis, and gate decisions; sub-agents handle bulk discovery, plan drafting, and code edits. Following the same pattern as `game.build`.

**Orchestrator (this thread — Opus) handles directly:**
- Phase 0 (argument parsing, prior-audit reads, scope determination)
- Phase 2 categorization + bucketing (cross-finding judgment)
- Phase 3 plan-file *assembly* (sub-agents draft per-finding chunks; orchestrator weaves them, computes dependency edges, writes the file)
- Phase 4 approval prompt (single text output, then STOP)
- Phase 5 wave construction (read plan file, build dependency graph, group findings into independent waves)
- Phase 5 test-gate arbitration (after each wave: run suites, decide whether to proceed, revert, or stop)
- Phase 5b drafting `game.build` rule text (judgment about what should become a project rule — the *edit* itself can be a Sonnet job)
- Final report to chat

**Sonnet sub-agents (spawned via Agent tool) handle:**
- Phase 1 discovery — one sub-agent per anti-pattern category (Network / Compute / Render / DB / Memory+Test+Startup), all in parallel
- Phase 3 per-finding plan drafting — one sub-agent per finding, all in parallel; each fills in the per-finding template and returns Markdown
- Phase 5 implementation — one sub-agent per finding (or per finding sub-component for big findings like a batch endpoint), grouped into waves by dependency
- Phase 5b mechanical edits to `skills/game.build/SKILL.md` and `.claude/skills/game.build/SKILL.md` once the orchestrator has drafted the rule text

### Delegation Pattern

When delegating to a Sonnet sub-agent, invoke the Agent tool with:

- `subagent_type`: `"general-purpose"` (for write tasks) or `"Explore"` (for read-only Phase 1 discovery)
- `model`: `"sonnet"`
- `description`: 3–5 word task summary
- `prompt`: a **self-contained** prompt — the sub-agent has none of this conversation's context

Every delegation prompt MUST include:
1. The finding's discovery citations (`file:line` ranges) and matched catalog ID
2. The project rule files to read (cite paths under `docs/` and `CLAUDE.md`)
3. Every file to read, create, or modify, with full paths
4. The acceptance criteria (what "done" looks like — e.g. "flutter analyze on file X reports zero new errors")
5. What to report back (concrete evidence, not vague summaries — e.g. "the diff for file X" or "the count of `firstWhere` matches remaining")
6. Hard limits — see Universal Sub-Agent Hard Rules below
7. The plan file path so the sub-agent can re-read its own finding's section verbatim if needed

Each phase below contains a **Sub-agent prompt template** — fill in the placeholders before invoking.

### Trust but Verify

After a Sonnet sub-agent returns, **do not trust its summary**. Before proceeding:
- Read the actual files it claims to have created or modified.
- Run `git status` and `git diff` to see the real changes (a sub-agent that says "applied finding A1" must actually have modified the cited files).
- Run `flutter analyze <changed-files>` and confirm zero new errors.
- For Phase 5: confirm the `Implementation log` entry was appended; if not, append it yourself based on the verified diff.

If the sub-agent's actual output diverges from what was requested, send a corrective follow-up via the Agent tool with the specific gap. Do not paper over divergences in the orchestrator's notes — the plan file's implementation log is the audit-history record.

### Adversarial / Judgment Tasks Stay on the Orchestrator

Categorization (Phase 2), plan-file assembly (Phase 3), wave construction (Phase 5), test-gate arbitration, and `game.build` rule drafting (Phase 5b) MUST stay on the orchestrator. These tasks need cross-finding context that no single sub-agent has. If you find yourself wanting to delegate one of these, decompose it instead: the *mechanical* part of the task (e.g. applying a rule edit to two files) becomes a Sonnet job; the *judgment* part stays on the orchestrator.

### Universal Sub-Agent Hard Rules

**This block MUST be embedded in every Phase 1, 3, 5, and 5b sub-agent prompt's hard-rules section.**

> **Scope guardrail:** Make ONLY the changes specified in this prompt. Touch ONLY the files listed under "Files to modify". If you discover a bug or missing dependency in a file outside that list, **STOP and surface it to the orchestrator** — do not fix it.
>
> **No git operations:** Do NOT run `git commit`, `git push`, `git checkout`, `git reset`, or any other git mutation. The orchestrator manages all git state.
>
> **Stay additive on shared files:** If your task touches `skills/game.build/SKILL.md`, `lib/main.dart`, `lib/constants/test_keys.dart`, or any cross-game shared file, your edit MUST be additive (a new section / new entry / new line) — do NOT delete or rewrite existing content unless the prompt explicitly says so.
>
> **Analyze after each edit:** After every `Edit` or `Write`, run `flutter analyze <file>` (or `dart analyze` for server files) and confirm ZERO new errors. If new errors appear, undo the change and report — do NOT proceed to the next file with broken code.
>
> **CLAUDE.md sync rules apply:** If your task modifies `skills/game.build/SKILL.md`, you MUST mirror the same edit to `.claude/skills/game.build/SKILL.md` (or vice versa) and verify with `diff -q`. Same for `skills/game.perf-audit/SKILL.md`.
>
> **Reporting:** Return a structured report:
> 1. Files actually modified (with paths).
> 2. The diff (or its summary) for each file.
> 3. Test count if you ran tests.
> 4. Any item from the prompt you did NOT complete and why.
> Vague summaries ("done", "applied finding X") are not accepted — the orchestrator reads the diff to verify.

### Wave Dispatch — Background vs Foreground

For Phase 5 waves, default to **foreground** dispatch so the orchestrator can sequence wave gates correctly. A wave's sub-agents are launched in a **single message with multiple Agent tool-uses** (the Anthropic harness runs them concurrently when sent in parallel). The orchestrator then waits for all to return before running the wave's test gate.

Only use `run_in_background: true` for genuinely long-lived dispatches (e.g. a sub-agent that itself runs `flutter test`) where the orchestrator has independent foreground work to do meanwhile. In normal Phase 5 flow, foreground parallelism is correct.

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

**Model:** 5 Sonnet sub-agents in parallel (one per anti-pattern category) for the grep+read+pattern-match work. Orchestrator (Opus) merges and dedupes.

Run the discovery battery below. For each anti-pattern category, record findings as a structured list with `file:line`, the offending snippet (short, ≤5 lines), and which catalog entry it matches.

**Dispatch all 5 sub-agents in a single message** (multiple `Agent` tool calls in the same response — the Anthropic harness runs them concurrently). Each sub-agent does its own greps and reads, then reports back with a list of citations. The orchestrator collects the 5 reports, dedupes findings cited by multiple categories, and produces the unified Phase-1 output.

Use `Grep` for the searches; only `Read` files when you need a few lines around a citation to confirm the pattern is real.

### Sub-agent prompt template — Phase 1 discovery

For each of the 5 categories, dispatch a `general-purpose` sub-agent with `model: "sonnet"`. Categories and their catalog IDs:

| Sub-agent | Categories covered | Catalog IDs |
|---|---|---|
| 1. Network | A. Network — N+1 / sequential calls | N1–N5 |
| 2. Compute | B. Compute — unnecessary work | C1–C5 |
| 3. Render | C. Render — Flutter widget rebuilds | R1–R6 |
| 4. DB | D. DB — Server / SQLite | D1–D5 |
| 5. Memory + Tests + Startup | E. Memory + F. Tests + G. App startup | M1–M4, T1–T4, S1–S4 |

```
You are doing READ-ONLY discovery for a performance audit of the Dart Games
Flutter + Dart Shelf monorepo. Working dir: <PROJECT_ROOT>.

Find candidate citations for these <CATEGORY> anti-patterns. For each
finding, give file:line, a ≤5-line snippet, and which catalog ID it
matches. **Do not edit anything — read-only sweep.**

Catalog (paste the rows from the catalog table for this category):
<CATALOG_ROWS_FOR_THIS_CATEGORY>

Where to look:
<PATHS_TO_SCAN — e.g. lib/screens/games/<game>/, lib/providers/, server/lib/routes/>

Report results as a flat list grouped by catalog ID. Under <WORD_CAP> words.
End with "no other suspicious patterns observed" if discovery was complete.

Hard rules: <UNIVERSAL_SUB_AGENT_HARD_RULES_BLOCK>
```

After all 5 sub-agents return, the orchestrator (Opus):
1. Reads each report.
2. Verifies the highest-impact citations by reading the cited files (3–5 spot-checks per category).
3. Merges into a single deduped finding list ready for Phase 2.

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

**Model:** Orchestrator (Opus) only. Bucketing requires cross-finding judgment — Impact / Effort / Risk are inter-related and depend on knowledge of the codebase's history. Do NOT delegate.

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

**Model:** Sonnet sub-agents in parallel for per-finding plan drafting (one per finding, all dispatched in a single message); orchestrator (Opus) for plan-file *assembly*, dependency-edge computation, and the final `Write` of the file.

**Why fan out:** for an audit with N findings, drafting plan sections sequentially on the orchestrator can take 5–15 minutes (each section is ~300–600 words of templated content with file paths, test impact, and game.build rule proposals). Fanning out N Sonnet sub-agents in parallel cuts this to a single sub-agent's wall-clock — typically 30–90 seconds — at ~5–10x lower cost.

### Step 3a — Orchestrator dispatches per-finding drafters

For each finding the audit will RECOMMEND (Phase 2 buckets A / B / C), dispatch one Sonnet sub-agent with the per-finding template + that finding's discovery citations. **Send all dispatches in a single message** so they run concurrently.

Skip Bucket D — those only need a one-line summary (orchestrator writes those directly).

```
Sub-agent prompt template — Phase 3 per-finding drafter

You are drafting one section of a perf-audit plan for the Dart Games
Flutter + Dart Shelf monorepo. Working dir: <PROJECT_ROOT>.

Finding to draft:
- ID: <FINDING_ID>            (e.g. A1, B2, C3)
- Catalog: <CATEGORY_ID>      (e.g. N3, R5)
- Title: <SHORT_TITLE>
- Bucket: <A | B | C>

Discovery citations from Phase 1:
<file:line list with ≤5-line snippets per citation>

Project rules to honour (read these first):
- <PROJECT_ROOT>/CLAUDE.md
- <PROJECT_ROOT>/skills/game.build/SKILL.md (specifically the AR-4 section
  and the results-screen / game-screen rules — your "game.build skill
  impact" subsection must propose edits that mesh with the existing rules)
- <PROJECT_ROOT>/docs/critical-rules/test-failures.md

Your job: fill in the per-finding template below VERBATIM, replacing the
placeholders. Do NOT edit any production code or tests — this is a
plan-drafting task only.

Per-finding template:
<PASTE THE TEMPLATE FROM "Per-finding template (mandatory)" SECTION>

Report back: the filled-in Markdown section, ready to paste into the plan
file. Under <WORD_CAP> words. Include the explicit "None" marker wherever
the template requires "OR None" — do NOT leave subsections blank.

Hard rules: <UNIVERSAL_SUB_AGENT_HARD_RULES_BLOCK>
```

### Step 3b — Orchestrator assembles + writes plan file

After all sub-agents return:
1. **Verify each draft** — read each Markdown chunk; confirm the "Test impact" and "`game.build` skill impact" subsections are populated (no "see above" / no blank subsections). For any draft that is incomplete, dispatch a corrective Sonnet sub-agent with the specific gap.
2. **Compute dependency edges** — re-read each draft's "Dependencies on other findings" subsection. Record edges like `B1 blocked by A3`. This is the input to Phase 5's wave construction.
3. **Order findings within each bucket** — typically by ID, but any "blocked by" edge moves the blocker earlier.
4. **Write the plan file** to `docs/perf-audits/<yyyy-mm-dd>-<scope>.md` per the template below. The orchestrator does this `Write` itself (one atomic write, not per-section appends).

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

**Model:** Orchestrator (Opus). Single text output, no delegation.

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

**Model:** Orchestrator (Opus) for wave construction, dependency analysis, test-gate arbitration, and `game.build` rule drafting. Sonnet sub-agents in parallel for the per-finding code edits, test additions, and mechanical `game.build` skill edits — one sub-agent per finding (or per finding sub-component for big findings), grouped into waves.

The plan file at `docs/perf-audits/<yyyy-mm-dd>-<scope>.md` is the SOURCE OF TRUTH for everything Phase 5 does. Re-read it at the start of Phase 5 — do not rely on chat context, which may have been compressed.

### Step 5.1 — Re-read plan file + register tasks (orchestrator)

1. **Read the plan file first.** Locate the approved findings (per the user's reply). Treat this file as authoritative for what to apply, what tests to add, and what existing tests are at risk.
2. **Update plan file header:** flip `Status` to `Phase 5 — implementing` and list the approved finding IDs under `Approved findings:` with the user's reply quoted.
3. Use `TaskCreate` to register one task per approved finding plus tasks for "Apply game.build skill impact" and "Run final test gate". Mark in_progress as you start each.

### Step 5.2 — Build wave plan (orchestrator)

For each approved finding, read its "Dependencies on other findings" subsection. Construct a directed graph: an edge from B → A means B is blocked by A. Then group findings into **waves** such that:

- Within a wave, no finding depends on any other finding in the same wave.
- Within a wave, no two findings target the same file (to avoid sub-agent edit collisions). If two findings touch the same file, place them in different waves.
- Findings with no dependencies and no file collisions can all share the first wave.

Worked example from the 2026-05-05 audit (11 approved findings):

| Wave | Findings | Notes |
|---|---|---|
| 1 | A2 (PRAGMA), A3 (migration v3), C1 (cache isSoloHero) | All independent + different files |
| 2 | B1 (server N+1) | Depends on A3 (uses the new index) |
| 3 | A4+A5 split per game | 6 RepaintBoundary wraps in 6 different files — all parallel |
| 4 | B2 (byId cache + swap call sites) | Provider change + screen swap |
| 5 | A1 (sub-fanout) | Server route ‖ client method ‖ provider method, then 6-screen swap as wave 5b |
| 6 | game.build skill edits | Orchestrator drafts rule text first; one Sonnet to apply edits |

Print the wave plan to chat for the user's awareness, then proceed wave-by-wave.

### Step 5.3 — For each wave: dispatch in parallel, gate with tests

For each wave **W**:

1. **Build per-finding sub-agent prompts.** For every finding in the wave, construct a self-contained prompt using the template below. The prompt must include the finding's plan-file section verbatim (paste it from the plan file) plus the universal hard-rules block.

2. **Dispatch all of W's sub-agents in a single orchestrator message** (multiple `Agent` tool-uses in the same response — they run concurrently). Use `subagent_type: "general-purpose"`, `model: "sonnet"`.

3. **Wait for all sub-agents in W to return.** Each returns a structured report (files modified, diff summary, test count if it ran tests, any uncompleted items).

4. **Verify each sub-agent's work** (orchestrator):
   - Read the actual modified files.
   - Run `flutter analyze <changed-files>` — confirm zero new errors.
   - For each finding, append an entry to the plan file's `Implementation log` per Step 5.5.

5. **Wave test gate.** After verification, the orchestrator runs:
   - `flutter test` — must stay at the documented count + any new tests this wave added.
   - `cd server && dart test` — only if any server file changed in this wave; must stay green.
   - `flutter analyze` — zero new errors anywhere.

6. **If gate is GREEN** → proceed to the next wave.

7. **If gate is RED:**
   - Identify which finding broke the suite (typically the most-recent in the wave, but inspect failure messages to confirm).
   - Revert that finding's changes only (`git checkout -- <files>` on the cited files; or surgically `Edit` back if uncommitted).
   - Mark that finding `reverted` in the implementation log with the failure reason.
   - Re-run the gate. If still red, halt — surface to the user. Do NOT continue waves while the suite is red.
   - If green after revert, continue with the rest of the plan, skipping the reverted finding.

```
Sub-agent prompt template — Phase 5 per-finding implementer

You are implementing ONE finding from a Dart Games perf-audit plan.
Working dir: <PROJECT_ROOT>.

Plan file (source of truth): docs/perf-audits/<yyyy-mm-dd>-<scope>.md
Finding ID to apply: <FINDING_ID>
Wave: <WAVE_NUMBER>

Plan section for this finding (verbatim from the plan file — paste here):
<FINDING_PLAN_SECTION>

What to do:
1. Read the plan section above. The "Files (and line ranges)" list is
   exhaustive — touch ONLY those files.
2. Apply the edits described under "Proposed". Match the project's
   existing code style.
3. Add the tests listed under "Test impact → New tests required" — every
   non-"None" entry MUST result in a new test.
4. Update existing tests listed under "Tests likely to BREAK without an
   update" — add/modify the assertions described in that subsection.
5. Run `flutter analyze <changed-files>` — confirm ZERO new errors. If
   errors appear, undo the change for that file and report — do NOT
   leave broken code in place.
6. Run the targeted test file(s) listed for this finding (e.g.
   `flutter test test/providers/<provider>_test.dart`) and report the
   pass count.

Project rules to honour (read these first):
- <PROJECT_ROOT>/CLAUDE.md
- <PROJECT_ROOT>/skills/game.build/SKILL.md (the project rules that
  Phase 5b will potentially extend — do NOT violate any existing rule)
- <PROJECT_ROOT>/docs/critical-rules/test-failures.md (NEVER auto-update
  failing tests — surface to orchestrator)

Report back: structured report per the universal hard-rules block.

Hard rules: <UNIVERSAL_SUB_AGENT_HARD_RULES_BLOCK>
```

### Step 5.4 — Apply `game.build` skill impact (Phase 5b)

After ALL approved findings have been applied (and their wave gates passed):

1. **Orchestrator drafts the rule text** — for each finding whose plan section had a non-"None" `game.build` skill impact, the orchestrator (Opus) reads the proposed text and confirms it (a) doesn't conflict with existing `game.build` rules and (b) is correctly worded for the imperative voice of the rest of the skill. This is judgment work — do NOT delegate.

2. **Dispatch a Sonnet sub-agent to apply the edits.** Single sub-agent (the work is small + sequential since both copies must stay in sync). Prompt:

```
Apply the following game.build skill rule edits to BOTH copies:
- .claude/skills/game.build/SKILL.md
- skills/game.build/SKILL.md

Edits to apply (verbatim from the orchestrator):
<FOR EACH FINDING:>
  Section: <SECTION HEADING>
  Verbatim text to insert: <TEXT>
  Insert before/after: <ANCHOR LINE>
  AR-4 row to add (if any): <ROW TEXT>

After applying:
- Run `diff -q .claude/skills/game.build/SKILL.md skills/game.build/SKILL.md` — must report no differences.
- Report the new line count of each copy.

Hard rules: <UNIVERSAL_SUB_AGENT_HARD_RULES_BLOCK>
```

3. **Verify** (orchestrator): read both files, spot-check the inserted text, confirm `diff -q` is clean.

4. **Append to each implementation-log entry**: `  - game.build updated: <section>; AR-4 row added: yes/no`. For findings with no game.build impact, write `  - game.build update: N/A`.

5. Also update relevant docs (e.g. `docs/development/game-integration.md`, `docs/architecture/shared-systems.md`) when the same pattern is documented there. This is typically a small additional Sonnet job.

### Step 5.5 — Implementation-log entry shape

After each finding lands (or is reverted/deferred), append a line to the plan file's `Implementation log` section:

```
- [ID] applied — files: X, Y, Z; new tests: A, B; status: <test count>; date: <yyyy-mm-dd>
- [ID] reverted — reason: <test failure>; commit at revert: <SHA or 'uncommitted'>
- [ID] deferred — reason: ...
```

### Step 5.6 — Final test gate + report

After all waves complete and Phase 5b is done:

1. **Run the full test suites:**
   - `flutter test` — confirm the count matches the plan file's "Tests that MUST run" section (e.g. plan said 1306/1306 + 12 new = 1318, you should see 1318 pass).
   - `cd server && dart test` — same for server count.
   - `flutter analyze` — zero new errors.
   - Targeted UI re-runs from the plan's "Tests that MUST run" section (specifically the screenshot tests + critical integration tests for changed screens).

2. **Finalize plan file:** flip `Status` to `Phase 5 — complete (<n> applied / <m> deferred / <k> reverted)`. Each implementation-log entry should now have a commit SHA appended (if the user has been committing per-finding) or 'uncommitted' (if the user is reviewing before commit).

3. Mark each `TaskCreate`-tracked task `completed`.

4. **Final report to chat:** per-finding diff summary, test counts, link to the now-complete plan file, any follow-up items deferred.

### Phase 5 Hard Rules Summary

- **No wave starts while the suite is red.** Test gates are the only authoritative checkpoint.
- **Sub-agent dispatches are foreground-parallel by default.** Use a single orchestrator message with multiple `Agent` tool-uses to launch a wave concurrently. Reserve `run_in_background: true` for cases where the sub-agent itself runs long suites.
- **Sub-agents do not commit.** The orchestrator manages all git state; sub-agents only `Edit` / `Write`.
- **Trust but verify after every wave.** The orchestrator reads the modified files (not just the sub-agent's summary) before declaring the wave done.

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
