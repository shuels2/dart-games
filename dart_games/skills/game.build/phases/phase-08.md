<!-- game.build Phase 8 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 8: Visual Validation

**Goal:** Execute the FULL iterative validation cycle from `docs/critical-rules/visual-validation.md`. This phase contains the complete visual + UI + non-UI verification loop, PRECEDED by the mandatory font-parity audit (AR-10).

**Model split:**
- **Step 0 (font parity — AR-10):** **Tier 3** (Sonnet) for chromedriver + `flutter drive` for both ribbons; **Tier 0** (orchestrator) drives Python analysis via **[Playbook §12 — Font ribbon Python tool]** and decides `overrideRecFs` iterations.
- **Step 1 (screenshot capture):** **Tier 3** (Sonnet).
- **Step 2 (visual evaluation):** **[Playbook §3 — Perspective-diverse review]** — 3× Tier-1 Opus lens reviewers (layout / typography / brand) in parallel. This does NOT violate "visual judgment stays on the orchestrator" — all 3 ARE Opus sub-agents. Any lens's flag counts.
- **Step 3 (report findings):** **Tier 0** (orchestrator) synthesizes across lenses.
- **Step 4 (fixes):** **Tier 3** (Sonnet), then **[Playbook §9 — Corrective re-audit]** re-runs Step 2 lens(es) that flagged the fixed issue.
- **Step 5 (UI test runs):** **Tier 3** (Sonnet), and for 3h+ runs use **[Playbook §11 — Background UI runs]** with `run_in_background: true` (a completion notification arrives; no polling timer needed).
- **Step 7 (flutter test + server test):** **Tier 3** (Sonnet).
- **Step 4/6/8 decisions, AR-7, AR-10:** **Tier 0** (orchestrator).

**CRITICAL UNDERSTANDING:** "Screenshot test passed" does NOT mean "visual validation complete." A passing test only means screenshots were captured without runtime errors. The actual validation is reading and evaluating every screenshot against the checklist. These are two completely separate steps — NEVER conflate them.

### STEP 0: Font Parity Audit (MANDATORY — runs BEFORE screenshots)

The new game's AppBar title fontSize (all 3 screens) AND its
home-card title offset in `home_screen.dart` MUST be tuned so their
visible cap heights match Target Tag (the visual baseline) within
±3 px, using the ribbon measurement tests and pixel-precise Python
analysis. This step MUST complete before Step 1 (screenshot capture)
because font sizing affects every AppBar in every screenshot — running
screenshots against the wrong fontSize wastes a full visual-validation
cycle.

Follow the full procedure documented in the **"Font parity audit
procedure (reference)"** section near the end of this skill file.
Summary of what MUST happen:

1. Add a `_Entry(...)` for the new game to BOTH ribbon test files
   (`integration_test/appbar_title_measurement_test.dart` and
   `integration_test/home_screen_font_measurement_test.dart`) — copy
   the actual GoogleFonts family + fontSize + text from the game
   screens and from `_buildGameCard(...)` in `home_screen.dart`.
2. Update the `_styleFor` switch in each test to route the new game's
   `fontFamily` to its `GoogleFonts.<family>(...)` call.
3. Run each ribbon test via `flutter drive` (chromedriver +
   `test_driver/screenshot_test.dart`); screenshots land at
   `temp_screenshots/appbar_title_ribbon.png` and
   `temp_screenshots/home_screen_font_ribbon.png`.
4. Pixel-analyse each ribbon with the Python PIL script in the
   procedure reference — report the new game's cap height vs. Target
   Tag baseline for both ribbons.
5. Iterate `overrideRecFs` (weight-parity bump for thin-stroke fonts
   per the procedure) until BOTH ribbons show the new game within
   ±3 px of Target Tag.
6. Apply the winning `fontSize` to all three per-game screen files
   (AppBar test) AND the winning `+ N` offset to the new game's
   branch of the ternary inside `_buildGameCard(...)` in
   `home_screen.dart` (home-screen test).
