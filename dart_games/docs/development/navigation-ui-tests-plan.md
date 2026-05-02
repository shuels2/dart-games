# Navigation UI Tests — All 5 Games

## Context
The Clockwork Quest `(route) => false` bug was fixed and documentation updated. Now we need UI tests that catch this class of bug across all 5 games. The audit found:

- **No test exercises the full results → change settings → menu → back → home flow** (the exact bug path)
- **Menu back → home tests**: only Clockwork Quest has one (4 games missing)
- **Game back → menu with settings persistence**: no game tests this
- **Change settings tests exist but don't verify settings preservation** (except CQ players-only)
- **Play again tests exist** but some don't verify settings carried over

## Plan

### Step 1: Add Missing ElementFinders

**File:** `integration_test/shared/element_finders.dart`

Add 2 missing menu back button finders:
```dart
static Finder getCarnivalDerbyBackButton() =>
    find.byKey(CarnivalDerbyMenuKeys.backButton);
static Finder getTargetTagBackButton() =>
    find.byKey(TargetTagMenuKeys.backButton);
```

### Step 2: Create Navigation Test Files (20 new tests across 5 games)

Each game gets a `navigation/` subfolder with 4 test files. Each test is standalone (own `main()`, own server reset).

#### Test 1: Menu Back → Home (4 new tests, CQ already has one)

**Pattern** (from CQ `back_button_test.dart`):
```
resetServerState → navigateToGameMenu → tap menu back button → verify home screen game cards
```

**New files:**
- `integration_test/target_tag/navigation/menu_back_to_home_test.dart`
- `integration_test/carnival_derby/navigation/menu_back_to_home_test.dart`
- `integration_test/monster_mash/navigation/menu_back_to_home_test.dart`
- `integration_test/reef_royale/navigation/menu_back_to_home_test.dart`

**Verification:** Assert ≥3 game cards visible (CarnivalDerby, TargetTag, MonsterMash).

#### Test 2: Game Back → Menu with Settings Persistence (5 new tests)

**Pattern:**
```
resetServerState → navigateToGameMenu → change non-default settings → addPlayers → startGame
→ tap game back button → (if save modal, tap Don't Save) → verify on menu screen
→ verify all changed settings still show their non-default values
```

**New files:**
- `integration_test/target_tag/navigation/game_back_settings_persist_test.dart`
- `integration_test/carnival_derby/navigation/game_back_settings_persist_test.dart`
- `integration_test/monster_mash/navigation/game_back_settings_persist_test.dart`
- `integration_test/reef_royale/navigation/game_back_settings_persist_test.dart`
- `integration_test/clockwork_quest/navigation/game_back_settings_persist_test.dart`

**Settings to change per game:**
- **Target Tag:** shieldMax → 5, toggle teamMode on
- **Carnival Derby:** targetScore → 180, perfectFinish → Yes
- **Monster Mash:** healthMax → 20, toggle bonusBuffs on
- **Reef Royale:** toggle easyClaim on, toggle bonusBuffs on
- **Clockwork Quest:** toggle includeBullseye on, toggle speedMode on

**Verification:** After navigating back to menu, find the settings UI elements and verify they show the non-default values. Use `find.text(...)` for displayed values.

#### Test 3: Results → Change Settings → Menu → Back → Home (5 new tests)

This is the exact bug path that was fixed. Each test completes a game, navigates through the full chain, and verifies landing on home.

**Pattern:**
```
resetServerState → navigateToGameMenu → (set settings) → addPlayers → startGame
→ completeGameToVictory → clickChangeSettings → verify on menu
→ tap menu back button → verify home screen with ≥3 game cards
```

**New files:**
- `integration_test/target_tag/navigation/change_settings_back_to_home_test.dart`
- `integration_test/carnival_derby/navigation/change_settings_back_to_home_test.dart`
- `integration_test/monster_mash/navigation/change_settings_back_to_home_test.dart`
- `integration_test/reef_royale/navigation/change_settings_back_to_home_test.dart`
- `integration_test/clockwork_quest/navigation/change_settings_back_to_home_test.dart`

**Completion strategies per game:**
- **Target Tag:** Use `_helpers.dart` `completeGameToVictory()` (shieldMax 3, 2 players)
- **Carnival Derby:** Set targetScore 180, throw 3x T20 = 180 win
- **Monster Mash:** Use `_helpers.dart` `completeGameToVictory()` (healthMax 10, 2 players)
- **Reef Royale:** Use `_helpers.dart` `completeGameToVictory()` (claim 7 targets)
- **Clockwork Quest:** Use `_helpers.dart` `completeGameToVictory()` (hit 1-20)

