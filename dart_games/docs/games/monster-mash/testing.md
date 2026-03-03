# Monster Mash - Testing Documentation

## Test Overview

### Test Suite Summary
- **Total Tests:** 116 tests (65 non-UI + 51 UI)
- **Non-UI Tests:** 65 tests (47 game logic + 18 announcements)
- **UI Automation Tests:** 51 tests (~32 minutes)

### Test Files

#### Non-UI Tests
**Location:** `test/screens/games/monster_mash/`

1. **monster_mash_game_with_announcements_test.dart** (47 tests)
   - Basic game mechanics (10 groups)
   - Dart outcomes (healing, damage, bullseye, outer bull, miss)
   - Bonus buff mechanics (Blood Moon, Ancient Bandages, Shadow Walk, Laboratory Spark)
   - Speed Play and round limit behavior
   - Elimination and turn advancement
   - Edit score functionality
   - Hat Trick and Clutch Heal detection
   - Multiple winner tiebreak logic

2. **monster_mash_game_with_announcements_test.dart** (18 tests)
   - Announcement precedence rule validation (10 rules)
   - All health warning tier crossings (weaken, critical, barely clinging)
   - Buff-modified announcements (Shadow Walk, Blood Moon, Ancient Bandages, Lab Spark)
   - Combined elimination and hat trick + elimination merged announcements
   - Edge cases (eliminated opponent hit, bullseye at full health, Max Health text)

#### UI Automation Tests
**Location:** `integration_test/monster_mash/`

1. **monster_mash_menu_test.dart** (~5 min)
   - Player selection and game settings validation
   - Health Points slider
   - Bonus Buffs toggle
   - Speed Play toggle and Round Limit slider
   - Start button enable/disable logic

2. **monster_mash_gameplay_test.dart** (~7 min)
   - Dart throw processing
   - Health bar updates
   - Monster image state changes
   - Skip turn functionality

3. **monster_mash_buff_test.dart** (~5 min)
   - Buff activation display
   - Buff shield indicators
   - Buff effect on gameplay

4. **monster_mash_edit_score_test.dart** (~4 min)
   - Edit score dialog behavior
   - Score recalculation
   - Dart border color coding (green/red/white)

5. **monster_mash_add_player_test.dart** (~4 min)
   - Stone button styling in dialog
   - Add player with name only
   - Name validation
   - Cancel button functionality

6. **monster_mash_results_test.dart** (~7 min)
   - Winner display with monster image
   - Victory music playback
   - Play Again settings preservation
   - Change Settings navigation
   - Speed Play winner display

## Running Tests

### Run All Game Tests (Non-UI)
```bash
flutter test test/screens/games/monster_mash/
```

### Run Specific Test File
```bash
# Game logic tests
flutter test test/screens/games/monster_mash/monster_mash_game_with_announcements_test.dart

# Announcement tests
flutter test test/screens/games/monster_mash/monster_mash_announcement_test.dart
```

### Run UI Automation Tests
```bash
# Start chromedriver first
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# In separate terminal, run Monster Mash UI tests
cd dart_games
./run_ui_tests.bat monster_mash
```

## Widget Keys Used

### Menu Screen Keys
**Class:** `MonsterMashMenuKeys`
**File:** `lib/constants/test_keys.dart`

- `addPlayerButton` - Add player button
- `addPlayerButtonEmptyState` - Add player button (empty state)
- `playerListView` - Player list scrollview
- `playerTile(playerId)` - Player selection tile (dynamic)
- `healthPointsSlider` - Health Points slider (10-50)
- `bonusBuffsSwitch` - Bonus Buffs toggle switch
- `speedPlaySwitch` - Speed Play toggle switch
- `roundLimitSlider` - Round Limit slider (3-20)
- `startGameButton` - Start game button
- `backButton` - Back to home button

### Game Screen Keys
**Class:** `MonsterMashGameKeys`
**File:** `lib/constants/test_keys.dart`

- `playerTile(playerId)` - Player tile (dynamic)
- `healthBar(playerId)` - Health bar (dynamic)
- `skipTurnButton` - Skip turn button
- `editScoreButton` - Edit score button
- `buffHealShield` - Buff heal shield indicator
- `buffDamageShield` - Buff damage shield indicator
- `buffLabel` - Buff description label
- `dartSingle1Button` through `dartSingle20Button` - 20 single dart buttons
- `dartDouble1Button` through `dartDouble20Button` - 20 double dart buttons
- `dartTriple1Button` through `dartTriple20Button` - 20 triple dart buttons
- `dartBullseyeButton` - Bullseye button
- `dartOuterBullButton` - Outer bull button
- `dartMissButton` - Miss button
- `getDartKey(multiplier, number)` - Helper method for dart button keys

**Total dart buttons:** 63 (20 singles + 20 doubles + 20 triples + bullseye + outer bull + miss)

### Results Screen Keys
**Class:** `MonsterMashResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `winnerName` - Winner name display
- `playAgainButton` - Play again button
- `changeSettingsButton` - Change settings button
- `backToMenuButton` - Back to menu / play another game button

## Test Patterns

### Game Logic with Announcements
```dart
// Process dart and verify announcement
provider.processDartThrow(20, 'single', 20, 'S20');
expect(announcements.last.message, contains('Plus'));
expect(announcements.last.priority, AudioPriority.hitConfirm);
expect(announcements.last.soundEffect, MonsterMashSoundEffects.healing);
```

### Health Percentage Verification
```dart
// Verify monster image changes at health thresholds
expect(game.getMonsterImagePath(playerId), contains('FullHealth'));
// Deal damage to bring below 70%
provider.processDartThrow(...);
expect(game.getMonsterImagePath(playerId), contains('70Health'));
```

### Buff Activation Testing
```dart
// Verify buff effects
game.activeBuff = BonusBuff.bloodMoon;
provider.processDartThrow(opponentTarget, 'single', opponentTarget, 'S$opponentTarget');
expect(game.health[opponentId], startingHealth - 2); // Double damage
```

## Known Test Quirks

### Buff Random Activation
**Issue:** Buffs activate with ~33% probability, making deterministic testing challenging
**Workaround:** Tests set `activeBuff` directly on the game model rather than relying on random activation

### 63 Dart Button Keys
**Issue:** Monster Mash has 63 dart button keys (vs Target Tag which reuses the dartboard emulator)
**Workaround:** `getDartKey(multiplier, number)` helper method generates keys programmatically