7. Run **AR-10 Font Parity** on the orchestrator.

### Adversarial Review AR-10: Font Parity

> "I will now act as the Font Parity Agent. I will verify BOTH font
> measurement ribbons ended within tolerance AND the winning sizes
> were applied to the game's actual code:
>
> **AppBar parity (`integration_test/appbar_title_measurement_test.dart`):**
> 1. The new game appears as a `_Entry(...)` in `_kEntries` with the
>    correct `text` (matches the gameplay screen's actual AppBar
>    title), `fontFamily` (matches the actual GoogleFonts family used
>    in the code), and `currentFs` (matches the fontSize actually
>    shipped by the game screens BEFORE this audit).
> 2. The `_styleFor` switch has a `case '<Family>':` branch routing to
>    `GoogleFonts.<family>(...)` with the same style args.
> 3. The most recent `temp_screenshots/appbar_title_ribbon.png` was
>    generated after the new game was added, and my Python pixel
>    analysis shows the new game's RECOMMENDED strip cap height sits
>    within +0..+3 px of Target Tag's cap height at fs 36. Cite the
>    measured value.
> 4. The winning `fontSize:` appears in ALL THREE per-game screen
>    files (`<game>_menu_screen.dart`, `<game>_game_screen.dart`,
>    `<game>_results_screen.dart`) at the AppBar title's
>    `GoogleFonts.<family>(fontSize: N, ...)` — all three identical.
>
> **Home-card parity (`integration_test/home_screen_font_measurement_test.dart`):**
> 5. The new game appears as a `_Entry(...)` with the correct `text`
>    (matches the string passed to `_buildGameCard(title: '...')`),
>    `fontFamily`, and `currentFs = 18 + N`.
> 6. The `_styleFor` switch has the matching branch.
> 7. The most recent `temp_screenshots/home_screen_font_ribbon.png`
>    was generated after the new game was added, and pixel analysis
>    shows the new game's RECOMMENDED strip cap height sits within
>    +0..+3 px of Target Tag's cap height at fs 22. Cite the measured
>    value.
> 8. The winning `+ N` offset appears in the new game's branch of the
>    nested ternary inside `_buildGameCard(...)` in
>    `lib/screens/home_screen.dart`, formatted as
>    `(theme.textTheme.titleMedium?.fontSize ?? 16) + N` (per the
>    canonical pattern — Carnival Derby's bare-fontSize form is
>    deprecated for new games).
>
> **Convention compliance (per the Universal Rule at the top):**
> 9. Menu screen title = `[Game Name] Game Setup` (case per the game's
>    own home-card casing).
> 10. Results screen title = `[Game Name] Results` (same case rule).
> 11. All three AppBar titles use IDENTICAL font style — verified by
>    the `(g4)` check in AR-4; this AR restates it.
>
> **FAIL this AR** if any of (1)-(11) is missing or shows a cap-height
> diff greater than +3 px above Target Tag OR any negative diff (game
> caps shorter than baseline). Cite files + line numbers for every
> finding."

Report AR-10 findings. Dispatch a corrective Sonnet sub-agent for any
gaps (apply fs / offset changes) before proceeding to Step 1.

### Phase 8 pre-flight verification (orchestrator runs BEFORE Step 1)

Before invoking any Sonnet sub-agent for Step 1, verify the runner scripts have the false-positive guards and stale-cache wipes:

1. **Pass-detection includes `Failure Details:` as a fail marker.** Both `run_ui_tests.bat` and `run_ui_tests_parallel_worker.bat` should have:
   ```powershell
   $found = ($c -match 'All tests passed') `
        -and (-not ($c -match 'Some tests failed')) `
        -and (-not ($c -match 'Failure Details:'));
   ```
   Why: in `-d chrome` mode, the integration_test framework can emit BOTH `+2: All tests passed!` AND a trailing `Failure Details:` block when an assertion in the test body throws. Without this guard, the script reports PASSED on a broken test (false positive). Verified failure: pirates_grid 2026-05-07 — sub-test was failing the `Should be on menu after NEW VOYAGE` assertion in both modes; sequential reported PASS; parallel reported FAIL.