#### Test 4: Results → Change Settings → Verify Settings Preserved (5 new tests)

**Pattern:**
```
resetServerState → navigateToGameMenu → change non-default settings → addPlayers → startGame
→ completeGameToVictory → clickChangeSettings → verify menu shows same non-default settings
```

**New files:**
- `integration_test/target_tag/navigation/change_settings_preserves_settings_test.dart`
- `integration_test/carnival_derby/navigation/change_settings_preserves_settings_test.dart`
- `integration_test/monster_mash/navigation/change_settings_preserves_settings_test.dart`
- `integration_test/reef_royale/navigation/change_settings_preserves_settings_test.dart`
- `integration_test/clockwork_quest/navigation/change_settings_preserves_settings_test.dart`

**Settings & verification per game:**
- **Target Tag:** Set shieldMax 5 → after change settings, verify `find.text('Shield Max: 5')`
- **Carnival Derby:** Set targetScore 180 → verify `find.textContaining('180')`
- **Monster Mash:** Set healthMax 20, toggle bonusBuffs → verify displayed values
- **Reef Royale:** Toggle easyClaim on → verify toggle state
- **Clockwork Quest:** Toggle includeBullseye on → verify checkbox checked via provider

### Step 3: Create Shared Navigation Helpers

**File:** `integration_test/shared/navigation_helpers.dart` (new file)

Extract common patterns:
```dart
class NavigationHelpers {
  /// Verify we're on the home screen by checking for multiple game cards
  static void verifyHomeScreen(WidgetTester tester) {
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  }
  
  /// Tap menu back button using the game's ElementFinders method
  static Future<void> tapMenuBackButton(WidgetTester tester, String game) async {
    // Game-specific back button finder
  }
}
```

### Step 4: Create Per-Game _helpers.dart in navigation/ Folders

Each `navigation/` folder gets a `_helpers.dart` that imports the game's existing results `_helpers.dart` and re-exports `completeGameToVictory` plus any setup functions needed.

### File Summary

| Category | Files | Tests |
|----------|-------|-------|
| ElementFinders update | 1 file modified | — |
| Navigation helpers (new) | 1 new shared file | — |
| Menu back → home | 4 new test files | 4 tests |
| Game back → menu + settings | 5 new test files | 5 tests |
| Change settings → back → home | 5 new test files | 5 tests |
| Change settings → verify settings | 5 new test files | 5 tests |
| Per-game nav _helpers | 5 new files | — |
| **Total** | **~26 files** | **19 new tests** |

Note: Clockwork Quest already has a menu back → home test, so 19 new tests total (not 20).

### Key Files to Reuse
- `integration_test/shared/game_ui_config.dart` — GameUIConfig factories for all games
- `integration_test/shared/element_finders.dart` — game card finders, back button finders
- `integration_test/shared/ui_test_helpers.dart` — navigateToGameMenu, addPlayer, startGame, resetServerState
- `integration_test/shared/pump_sequences.dart` — navigation, simpleUpdate, fullRebuild
- `integration_test/shared/settings_helpers.dart` — toggle/set helpers for all game settings
- `integration_test/shared/results_helpers.dart` — clickPlayAgain, clickChangeSettings, clickBackToMenu
- Each game's existing `results_screen/_helpers.dart` — completeGameToVictory functions

### Step 5: Update Documentation for Future Games

Ensure new games are required to create these navigation tests from the start.

#### `docs/development/adding-games.md`
In Step 15 (Create Tests), add a **Navigation UI Tests** subsection listing the 4 mandatory navigation tests every game must have:
1. Menu back → home (verify ≥3 game cards)
2. Game back → menu with settings persistence (change non-default settings, start game, go back, verify settings preserved)
3. Results → Change Settings → menu → back → home (the full chain)
4. Results → Change Settings → verify settings preserved

Add corresponding checklist items to the bottom checklist.

#### `docs/development/game-integration.md`
In Section 6 (Navigation Rules), add a "Required Navigation Tests" subsection referencing the 4 test patterns above with the expected file locations (`integration_test/your_game/navigation/`).

#### `docs/testing/test-overview.md`
Update test counts to include the new navigation tests (19 new UI tests → update total from 395 to 414).

#### `docs/games/_GAME_TEMPLATE/testing.md`
Add a Navigation Tests section listing the 4 required test files with the expected patterns and file names.

## Verification
1. Run `flutter test` — all 1190+ non-UI tests still pass
2. Run each new test individually via `run_ui_tests.bat` to confirm they pass
3. Verify the "change settings → back → home" test would have caught the original CQ bug (it navigates the exact broken path)
4. Review updated docs to confirm a developer following the adding-games guide would know to create all 4 navigation tests
