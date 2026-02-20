# Critical Rule: Handling Test Failures

## Overview
**NEVER automatically update tests to make them pass without user approval.**

When tests fail after making code changes, you must stop, analyze, and ask the user for direction.

## The Problem

Automatically updating tests to pass can hide real bugs in the application code. Tests often catch legitimate regressions introduced by code changes.

## Procedure When Tests Fail

### 1. STOP and Analyze

When tests fail after making code changes:

- **Read the test failure messages carefully**
- **Understand what functionality the test is validating**
- **Determine if the test is catching a bug** in the new code OR if the test is outdated

Do NOT assume the test needs updating.

### 2. Ask the User for Direction

Present the test failure details to the user and ask:

```
The tests are failing. Would you like me to:
  (A) Fix the application code to make the existing tests pass, OR
  (B) Update the tests to match the new application behavior?
```

**Wait for explicit user choice before proceeding.**

### 3. After User Decision

**If (A) - Fix Application Code:**
- Fix the application code while preserving test requirements
- Re-run `flutter test` to verify 100% pass rate
- Only then proceed with build/commit

**If (B) - Update Tests:**
- Update tests to match new application behavior
- **Update CLAUDE.md** with new test count/descriptions
- Re-run `flutter test` to verify 100% pass rate
- Document what tests were changed and why
- Only then proceed with build/commit

## Example Workflow

### ❌ WRONG Approach

```
Scenario: After updating player management, 3 tests fail

1. Automatically modify tests to pass
2. Proceed with build
```

This is **dangerous** because:
- The tests might be catching real bugs
- You may lose test coverage
- Application bugs get shipped to production

### ✅ CORRECT Approach

```
Scenario: After updating player management, 3 tests fail

1. Analyze the 3 failing tests
2. Present to user:
   "Tests are failing because the new code changes how player names
   are validated. Would you like me to:
   (A) Revert the validation changes to match the test expectations, OR
   (B) Update the tests to accept the new validation logic?"
3. Wait for user choice
4. Implement the chosen solution
5. Re-run tests to verify all pass
```

This is **correct** because:
- User makes the decision about intended behavior
- Tests might be catching real bugs (user can confirm)
- Changes are intentional and documented

## Types of Test Failures

### Regression Bug (Fix Application Code)

**Example:**
```
Test: "Player names should not be empty"
Failure: "Expected false, got true"
Cause: New code accidentally allows empty names
Solution: Fix application code
```

### Intentional Behavior Change (Update Tests)

**Example:**
```
Test: "Player names should be max 20 characters"
Failure: "Expected 20, got 30"
Cause: You changed the max length to 30 characters
Solution: Update test (with user approval)
```

## When Tests Are Updated

If the user approves updating tests:

1. **Update the test code** to reflect new behavior
2. **Update CLAUDE.md:**
   - Update test counts if tests were added/removed
   - Update test descriptions if behavior changed
3. **Document the change:**
   - What tests were modified
   - Why they were modified
   - What the new behavior validates
4. **Verify all tests pass:**
   ```bash
   flutter test
   ```

## Red Flags

These situations require **extra caution**:

- ❌ Many tests failing after a small code change
  - Likely indicates a bug in the code, not outdated tests

- ❌ Core functionality tests failing
  - User management, dartboard, scoring, etc.
  - These are well-established; failure likely means regression

- ❌ All tests for a specific feature failing
  - Suggests fundamental change to feature
  - User should confirm this is intentional

- ❌ Tests passing locally but failing in CI
  - Environment issue or flakiness
  - Don't just update tests; fix the root cause

## Communication Template

When tests fail, use this template:

```
[X] tests are failing after [description of changes made].

Failing tests:
1. [Test name] - [Failure reason]
2. [Test name] - [Failure reason]
3. [Test name] - [Failure reason]

Analysis:
[Your analysis of why tests are failing]

Options:
(A) Fix the application code to make existing tests pass
    [Brief description of what would be fixed]

(B) Update the tests to match the new application behavior
    [Brief description of what tests would change]

Which approach would you prefer?
```

## Test Update Documentation

If tests are updated, document in commit message:

```
Updated [N] tests to match new [feature] behavior

Modified tests:
- test/path/to/test1.dart - [what changed]
- test/path/to/test2.dart - [what changed]

Reason: [Why the behavior changed]

Previous behavior: [description]
New behavior: [description]
```

## Summary

**Never automatically update tests.** Tests are the safety net that catches bugs. Respect them by:

1. Analyzing why they fail
2. Asking the user for direction
3. Implementing the user's choice
4. Documenting changes
5. Verifying all tests pass

This ensures code quality and prevents bugs from reaching production.