2. **flutter_tools temp kernel cache wipe in pre-flight.** Both runners should delete `%LOCALAPPDATA%\Temp\flutter_tools.*` before any flutter command:
   ```bat
   for /d %%D in ("%LOCALAPPDATA%\Temp\flutter_tools.*") do rmdir /S /Q "%%D" >nul 2>&1
   ```
   Why: `flutter_tools` keeps an `app.dill` kernel snapshot that survives `flutter clean`. When a method is added to a file already in the cached kernel, the next `flutter drive` reuses the stale kernel and reports "Member not found" — wasting hours on what looks like a code bug.

If either guard is missing, fix the runner scripts BEFORE running Phase 8 — otherwise visual-validation feedback is unreliable.

### The Iterative Validation Cycle

```
STEP 1 → STEP 2 → STEP 3 → STEP 4 decision
                                ↓ issues found → fix → back to STEP 1
                                ↓ no issues → STEP 5
STEP 5 → STEP 6 decision
            ↓ UI tests fail → fix → back to STEP 1
            ↓ UI tests pass → STEP 7
STEP 7 → STEP 8 decision
            ↓ non-UI fail → fix → back to STEP 1
            ↓ non-UI pass → STEP 9 (all pass simultaneously → done)
```

---

### STEP 1 PRE-FLIGHT (scripted — run before every capture attempt)

Screenshot runs fail for two very different reasons — the app is broken, or the
harness is — and both produce the same symptom: a run that hangs and a log that
ends at "Debug service listening". Separate them BEFORE spending a chromedriver
cycle.

**0. Boot smoke is green in this cycle.** If `boot_smoke_test.dart` (GATE 1.5)
has not run since the last app edit, run it first. It fails in 90 seconds where
a screenshot run fails in ten minutes.

**1. Analyze the new game — zero errors:**
```bash
flutter analyze lib/screens/games/[GAME_SNAKE]/ integration_test/[GAME_SNAKE]/
```

**2. Environment, in this order, each verified before the next:**
```bash
./update_chromedriver.bat                    # Chrome auto-updates; drivers don't
taskkill /F /IM chromedriver.exe             # NEVER chrome.exe — crash-recovery state
rm -rf "$LOCALAPPDATA/Temp/flutter_tools."*  # stale kernel → "Member not found"
```
Then start the server and poll until it answers, and start chromedriver and
poll `http://localhost:4444/status` until ready. Poll — never sleep a fixed
duration and hope.

**3. Budget check — BEFORE running, not after it dies:**
```bash
grep -c takeScreenshot integration_test/[GAME_SNAKE]/visual_validation/*.dart
```
Estimate `captures × 20s + 60s boot`. Over ~480s, split the file NOW. The
runner kills at 600s and the resulting log is indistinguishable from a
structural bug (see CLAUDE.md → Screenshot Test Technical Rules).

**4. Run with a watchdog.** Launch in the background and poll
`temp_screenshots/` every 30s. If no new file appears for 60s while the process
is alive, kill chromedriver, capture the log tail, and go to TRIAGE. Do not sit
through a ten-minute hang.

### STEP 1 TRIAGE — consult this BEFORE contacting the user

| What you see | Cause | Do this |
|---|---|---|
| Hangs at the FIRST `takeScreenshot`, zero files written | Wrong driver | Use `test_driver/screenshot_test.dart`; re-run |
| `DURATION=` near 600s in `<game>_results.txt`; log ends "Debug service listening"; `SocketException` at `WebDriver.quit` | 600s budget | Split the screenshot file; re-run |
| `Member not found` | Stale flutter_tools kernel | Wipe `flutter_tools.*`; re-run |
| `org-dartlang-app:/…File not found` | New file in `integration_test/shared/` invisible to the web compile cache | Fold the helper into an existing shared class (Rule §26); re-run |
| `AppConnectionException` | Chrome crash-recovery state | Open Chrome manually, dismiss the restore prompt, close it, restart chromedriver |
| "session not created" / version mismatch | Chrome updated under you | `./update_chromedriver.bat`; re-run |
| Stalls mid-file at capture #N | App exception in that state, OR an unfrozen `Timer.periodic` keeping the frame busy | Read the partial log and the last written PNG; re-run just that screen; check for uncancelled timers |
| Connection refused in the log | Server not up, or wrong port | Preflight step 2 |

