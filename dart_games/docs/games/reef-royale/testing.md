# Reef Royale — Testing

## Test Suite Summary

- **Non-UI Tests:** ~150 tests (game logic + announcements)
- **UI Automation Tests:** 67 tests (~45 minutes)

## Non-UI Test Files

### `reef_royale_game_test.dart`
Game logic and model tests covering:
- DartboardLayout utilities (neighbor lookup, adjacency)
- Game creation (standard and random reefs)
- Dart processing (miss, single/double/triple hits)
- Mark accumulation and coral claiming
- Pearl scoring (standard and Cursed Tide)
- Neighbor number resolution (single and shared neighbors)
- Bonus buffs (Riptide Rush, Pearl Fever, Ink Cloud)
- Win conditions (all corals, all locked, speed play)
- Turn management and skip turn
- Edit score / revert turn
- Target locking mechanics
- Multi-player scoring scenarios
- Display helpers (creature names, coral names, image paths)

### `reef_royale_announcement_test.dart`
Announcement system tests covering:
- Game event announcements (start, random reefs)
- Dart event announcements (miss, marks, neighbor hits)
- Claim and lock event announcements
- Pearl scoring announcements (standard and Cursed Tide)
- Buff activation announcements
- Game completion announcements (near victory, victory)
- Announcement precedence (max 2 per dart rule)
- Game state integration with announcement timing

## UI Automation Test Files

### `reef_royale_menu_and_settings_test.dart` (10 tests)
- All menu options visible and functional
- Toggle switches (Easy Claim, Neighbor Numbers, Random Reefs, Bonus Buffs, Show Hints, Speed Play)
- Game mode dropdown (Standard, Cursed Tide)
- Round limit slider
- Player addition and removal
- Start game button state

### `reef_royale_add_player_test.dart` (6 tests)
- Add player dialog appearance
- Player creation with name
- Camera/photo integration
- Form validation
- Empty state add button
- Player tile display

### `reef_royale_gameplay_test.dart` (30 tests)
- Dart throwing via mock dartboard
- Mark accumulation and coral claiming
- Pearl scoring verification
- Dart indicator color coding (direct, neighbor, claimed, miss)
- Skip turn functionality
- Cursed Tide pearl redirection
- Buff effects (Riptide Rush, Pearl Fever)
- Neighbor hit resolution
- Shared neighbor multi-target hits
- Pulsing glow on multi-target indicators
- Badge visibility (CURSED, NEIGHBORS, BUFFS)
- Turn progression and takeout flow

### `reef_royale_edit_score_test.dart` (6 tests)
- Edit score dialog appearance
- Dart score modification
- Turn state revert and replay
- Color coding in edit dialog

### `reef_royale_results_screen_test.dart` (6 tests)
- Winner display (creature, name, stats)
- Player rankings
- Play Again navigation
- Change Settings navigation
- Back to Menu navigation
- Victory music integration

### `reef_royale_visual_validation_test.dart` (7 tests)
- Coral card updates after claim
- Active player panel (avatar, stats, counters)
- Dart indicators after throws
- Buff banner display
- Opponent summary bar
- Hint overlay display
- Cursed Tide badge and visual changes
- Badge absence with default settings

### `reef_royale_screenshot_test.dart` (1 test)
- Captures 15 screenshots across all screens and option combinations

### `reef_royale_showcase_test.dart` (1 test)
- End-to-end showcase with Easy Claim, Neighbors, and Buffs enabled

## Widget Keys

### Menu Keys (`ReefRoyaleMenuKeys`)
- `backButton`, `gameModeDropdown`, `easyClaimSwitch`, `neighborNumbersSwitch`
- `randomReefsSwitch`, `bonusBuffsSwitch`, `showHintsSwitch`, `speedPlaySwitch`
- `roundLimitSlider`, `startGameButton`, `addPlayerButton`, `addPlayerButtonEmptyState`
- `playerListView`, `playerTile(id)`, `removePlayerButton(id)`

### Game Keys (`ReefRoyaleGameKeys`)
- `skipTurnButton`, `editScoreButton`, `coralCard(target)`, `playerAvatar`
- `pearlCounter`, `coralCounter`, `dartIndicator(index)`, `buffBanner`
- `roundCounter`, `hintOverlay`, `playerTile(id)`
- `cursedBadge`, `neighborsBadge`, `buffsBadge`
- `dartBullseyeButton`, `dartOuterBullButton`, `dartMissButton`, `getDartKey()`

### Results Keys (`ReefRoyaleResultsKeys`)
- `winnerName`, `winnerPhoto`, `pearlCount`, `coralCount`
- `playAgainButton`, `changeSettingsButton`, `backToMenuButton`, `playerRanking(index)`

## Running Tests

```bash
# Non-UI tests
flutter test test/screens/games/reef_royale/

# All UI tests
./run_ui_tests.bat reef_royale

# Specific UI test
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/reef_royale_gameplay_test.dart -d chrome
```
