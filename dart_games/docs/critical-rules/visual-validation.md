# Critical Rule: Visual Validation and Game Completion Gates

## Overview
**NEVER skip visual validation, UI test verification, or any completion gate when developing a new game.**

A game is NOT complete until all validation steps have been actually executed (not just planned or written) and pass simultaneously.

## The Problem

Visual validation and UI test runs are the final quality gate before a game can be considered complete. Skipping them means:
- Visual bugs (overflow, clipping, misalignment) ship undetected
- UI automation tests may fail due to integration issues never caught
- The spec's Definition of Done is not actually verified
- The user receives incomplete work presented as complete

## Mandatory Completion Gates

Every new game MUST pass ALL of these gates before proceeding to documentation or being marked complete:

### Gate 1: Screenshot Tests
1. **Run** the screenshot test to capture screenshots of every game state
2. **Evaluate** EVERY screenshot against the spec's visual evaluation checklist
3. **Fix** any visual issues found (overflow, clipping, misalignment, poor contrast, etc.)
4. **Re-run** screenshots and re-evaluate until zero visual issues remain

### Gate 2: UI Automation Tests
1. **Run** ALL UI automation tests for the new game
2. **Fix** any test failures (in application code, not by removing tests)
3. **Re-run** until 100% of UI tests pass

### Gate 3: Non-UI Tests
1. **Run** `flutter test` to verify all non-UI tests still pass
2. **Fix** any regressions introduced during visual fixes
3. **Re-run** until 100% pass

### Gate 4: Simultaneous Pass
All three gates must pass AT THE SAME TIME. If fixing a visual issue breaks a UI test, or fixing a UI test breaks a non-UI test, the cycle must repeat until all are clean simultaneously.

### Gate 5: Spec Definition of Done
Every item in the game spec's Definition of Done checklist must be verified and the results reported to the user.

## Prohibited Actions

- **NEVER** skip a gate because "it requires manual setup" — ask the user for help instead
- **NEVER** skip a gate because "the test files were already written" — writing tests is not the same as running them
- **NEVER** skip a gate because "it seems like a visual-only step" — visual quality is a requirement
- **NEVER** mark a gate as complete without actually executing it
- **NEVER** move to documentation while any gate is incomplete
- **NEVER** rationalize skipping with any justification — there is no valid reason to skip

## When a Gate Cannot Be Run

If a gate cannot be executed (e.g., chromedriver is not available, environment issue):
1. **STOP** immediately
2. **Tell the user** which gate cannot be run and why
3. **Ask the user** how to proceed
4. **Do NOT** skip the gate or proceed without it

## Iterative Fix Cycle

**CRITICAL:** "Screenshot test passed" does NOT mean "visual validation complete." A passing test only means the screenshots were captured without runtime errors. The actual validation is reading and evaluating every screenshot against the checklist. These are two completely separate steps — never conflate them.

The fix cycle works as follows:

```
1. CAPTURE: Run screenshot test → confirm all screenshots saved
2. EVALUATE: Read EVERY screenshot with the Read tool → check EVERY
   item on the visual evaluation checklist for EACH screenshot
3. REPORT: List all issues found (screenshot number, severity, description)
4. Found visual issues? → Fix them → Go to step 1
   (MUST re-capture AND re-evaluate ALL screenshots, not just fixed ones)
5. No visual issues? → Run UI automation tests
6. UI tests fail? → Fix them → Go to step 1 (screenshots may have changed)
7. UI tests pass? → Run flutter test
8. Non-UI tests fail? → Fix them → Go to step 1
9. All pass simultaneously? → Verify spec Definition of Done → DONE
```

The key insights:
- **Capturing ≠ Evaluating.** You must do both, every time.
- **Fixing anything sends you back to step 1** — re-capture AND re-evaluate all screenshots.
- **Evaluate ALL screenshots every cycle**, not just the ones you expect changed — fixes can have unintended effects on other screens.

## Visual Evaluation Checklist

When evaluating screenshots, check for:
- No scrolling required on any screen
- No image clipping or overflow
- Proper alignment of all UI elements
- No text overflow or truncation
- Good screen space utilization
- Consistent typography (correct fonts, sizes, weights)
- Adequate text contrast and readability
- Visual appeal appropriate for the game's theme
- Family-friendly scale and content
- All interactive elements are clearly identifiable
- Game characters render correctly
- All game states display the correct information

## Screenshot Test Technical Requirements

When running screenshot tests, follow these rules exactly to avoid debugging infrastructure issues:

### Use the Correct Driver
Screenshot tests MUST use `test_driver/screenshot_test.dart`, NOT `test_driver/integration_test.dart`. The standard driver has no `onScreenshot` callback, so `binding.takeScreenshot()` will hang silently.

```bash
# CORRECT
flutter drive --driver=test_driver/screenshot_test.dart \
  --target=integration_test/<game>_screenshot_test.dart -d chrome

# WRONG — will hang on first takeScreenshot() call
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/<game>_screenshot_test.dart -d chrome
```

### Follow Existing UI Test Patterns
Before writing or running screenshot tests, reference `run_ui_tests.bat` for the established launch pattern:
- Kill and restart chromedriver before each test
- Do NOT use `--no-headless` flag
- Wait 5 seconds after starting chromedriver before launching tests

### Never Use pumpAndSettle() in Integration Tests
The splash screen has a `CircularProgressIndicator` that prevents `pumpAndSettle()` from ever completing. Use manual `pump()` sequences instead. See [Continuous Animations](../testing/continuous-animations.md).

### Never Kill All Chrome Processes
Only kill `chromedriver.exe`. Killing all `chrome.exe` processes destroys the user's browser sessions and leaves Chrome in a crash recovery state that causes `AppConnectionException` errors on subsequent runs.

### ChromeDriver Session Management
- Restart chromedriver before each screenshot test run
- If `AppConnectionException` occurs: open Chrome manually, dismiss any crash recovery dialogs, close Chrome, restart chromedriver, retry

## Summary

**Visual validation is not optional.** It is a mandatory quality gate that must be executed, not just planned. No rationalization justifies skipping it. If it cannot be run, stop and ask the user.