**Escalation rule.** Work the table. Only after **two** distinct triage
attempts have failed do you stop and ask the user — and when you do, report:
the log tail, which screenshots were captured, which triage rows you tried, and
what each produced. "The screenshot test failed" is not a report.

Never stop before triage. That was the single largest source of manual
intervention in this pipeline.

### STEP 1: CAPTURE (Sonnet sub-agent)

**Hung-process safety:** Past sessions have seen the screenshot test deadlock for 25+ minutes when the game UI has a build error or missing widget. The orchestrator imposes a **25-second progress timeout** on the screenshot test process — if no new screenshot file appears in `temp_screenshots/` for 25 seconds AND the flutter_drive process hasn't exited, the orchestrator instructs the sub-agent to KILL chromedriver + chrome + flutter_drive, read the partial log, and assess what's wrong before retrying. The 25s threshold matches the actual per-screenshot capture time observed in healthy runs (5–15s typical, with margin for the initial app boot of the first capture). Past failure: Pirate's Grid screenshot test halted at #12 of 15 (the speed-play timer transition) and we waited 4 minutes before killing it — wasted iteration time. Tighter timeout = faster failure detection = faster fix loop.

**Known problem area — timer-based UI states:** Screenshot tests that capture a state involving a continuously-running `Timer` (e.g., a Speed Play countdown, an animation that loops indefinitely) deadlock if the test pumps `pump(Duration)` on a continuously-firing timer — the timer keeps emitting events and `pumpAndSettle` never completes, freezing capture. The screenshot test for any timer-driven UI state MUST: (a) freeze the timer before capturing — set the screen state to a fixed timer value via `provider.<setTimerForTest>(...)` if a hook exists, OR (b) capture immediately on the same frame the timer was started (no `pump(Duration)`), OR (c) skip that visual state and document it in the spec coverage report as a known gap. Reference: PG `game_speed_play_timer` capture at index #12; the screen had an active `Timer.periodic` and `pumpAndSettle` never settled.

**Sub-agent prompt template:**

> You are running the screenshot capture for the **[GAME_NAME_DISPLAY]** game.
>
> **Read first:**
> - `docs/critical-rules/visual-validation.md`
> - `docs/testing/ui-automation.md` (chromedriver version sync, server startup, port assignments)
> - `run_ui_tests.bat` (for the established launch pattern — match it)
>
> **Tasks:**
> 1. **Sync chromedriver to the installed Chrome version:** run `./update_chromedriver.bat` from the repo root. Without this step, a Chrome auto-update will cause silent test failures with cryptic chromedriver errors.
> 2. Kill any running `chromedriver.exe` processes via `taskkill /F /IM chromedriver.exe` (NEVER kill `chrome.exe` — that triggers Chrome crash recovery state).
> 3. **Start the backend server in the background** (the screenshot test needs it):
>    ```
>    cd server && dart run bin/server.dart --port 9000 --data-dir ../ui_test_data
>    ```
>    Wait until it logs that it's listening on port 9000.
> 4. Start chromedriver in the background: `cd chromedriver/chromedriver-win64 && ./chromedriver.exe --port=4444`
> 5. Wait 5 seconds for chromedriver to initialize.
> 6. Run the screenshot test:
>    ```
>    flutter drive --driver=test_driver/screenshot_test.dart --target=integration_test/[GAME_NAME_SNAKE]/visual_validation/[GAME_NAME_SNAKE]_screenshot_test.dart -d chrome
>    ```
>    **CRITICAL:** Use `test_driver/screenshot_test.dart` — NEVER `test_driver/integration_test.dart` (will hang silently on `takeScreenshot()`).
>    **CRITICAL:** Do NOT use `--no-headless`.
> 7. Confirm all screenshots saved to `temp_screenshots/`.
> 8. Tear down: kill the chromedriver process; kill the backend server process. (Do NOT kill `chrome.exe`.)
>
> **Report back:**
> - The list of every screenshot file found in `temp_screenshots/` (filename + size)
> - The chromedriver version sync output
> - Any errors from the backend server, chromedriver, or `flutter drive`
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Kill `chrome.exe`
> - Use `--no-headless`
> - Use `pumpAndSettle()`
> - Skip `update_chromedriver.bat`
> - Read or evaluate the screenshots — that's the orchestrator's job

