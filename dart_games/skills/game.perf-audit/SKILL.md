---
name: game.perf-audit
description: Audits the Dart Games codebase for Flutter/Dart performance and code-quality opportunities. Reads the catalog of anti-patterns, scans the codebase, prioritizes findings, builds an implementation plan, and waits for explicit user approval before applying any changes. Repeatable — invoke whenever you want a fresh sweep.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, TaskCreate, TaskUpdate, TaskList, TaskGet, WebSearch, WebFetch
---

You are auditing the Dart Games Flutter + Dart Shelf monorepo for performance and code-quality opportunities. You will produce a structured report with prioritized findings and a concrete implementation plan. **You will NOT modify any production code or tests until the user explicitly approves a subset of the findings.**

## Hard rules — do NOT violate

1. **Phases 1–4 are read-only.** No `Edit` / `Write` calls to production code. The only files you may write before approval are the report itself and `TaskCreate`/`TaskUpdate` records.
2. **Phase 4 is a mandatory stop.** Print the report, ask the user which findings to apply, and **end your turn**. Do not auto-proceed to Phase 5.
3. **Phase 5 only fires AFTER explicit user approval** like "approve all", "approve #1, #3", or "do #2". A vague affirmation ("ok", "go") is acceptable only if you have already explicitly enumerated the items being approved in the immediately prior message.
4. **`game.build` skill rule reuse:** all changes from Phase 5 must still respect the project's existing rules — outer-Stack modal pattern, `context.watch` in build, no `floatingActionButton:` on Scaffold, etc. Read `skills/game.build/SKILL.md` if you're unsure whether a proposed change conflicts with an existing rule.
5. **Test gate:** any code change in Phase 5 must keep `flutter test` at the documented pass count (currently 1297/1297 Flutter non-UI + 178 server) and `flutter analyze` introducing zero new errors.
6. **Scope guardrail:** this skill audits performance and code-quality. It does NOT do design changes, feature additions, refactors-for-style-only, or test additions unless they're tied to a performance finding.

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

## Phase 3: Build implementation plan

For each finding the audit will RECOMMEND (Phase 2 buckets A/B/C), produce a concrete plan section in the report:

```
### [ID] [Title]

**Where:** files + line ranges
**Currently:** ≤3-line snippet of the existing code
**Proposed:** ≤5-line snippet of the replacement (or pseudo-code for larger changes)
**Server change** (if applicable): route file + endpoint name + request/response shape
**Test changes** (if any): test files that need updates AND new tests required
**Estimated savings:** quantify (e.g., "1 RTT × 6 games × ~80ms = ~480ms cumulative" or "~30% rebuild count on game screen")
**Risk:** Low/Medium/High with one-line reason
**Migration:** if backwards-compat matters, describe the staged path
```

For DB schema changes, include the migration version number that would be added (next sequential after the highest existing version in `server/lib/database/migrations/`).

For each plan item, also note **dependencies** if one finding's fix presupposes another.

---

## Phase 4: APPROVAL GATE — STOP HERE

Print the full report (sections from Phases 2 + 3) AND a clearly-marked approval prompt:

```
═══════════════════════════════════════════════════════
APPROVAL NEEDED — pick which findings to apply

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

If the user replies with "approve <subset>", proceed to Phase 5 ONLY for the approved items.

---

## Phase 5: Implementation (only after approval)

For each approved finding, execute the plan from Phase 3:

1. Use `TaskCreate` to register one task per approved finding. Mark in_progress as you start each.
2. Apply edits (`Edit` / `Write`) — small, reviewable diffs per file.
3. Update tests if the plan listed test changes.
4. After EACH finding is complete: run `flutter analyze` on the modified file(s). If any new errors appear, stop and report — do not move to the next finding.
5. After ALL approved findings are complete: run the full `flutter test` suite. Confirm 1297/1297 Flutter non-UI tests still pass. Run `cd server && dart test` if any server change was made (must be 178/178).
6. Update the relevant docs and the `game.build` skill IF a finding introduces a new pattern that future games should follow (e.g. "always use the batch stats endpoint"). Both skill copies must stay byte-identical (per the existing CLAUDE.md rule).
7. Mark each task `completed` as you finish it.
8. Final report: per-finding diff summary, test counts, any follow-up items deferred.

**Hard test rule:** if `flutter test` regresses, immediately reverse the most recent finding's edits and report which one broke things.

---

## Sync rule (matches `game.build` pattern)

This skill exists in TWO places:
- `.claude/skills/game.perf-audit/SKILL.md` — locally installed, used by this Claude session
- `skills/game.perf-audit/SKILL.md` — project-tracked, committed to git

Both copies MUST stay byte-identical. When updating the skill (e.g. adding a new anti-pattern after a Phase-5 lesson learned), apply the SAME edit to both, OR `cp` one over the other. Verify with `diff -q` reporting no differences. Add the same rule to `CLAUDE.md`'s skill-sync section if not already present.

---

## Output style

The report itself should be self-contained Markdown that the user can read top-to-bottom and act on. Sections in this order:

```
# Perf Audit Report — <yyyy-mm-dd> [scope: full / <game> / <category>]

## Summary
N findings. Buckets: A=<X>, B=<Y>, C=<Z>, D=<W>. Top 3 below.

## Bucket A — High impact, low effort, low risk (recommended)
[Plan sections per finding]

## Bucket B — High impact, medium effort
[Plan sections per finding]

## Bucket C — Quick wins
[One-line summaries, batch-fixable]

## Bucket D — Deferred (low priority or high risk)
[One-line summaries; noted but not planned unless asked]

## Approval prompt (Phase 4 gate above)
```

Cite Flutter's official guidance ([Flutter perf best practices](https://docs.flutter.dev/perf/best-practices)) and SQLite docs ([SQLite Optimizations](https://www.powersync.com/blog/sqlite-optimizations-for-ultra-high-performance)) where the rationale isn't obvious — but don't pad the report with citations.

---

## Notes for future maintenance

- After each `/game.perf-audit` run, if you discover a NEW anti-pattern that wasn't in the catalog above, ADD it as a new row to the appropriate section (in BOTH skill copies). The catalog should grow over time.
- If a Phase-5 implementation reveals a deeper architectural rule (e.g. "all stats endpoints should be batched"), update `game.build`'s SKILL.md too so new games follow the rule from day 1.
- Don't audit the same code path twice in successive runs — keep a short "previously fixed" list at the bottom of the report so the next run can skip them or focus elsewhere.
