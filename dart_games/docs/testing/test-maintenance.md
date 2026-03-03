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

### Files That Must Stay in Sync

- `ui_test_helpers.dart` - Navigation, player management
- `element_finders.dart` - Widget key-based finders
- `provider_helpers.dart` - Provider state access
- `settings_helpers.dart` - Settings and configuration
- `edit_score_helpers.dart` - Edit score dialog operations
- `results_helpers.dart` - Results screen verification
- `pump_sequences.dart` - Animation and async waiting
- `game_ui_config.dart` - Game-specific UI configuration

### Exception: Integration-Test-Only Files

Some files only exist in `integration_test/shared/` because they're specific to UI automation:
- Screenshot test helpers
- Web driver utilities
- Browser-specific functions

**Rule:** If a file exists in both locations, keep them in sync. If it only exists in one, that's intentional.

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
- All 272+ tests passing

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
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