If the screenshot test fails to run, work the **STEP 1 TRIAGE** table above.
Only after two distinct triage attempts have failed does the orchestrator stop
and ask the user — with the log tail, the list of screenshots captured, and
what each triage attempt produced. Do NOT skip the run, and do NOT stop before
triage.

---

### STEP 2: EVALUATE every screenshot

**Who does this.** The orchestrator reads and judges every screenshot itself.
It MAY additionally fan out the same set to parallel top-tier lens reviewers
(layout / typography / brand — Playbook §3) and merge their flags; any lens's
flag counts as an issue. What is forbidden is *delegating the judgment away* —
handing evaluation to a cheaper sub-agent and accepting its verdict without
looking. If you fan out, you still read every screenshot yourself.

**Compare against the approved wireframes, not just the checklist.** Phase 2
spent four user-approval gates fixing what these screens should look like.
For each screenshot, open the corresponding approved wireframe and check:
same background treatment, panel positions within ~5% of the viewport, same
fonts and sizes, same option-box heights and gaps, same imagery placement.
**Any divergence the user did not explicitly approve is an issue**, even if it
looks fine on its own — "looks fine" is how a game ends up not matching the
design the user signed off on.

For EACH screenshot image in `temp_screenshots/`:
1. Read the screenshot image file using the Read tool.
2. Diff it against its approved wireframe (above).
3. Check EVERY item on this checklist:

**Layout & Spacing:**
- [ ] No scrolling required on this screen
- [ ] No image clipping or overflow
- [ ] Proper alignment of all UI elements
- [ ] No text overflow or truncation
- [ ] Good screen space utilization

**Typography & Consistency:**
- [ ] Font sizes are correct for the game's design system
- [ ] Fonts match the spec's Style section typography
- [ ] No Nunito font or other container tokens leaking through
- [ ] Adequate text contrast and readability
- [ ] Consistent styling across similar elements

**Visual Quality:**
- [ ] Colors match the game's palette from the spec's Style section
- [ ] No Flame Orange (`#FF6B35`) or other container colors
- [ ] Visual appeal appropriate for the game's theme
- [ ] Family-friendly scale and content
- [ ] Option effects are visible where applicable

**Correctness:**
- [ ] Game characters render correctly (not used as player avatars)
- [ ] All interactive elements clearly identifiable
- [ ] All game states display correct information
- [ ] Button sizes are tappable (touch-friendly)

Also check any game-specific visual items from the spec's Testing Plan visual section.

**You MUST read and evaluate EVERY screenshot. You MUST check EVERY item. Do not evaluate a subset.**

---

### STEP 3: REPORT findings (orchestrator)

```
Visual Validation Report — Cycle N
Screenshots evaluated: X/X

Issues found:
1. [screenshot_name.png] SEVERITY: [High/Medium/Low]
   Description: [what's wrong]
2. ...

Total issues: N
```

Present the full report to the user.

---

### STEP 4: Visual issues found?

**YES (issues > 0):**
- For each issue, identify the specific code change needed (orchestrator decides the fix).
- Dispatch a Sonnet sub-agent with the full fix list as a self-contained brief — include the screenshot filename, the specific issue, the file/line to change, and the desired result.
- After the sub-agent returns, **go back to STEP 1.** Re-capture AND re-evaluate ALL screenshots — fixes can have unintended effects on other screens.

