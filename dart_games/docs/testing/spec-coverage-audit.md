# Spec Coverage Audit

## Overview

A spec coverage audit verifies that every game option, visual element, and game mode defined in the spec has corresponding test coverage in both non-UI and UI test suites. This audit is a **mandatory completion gate** — a game cannot be marked complete until 100% spec coverage is confirmed.

## Why This Exists

Writing tests is not the same as writing *sufficient* tests. It is common to write tests for the "happy path" while missing coverage for specific options (e.g., Cursed Tide mode, Bonus Buffs, Random Reefs, Speed Play). The spec defines exactly what must be testable, and the audit ensures nothing is missed.

## When to Run

Run a spec coverage audit:
- **After all tests are initially written** for a new game
- **Before marking any game phase as complete** that involves testing
- **After adding new options or features** to an existing game
- **As part of the New Game Completion Gates** (Gate 1)

## Audit Procedure

### Step 1: Extract Spec Requirements

Read the game's spec file and extract three lists:

**A. Options Table (Spec Section 7)**
List every game option with its expected behavior:
```
| Option           | Default | Expected Effect                    |
|------------------|---------|------------------------------------|
| Game Mode        | Standard| Cursed Tide reverses pearl flow    |
| Easy Claim       | OFF     | Claim threshold drops to 2 marks   |
| Neighbor Numbers | OFF     | Adjacent numbers count as 1 mark   |
| Random Reefs     | OFF     | Targets randomized each game       |
| Bonus Buffs      | OFF     | Random buffs activate each round   |
| Show Hints       | ON      | Hint overlay visible during play   |
| Speed Play       | OFF     | Round counter visible, game ends   |
| Round Limit      | 10      | Adjustable via slider (5-20)       |
```

**B. Visual Elements (Spec Section 10)**
List every visual element that should have a widget key and be testable:
```
- Coral cards (7 targets)
- Player avatar
- Pearl counter
- Coral counter
- Dart indicators (D1, D2, D3)
- Buff banner
- Round counter
- Hint overlay
- Cursed badge
- Opponent summary tiles
- Skip turn button
- Edit score button
```

**C. Test Requirements (Spec Section 12)**
List every test the spec explicitly requires, organized by test file.

### Step 2: Map Tests to Requirements

For EACH item from Steps A, B, and C, search the actual test files to find matching coverage:

**Non-UI tests** (`test/screens/games/[game_name]/`):
- Does a test exercise this option's logic?
- Does a test verify the option changes game behavior?

**UI tests** (`integration_test/[game_name]_*.dart`):
- Does a test toggle/set this option in the UI?
- Does a test verify the option's visual effect on the game screen?
- Does a test verify the widget key exists?

### Step 3: Build Coverage Matrix

Create a coverage matrix like this:

```
| Requirement              | Non-UI Test? | UI Test?  | Gap? |
|--------------------------|--------------|-----------|------|
| Standard mode scoring    | Yes (T40)    | Yes (T8)  | No   |
| Cursed Tide mode         | Yes (T45)    | No        | YES  |
| Easy Claim threshold     | Yes (T34)    | Yes (T10) | No   |
| Buff Riptide Rush        | Yes (T54)    | No        | YES  |
| Buff Pearl Fever         | Yes (T55)    | No        | YES  |
| Random Reefs variation   | Yes (T18)    | No        | YES  |
| Speed Play round counter | Yes (T63)    | No        | YES  |
| Buff banner widget       | N/A          | No        | YES  |
| Opponent summary tiles   | N/A          | No        | YES  |
```

### Step 4: Report Gaps

Present the coverage matrix to the user with a clear summary:
```
Spec Coverage Audit Results:
- Total requirements: 25
- Covered: 18 (72%)
- Gaps: 7 (28%)

Missing non-UI tests:
1. [description]
2. [description]

Missing UI tests:
1. [description]
2. [description]
```

### Step 5: Write Missing Tests

For each gap identified:
1. Determine if infrastructure changes are needed (new provider methods, new helpers)
2. Write the missing tests
3. Run all tests to verify they pass

### Step 6: Re-audit

After writing missing tests, repeat Steps 2-4 to confirm 100% coverage. The audit is complete only when every row in the coverage matrix shows "No" in the Gap column.

## What Counts as Coverage

### Non-UI Test Coverage
A spec option is covered by a non-UI test if:
- The test creates a game with that option enabled
- The test verifies the option changes game behavior (e.g., marks, pearls, win conditions)
- Edge cases are tested (e.g., multi-player distribution for Cursed Tide)

### UI Test Coverage
A spec option is covered by a UI test if:
- The test toggles/sets the option in the menu screen, OR
- The test starts a game with the option enabled and verifies the visual effect, OR
- The test verifies a widget key exists for the option's visual indicator

### Visual Element Coverage
A visual element is covered if:
- A UI test verifies the widget key exists (`find.byKey(...)`)
- The element appears correctly after relevant game actions

## Infrastructure Patterns

When writing tests for missing coverage, you may need:

### Provider Test Helpers
Add methods to `ReefRoyaleProvider` (or equivalent) for programmatic state manipulation:
```dart
void setActiveBuff(ReefBuff? buff)  // For testing buff effects
```

### Settings Helpers
Add methods to `integration_test/shared/settings_helpers.dart`:
```dart
static Future<void> setGameMode(tester, 'Cursed Tide')
```

### Provider Helpers
Add methods to `integration_test/shared/provider_helpers.dart`:
```dart
static void setActiveBuff(tester, buff)
static GameMode? getGameMode(tester)
```

## Common Gaps to Watch For

Based on past audits, these areas are frequently under-tested:

1. **Alternate game modes** (e.g., Cursed Tide) — easy to test standard but forget the variant
2. **Buff/power-up effects** — random activation makes them hard to test without provider helpers
3. **Visual indicators for options** — widget keys exist but no test verifies they appear
4. **Multi-player edge cases** — 2-player tests pass but 3+ player distribution is untested
5. **Speed Play / round limits** — timer/counter UI elements need explicit verification
6. **Edit score interactions with options** — editing darts when buffs or special modes are active
7. **Random elements** — Random Reefs, random buffs need statistical or programmatic tests

## Audit Checklist

Use this checklist for each new game:

- [ ] Extracted all options from spec Section 7
- [ ] Extracted all visual elements from spec Section 10
- [ ] Extracted all test requirements from spec Section 12
- [ ] Mapped every non-UI test to requirements
- [ ] Mapped every UI test to requirements
- [ ] Built coverage matrix
- [ ] Reported gaps to user
- [ ] Wrote all missing tests
- [ ] Re-audited to confirm 100% coverage
- [ ] All tests pass simultaneously (non-UI + UI)
