# Widget Keys for Testing

## Overview

**ALL games MUST implement widget keys for testable elements.**

Widget keys enable reliable, maintainable UI testing by providing stable identifiers that don't break when text changes or UI is reordered.

## Why Widget Keys Are Required

### Problems Without Keys
❌ Breaks when text changes  
❌ Breaks when UI is reordered  
❌ Breaks when widget types change  
❌ Flaky tests with random failures  
❌ Hard to maintain (magic indices, duplicated text)

### Benefits With Keys
✅ Stable across text changes  
✅ Stable across UI refactoring  
✅ Stable across widget type changes  
✅ Clear intent (key name describes element)  
✅ Easy to maintain (centralized)

## What Needs Keys

Add `Key` to ALL interactive elements:
- Buttons (start, skip, edit, back, etc.)
- Player tiles (selectable, draggable)
- Menu cards (game selection)
- Input fields (text fields, dropdowns, sliders, switches)
- Dialogs (add player, edit score, settings)
- Dart score buttons (S20, D20, T20, Bull, Miss - all 60+)
- Navigation elements (tabs, drawers)
- Results screen elements (play again, change settings)

## Key Naming Convention

### Format
`Key('game_screen_element')` — game first, then screen, then element.

**All keys live in one file:** `lib/constants/test_keys.dart`.

```dart
// Real examples from test_keys.dart — copy this shape.
class TreasureDivideMenuKeys {
  static const backButton = Key('td_menu_back_button');
  static const startButton = Key('td_menu_start_button');
  static Key playerTile(String playerId) => Key('td_menu_player_tile_$playerId');
}

class TikiGolfGameKeys {
  static const skipTurnButton = Key('tiki_golf_game_skip_turn_button');
  static const editScoreButton = Key('tiki_golf_game_edit_score_button');
  static Key dartIndicator(int index) => Key('tiki_golf_game_dart_indicator_$index');
}
```

The game segment may be an abbreviation (`td_`) or the full name
(`tiki_golf_`); be consistent within a game. Home-screen cards use
`home_card_<game>` for new games.

### Shared component keys — do not redefine these

The shared widgets already declare their own keys. Use them rather than adding
per-game duplicates:

| Class | Covers |
|---|---|
| `AddPlayerDialogKeys` | Add Player dialog |
| `EditScoreDialogKeys` | Edit Score dialog |
| `SaveGameModalKeys` | Save Game modal (incl. `errorMessage`) |
| `ResumeGameModalKeys` | Resume Game modal (incl. `errorMessage`, `retryButton`) |
| `RemoveDartsModalKeys` | Remove Darts modal |
| `DartboardEmulatorKeys` | Emulator section, incl. `playToTieButton` / `buffToggleButton` |

### Parameterised keys

Take the identifier the widget actually renders from, and keep the meaning
consistent across screens. Tiki Golf has `teamBox(teamIndex)` on the menu and
`teamBox(teamId)` on the game screen — same name, different argument, which is
a trap for anyone writing tests against both.

## Key Organization

**File:** `lib/constants/test_keys.dart`

Organize keys by screen/component:

```dart
// Home screen keys (shared)
class HomeKeys {
  static const carnivalDerbyCard = Key('home_carnival_derby_card');
  static const targetTagCard = Key('home_target_tag_card');
}

// Your game keys
class YourGameMenuKeys { /* ... */ }
class YourGameGameKeys { /* ... */ }
class YourGameDialogKeys { /* ... */ }
class YourGameResultsKeys { /* ... */ }
```

## Implementation Example

### In Widget File

```dart
import 'package:dart_games/constants/test_keys.dart';

// Add keys to widgets
ElevatedButton(
  key: YourGameMenuKeys.startButton,  // ← Add key
  onPressed: _startGame,
  child: Text('Start Game'),
)

// Dynamic keys (player tiles)
PlayerTile(
  key: YourGameMenuKeys.playerTile(player.id),  // ← Dynamic key
  player: player,
  onTap: () => _selectPlayer(player),
)
```

### In Tests

```dart
import 'package:dart_games/constants/test_keys.dart';

// Find elements by key (NOT by text or type)
final startButton = find.byKey(YourGameMenuKeys.startButton);
await tester.tap(startButton);

final aliceTile = find.byKey(YourGameMenuKeys.playerTile('alice-id'));
await tester.tap(aliceTile);

// NO MORE:
// ❌ find.text('Start Game')  // Breaks when text changes
// ❌ find.byType(ElevatedButton).at(2)  // Breaks when UI reorders
```

## Dynamic Keys for Lists

Use dynamic key generation for list items:

```dart
class YourGameMenuKeys {
  static playerTile(String playerId) => Key('menu_yg_player_tile_$playerId');
  static settingItem(int index) => Key('menu_yg_setting_$index');
}
```

## Common Key Patterns

### Buttons
```dart
static const startButton = Key('screen_game_start_button');
static const cancelButton = Key('screen_game_cancel_button');
static const submitButton = Key('screen_game_submit_button');
```

### Input Fields
```dart
static const nameField = Key('screen_game_name_field');
static const scoreField = Key('screen_game_score_field');
```

### List Items
```dart
static playerTile(String id) => Key('screen_game_player_tile_$id');
static gameCard(String name) => Key('home_game_card_$name');
```

### Dialogs
```dart
static const addPlayerDialog = Key('dialog_add_player');
static const confirmDialog = Key('dialog_confirm');
```

## Monster Mash Keys

### MonsterMashMenuKeys
- `addPlayerButton`, `addPlayerButtonEmptyState` - Add player buttons
- `playerListView` - Player list scrollview
- `playerTile(playerId)` - Player selection tile (dynamic)
- `healthPointsSlider` - Health Points slider (10-50)
- `bonusBuffsSwitch` - Bonus Buffs toggle
- `speedPlaySwitch` - Speed Play toggle
- `roundLimitSlider` - Round Limit slider (3-20)
- `startGameButton`, `backButton` - Action buttons

### MonsterMashGameKeys
- `playerTile(playerId)`, `healthBar(playerId)` - Dynamic player elements
- `skipTurnButton`, `editScoreButton` - Action buttons
- `buffHealShield`, `buffDamageShield`, `buffLabel` - Buff display elements
- `dartSingle1Button` through `dartSingle20Button` - 20 single buttons
- `dartDouble1Button` through `dartDouble20Button` - 20 double buttons
- `dartTriple1Button` through `dartTriple20Button` - 20 triple buttons
- `dartBullseyeButton`, `dartOuterBullButton`, `dartMissButton` - Special buttons
- `getDartKey(multiplier, number)` - Helper method (63 total dart buttons)

### MonsterMashResultsKeys
- `winnerName` - Winner name display
- `playAgainButton`, `changeSettingsButton`, `backToMenuButton` - Action buttons

## Reference Implementations

See existing games for complete examples:
- Target Tag: `lib/constants/test_keys.dart` (TargetTagMenuKeys, TargetTagGameKeys)
- Carnival Derby: `lib/constants/test_keys.dart` (CarnivalDerbyMenuKeys, CarnivalDerbyGameKeys)
- Monster Mash: `lib/constants/test_keys.dart` (MonsterMashMenuKeys, MonsterMashGameKeys, MonsterMashResultsKeys)
- Example tests: `integration_test/target_tag/target_tag_menu_and_mechanics_test.dart`

## Related Documentation

- [Adding New Games](adding-games.md)
- [UI Automation Testing](../testing/ui-automation.md)