**Per-screen iteration option (when full screenshot test breaks midway):** if the screenshot test fails partway through (e.g., screenshots 1-7 captured, 8-11 missing because step 8 throws), don't loop on the full test. Instead:
1. Diagnose what's wrong with the screen at the failure point (read the partial log + assess widget tree state).
2. Dispatch a focused diagnostic sub-agent to capture JUST the failing screen state via a minimal targeted test that sets up just enough state for that screen.
3. Once that one screen renders, re-run the full screenshot test. Per-screen iteration is much faster than re-running the full ~4-minute screenshot capture for each fix.

**Per-screen iteration is the DEFAULT from cycle 2 onward** — do not re-run the
full capture set for a one-screen fix. Re-run the full set only once every
targeted screen renders clean; the "re-evaluate ALL screenshots" rule still
applies to that full run.

#### Loop control (mandatory — this loop has no natural end)

Maintain in the build-state file:

```json
"phase8": { "cycle": 3,
            "open_issues": [{"shot": "05_game_early", "sev": "High",
                             "desc": "player column overflows 24px",
                             "fix_attempts": 2}] }
```

At the top of every cycle print: `Cycle N — open issues carried in: M`.

- **Per-issue:** after 3 failed fix attempts on the same issue, stop working
  that issue, mark it `escalated`, and carry on with the others. One stubborn
  issue must not block the rest of the cycle.
- **Per-loop:** if `cycle > 3` AND the open-issue count did not decrease
  against the previous cycle, STOP. Write the state file and present a
  convergence report: every open issue, how many times each was attempted,
  what was tried, and the suspected root cause. Then ask the user to choose:
  (a) keep going, (b) accept the listed issues as known, or (c) take over.

The only two ways out of this loop are zero open issues or that report. Never
exit silently, and never keep cycling past the point where progress has
stopped — that is the failure mode where the model appears to give up.

**NO (issues = 0):**
- Continue to STEP 5.

---

### STEP 5: Run UI automation tests (Sonnet sub-agent)

**CRITICAL — driver choice during build vs production:**

During build (Phase 7 + Phase 8, while failure-screenshot wraps from Rule §38 are still in place), tests MUST be invoked via `flutter drive --driver=test_driver/screenshot_test.dart` per test file in foreground. This is the SAME invocation pattern the visual-validation screenshot test uses in Phase 8 STEP 1. Reasons:

- The wraps' `runWithFailureScreenshot` calls write PNG bytes to `temp_screenshots/failures/` ONLY when the `screenshot_test.dart` driver's `onScreenshot` callback is registered. The standard `test_driver/integration_test.dart` driver has no `onScreenshot`, so the wraps silently no-op (no failure pixels written) under the production runner.
- The parallel runner (`run_ui_tests_parallel.bat`) uses the production driver and additionally relies on Windows `start "Worker"` + `git worktree add` to spawn parallel workers. Those Windows-specific commands silently no-op in the orchestrator's MSYS2/Bash sandbox, so the runner returns exit 0 without actually running anything. The orchestrator therefore CANNOT use the parallel runner during the build cycle — it must invoke `flutter drive` directly per test file.

The parallel runner is intended for the post-build pack (Phase 9 onward, after the wraps are removed). Until then: foreground `flutter drive` per file is the only way to actually exercise the tests AND get failure pixels.

**Foreground invocation pattern (canonical):**

