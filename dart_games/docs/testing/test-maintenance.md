# Test Maintenance

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
