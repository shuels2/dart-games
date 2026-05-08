# Test Maintenance

## CRITICAL: Shared Test Helper Synchronization

**The `test/shared/` and `integration_test/shared/` folders MUST be kept in sync at all times.**

### Why This Matters

- **Non-UI tests** use helpers from `test/shared/`
- **UI automation tests** use helpers from `integration_test/shared/`
- Both test suites test the same features using the same helper functions
- Divergence causes tests to fail inconsistently or produces false positives/negatives

### Synchronization Rules

When modifying any file in either shared folder:

1. **Check both locations** - The file likely exists in both `test/shared/` and `integration_test/shared/`
2. **Update both files** - Apply the same changes to both versions
3. **Verify consistency** - Ensure both files have the same:
   - Function signatures
   - Helper methods
   - Element finders
   - Provider accessors
   - Settings manipulation functions
4. **Test both suites** - Run both non-UI tests (`flutter test`) and UI tests to verify

### Files That Must Stay in Sync — Discovered Dynamically

The set of mirrored helpers is NOT a hardcoded list. The rule:

> **For every `*.dart` file present in BOTH `integration_test/shared/` and `test/shared/`, the two copies MUST stay byte-identical.**

Discover the current set with `ls`:

```bash
ls integration_test/shared/*.dart
ls test/shared/*.dart        # superset — includes non-UI-only helpers
```

Earlier versions of this doc enumerated "11 mirrored helpers" and "the 12 mirrored files" by name. Those lists went stale every time a new helper was added without doc updates. The list-free rule auto-tracks reality: when a helper is added to both folders, it's automatically in scope; when one is removed, it's automatically out of scope.

**Verify all mirrored pairs are byte-identical:**

```bash
diff -rq integration_test/shared test/shared 2>&1 | grep "differ" || echo "OK"
```

`diff -rq` walks both directories and emits one line per file pair. The `grep "differ"` filter strips expected `Only in <dir>: <file>` lines for intentionally non-mirrored helpers and shows only divergence (`Files X and Y differ`). On a clean tree, the output is empty.

### Exception: Single-Directory Files Are Intentional

Some files exist in only one directory because they import packages or use APIs only available in that directory's compile context:

- `test/shared/` only: `mock_api_helpers.dart`, `player_test_utils.dart`, `sector_parser.dart` — and their `*_test.dart` counterparts. These import non-UI testing packages (e.g. `package:test`) and have no UI-test analogue.
- `integration_test/shared/` only: any helper that imports `package:integration_test` or uses `IntegrationTestWidgetsFlutterBinding`, `WidgetTester`-only types, etc. Currently none, but the category exists by design.

**Rule:** if a file exists in both locations, keep them in sync. If it exists in only one, that's intentional — the parity audit (`diff -rq … | grep differ`) automatically excludes it via the `Only in` exclusion.

### Caveat — `flutter drive` web compile cache

Brand-new files under `integration_test/shared/` are silently ignored by the web compile cache (commit `4d1377e`). When a UI test imports such a file, compilation fails with `org-dartlang-app:/...File not found` even though `dart analyze` finds the file.

**Workaround:** add the new functionality as a static method on an existing long-lived helper class (e.g. `UITestHelpers` in `ui_test_helpers.dart`) instead of creating a new shared file. The `UITestHelpers.runWithFailureScreenshot` method was placed inside `ui_test_helpers.dart` for exactly this reason — see `failure_screenshot_helper.dart` in commit `3cafc83` (deleted) for the pattern that didn't work.

### Game-Specific `_helpers.dart` Convention

Each game's test subdirectories have `_helpers.dart` files that **delegate** to shared helpers rather than duplicating code. When a shared helper changes:

1. Update the shared file in both `test/shared/` and `integration_test/shared/`
2. Game-specific `_helpers.dart` files automatically pick up the changes (they call shared functions, not copy them)
3. Only update game-specific helpers if you're changing a function signature

See [Shared Helpers Reference](shared-helpers-reference.md) for the full list of shared helpers and the delegate pattern.

## When Features Change

**When updating features, tests MUST be updated to match.**

This ensures test coverage remains accurate and complete.

## Process

### 1. Ask User

When you update a feature:

```
I've updated the [feature name]. Would you like me to update 
the tests to cover the new functionality?
```

### 2. If User Says Yes

- Update existing tests affected by changes
- Add new tests to cover new functionality
- Ensure all tests pass
- Run `flutter test` to verify 100% pass rate

### 3. Update Documentation

Update these documentation files:
- Main CLAUDE.md with new test counts
- Test Overview section with new totals
- Game-specific test documentation
- Test breakdown sections

### 4. Commit Test Updates

Include test updates in same commit OR create separate commit:

```bash
git commit -m "Updated tests for [feature name]

- Added [N] tests for new functionality
- Updated [M] tests for changed behavior
- All 1198+ tests passing

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

## Important Notes

- Never leave tests broken after feature updates
- Test coverage should never decrease
- Breaking changes MUST have corresponding test updates
- If tests temporarily disabled, document why and create task to fix

## Example Workflow

```
User: "Update player photo feature to support GIF files"

Claude:
1. Updates code to support GIF files
2. Asks: "Would you like me to update the PlayerProvider 
   tests to cover GIF file handling?"

User: "yes"

Claude:
1. Adds tests for GIF handling
2. Runs flutter test - now 275 tests (was 272)
3. Updates CLAUDE.md with new test count
4. Commits changes with updated documentation
```

## Test Count Updates

When test count changes:

### Main CLAUDE.md
Update test suite totals and breakdowns

### Test Overview (docs/testing/test-overview.md)
Update all test counts and breakdowns

### Non-UI Tests (docs/testing/non-ui-tests.md)
Update category breakdowns

### Game Documentation
Update game-specific test counts

## Related Documentation

- [Test Overview](test-overview.md)
- [Critical Rules - Test Failures](../critical-rules/test-failures.md)
- [Build Process](../deployment/build-process.md)