```bash
# Reset state ONCE per category before invoking
taskkill /F /IM chromedriver.exe 2>&1 || true
taskkill /F /FI "WINDOWTITLE eq Dart Games*" 2>&1 || true
for /d %D in ("%LOCALAPPDATA%\Temp\flutter_tools.*") do rmdir /S /Q "%D" 2>&1
rm -rf temp_screenshots/failures/*

# Start backend server in background (port 9008 for gladiator_arena per
# docs/testing/ui-automation.md port table)
cd server && dart run bin/server.dart --port 9008 --data-dir ../ui_test_data &

# Start chromedriver in background (port 4444 — flutter drive default)
chromedriver/chromedriver-win64/chromedriver.exe --port=4444 &

# Run each test file individually (sub-agent loops through every *.dart in
# integration_test/[GAME_NAME_SNAKE]/<subdir>/ except _helpers.dart)
flutter drive \
  --driver=test_driver/screenshot_test.dart \
  --target=integration_test/[GAME_NAME_SNAKE]/<subdir>/<test_file>.dart \
  -d chrome \
  --dart-define=SERVER_PORT=9008 \
  --web-browser-flag=--start-maximized \
  --browser-dimension=1920x1080 \
  --web-browser-flag=--no-restore-last-session
```

**Sub-agent prompt template:**

> Run the UI automation tests for the **[GAME_NAME_DISPLAY]** game and report results. Use the FOREGROUND `flutter drive` per-file invocation pattern (NOT the parallel runner — see skill Phase 8 STEP 5 driver-choice note for why).
>
> **Pre-flight:**
> 1. `taskkill /F /IM chromedriver.exe 2>&1 || true`
> 2. `taskkill /F /FI "WINDOWTITLE eq Dart Games*" 2>&1 || true`
> 3. Wipe `%LOCALAPPDATA%\Temp\flutter_tools.*`
> 4. Clear `temp_screenshots/failures/`
> 5. Start backend server background: `cd server && dart run bin/server.dart --port 9008 --data-dir ../ui_test_data`
> 6. Start chromedriver background on port 4444
>
> **Test loop:**
> For each subdirectory in `integration_test/[GAME_NAME_SNAKE]/` (in skill-mandated order: visual_validation, menu_and_settings, add_player, navigation, gameplay, pause_modal, results_screen, save_resume, edit_score, play_to_complete), for each `*_test.dart` file (skip `_helpers.dart`):
>
> ```
> flutter drive \
>   --driver=test_driver/screenshot_test.dart \
>   --target=integration_test/[GAME_NAME_SNAKE]/<subdir>/<test>.dart \
>   -d chrome --dart-define=SERVER_PORT=9008 \
>   --web-browser-flag=--start-maximized --browser-dimension=1920x1080 \
>   --web-browser-flag=--no-restore-last-session
> ```
>
> Capture exit code + look for "All tests passed!" / "Some tests failed:" / "Failure Details:" in output.
>
> **For each failing test:**
> - Note the test file path
> - Read the failure stack trace from flutter drive output
> - List any failure screenshots in `temp_screenshots/failures/` (path + size)
>
> **Hung-process safety:** if a single `flutter drive` invocation runs longer than 5 minutes, KILL it (taskkill chromedriver + close test windows) and mark the test FAILED with a "TIMEOUT" reason.
>
> **Tear down:** kill chromedriver, kill backend server.
>
> **Report back:**
> - Total tests attempted
> - Pass/fail count broken down by subdirectory
> - For each failure: test path + error message excerpt + failure screenshot path (if captured)
> - Total runtime
>
> **Hard rules:**
> - Do NOT attempt to fix failing tests — only report them. Orchestrator triages root causes.
> - Do NOT use the parallel runner.
> - Do NOT skip individual tests. Every test must be attempted.
> - Do NOT kill chrome.exe globally — only chromedriver.exe and test windows by title.

If chromedriver is not available or tests cannot run:
- Orchestrator STOPs immediately.
- Tell the user which tests cannot run and why.
- Ask the user how to proceed.
- Do NOT skip. Do NOT proceed without running them.

---

### STEP 6: UI tests fail? (orchestrator decision)

**YES (any failures):**
- Orchestrator analyzes failures (root-cause reasoning).
- Present to user per `docs/critical-rules/test-failures.md`: "Tests failed. (A) Fix application code, or (B) Update tests?"
- Wait for user decision. Do NOT auto-fix tests.
- Dispatch a Sonnet sub-agent with the specific fix per user choice.
- **Go back to STEP 1.** Screenshots may have changed due to fixes.

**NO (all pass):**
- Continue to STEP 7.

---

### STEP 7: Run all non-UI tests (Sonnet sub-agent or orchestrator)

Run BOTH:
- `flutter test`
- `cd server && dart test`

This runs ALL non-UI tests across ALL games and the entire server. Either path is fine — Sonnet sub-agent for cleaner parallelism, or orchestrator running directly via Bash for simplicity.

---

### STEP 8: Non-UI tests fail? (orchestrator decision)

**YES (any failures in flutter test OR server test):**
- Orchestrator analyzes failures.
- Present to user per `docs/critical-rules/test-failures.md`.
- Wait for user decision. Dispatch a Sonnet sub-agent with the fix.
- **Go back to STEP 1.** Start the entire cycle over.

**NO (all pass):**
- Continue to STEP 9.

---

### STEP 9: All pass simultaneously

All four conditions are now true at the same time:
- Visual validation: zero issues
- UI automation tests: 100% pass
- Flutter non-UI tests: 100% pass
- Server tests: 100% pass

Proceed to STEP 10 (final user acceptance).

---

### STEP 10: FINAL USER ACCEPTANCE GATE (mandatory)

After the orchestrator's iterative review passes, present the FINAL screenshot set + Phase 2 wireframes to the user for explicit acceptance:

> "All gates have passed internally. Before we move to documentation, please review the final visual state:
>
> 1. Open `temp_screenshots/` and review every captured screenshot.
> 2. Open `temp_wireframes/[GAME_NAME_SNAKE]/index.html` and compare against the Phase 2 wireframes you originally approved.
>
> Confirm:
> - The implementation matches the wireframe intent (colors, fonts, layout, character/imagery use).
> - All player counts (min/mid/max) render correctly.
> - All option states are represented (defaults, alternates, ON/OFF toggles).
> - All screens look polished and family-friendly at scale.
>
> Reply: ✅ **Accept** (proceed to AR-7) — OR — 🔧 list specific UI changes you'd like."

**STOP and wait for user response.**

If the user requests changes:
- Dispatch a Sonnet sub-agent to apply the UI fixes to the relevant screen file(s).
- After the sub-agent returns, **go back to STEP 1.** Re-capture AND re-evaluate ALL screenshots.
- Then re-run the UI test suite (STEP 5) and non-UI tests (STEP 7).
- Repeat the entire Phase 8 cycle until the user explicitly accepts.

**Do NOT proceed to AR-7 until the user has explicitly accepted.** The orchestrator's "all gates pass" is necessary but not sufficient — final visual judgement is the user's.

---

### Adversarial Review AR-7: Validation Completeness (orchestrator)

**Before leaving Phase 8, answer every question honestly. If any answer is "no", go back and complete the missing step.**

> "(a) Did I run `update_chromedriver.bat` before the screenshot test?
> (b) Did I start the backend server before the screenshot test?
> (c) Did I actually RUN the screenshot test (not just write it)?
> (d) Did I actually READ every screenshot image with the Read tool (not just assume they were fine)?
> (e) For each screenshot, did I check EVERY item on the full checklist (not a subset)?
> (f) After EVERY fix, did I go back to Step 1 and re-capture AND re-evaluate ALL screenshots (not just the changed ones)?
> (g) Did I run the UI automation tests with `run_ui_tests.bat` (not just the non-UI tests)?
> (h) Did I run BOTH `flutter test` AND `cd server && dart test` after the UI tests passed?
> (i) Are ALL four (visual clean + UI pass + flutter test pass + server test pass) true RIGHT NOW, simultaneously?
>
> Answers: (a) [Y/N] (b) [Y/N] (c) [Y/N] (d) [Y/N] (e) [Y/N] (f) [Y/N] (g) [Y/N] (h) [Y/N] (i) [Y/N]
>
> If any answer is NO, I will go back and complete the missing step before proceeding."

---
