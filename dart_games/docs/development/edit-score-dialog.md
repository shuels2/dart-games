# Edit Score Dialog Integration

## Overview

**ALL games MUST use the shared Edit Score dialog component when editing dart scores.**

The Edit Score dialog provides consistent dart-picker logic (ring + number selection for 3 darts) while allowing styling customization.

## Integration Pattern

### Step 1: Import Package

```dart
import '../../../widgets/edit_score/edit_score.dart';
```

### Step 2: Call Dialog from Button

```dart
ElevatedButton(
  onPressed: () {
    final provider = Provider.of<YourProvider>(context, listen: false);
    showEditScoreDialog(
      context: context,
      playerName: currentPlayer.name,
      initialSegments: provider.getCurrentTurnDarts(playerId),
      onSubmit: (newSegments) =>
          provider.updateAllDartScores(playerId, newSegments),
      config: EditScoreDialogConfig.yourGame(),
      dartBorderColors: _computeDartBorderColors(playerId), // Optional
    );
  },
  child: Text('Edit Score'),
)
```

## Configuration

Create factory method in `lib/widgets/edit_score/edit_score_dialog_config.dart`:

```dart
factory EditScoreDialogConfig.yourGame() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xYOURCOLOR).withOpacity(0.95),
    borderColor: const Color(0xYOURBORDER),
    titleStyle: GoogleFonts.yourFont(/*...*/),
    dartLabelStyle: GoogleFonts.yourFont(/*...*/),
    scoreBoxBackgroundColor: const Color(0xYOURBG),
    scoreBoxDefaultBorderColor: Colors.white38,
    buttonUnselectedColor: const Color(0xYOURUNSEL),
    buttonSelectedColor: const Color(0xYOURSEL),
    cancelButtonColor: Colors.grey,
    submitButtonColor: const Color(0xYOURACCENT),
    // Optional: transform score display
    // scoreDisplayTransform: (segment) => transformSegment(segment),
  );
}
```

## Segment Encoding

- `S20` - Outer single 20
- `s20` - Inner single 20 (Carnival Derby only)
- `D16` - Double 16
- `T19` - Triple 19
- `Bull` - Bullseye (50)
- `25` - Outer bull
- `Miss` - Miss

**Critical:** A thrown miss (score 0) MUST be encoded as `'Miss'` in `initialSegments`, NOT `'-'` or empty. The value `'-'` means "dart not yet thrown" and disables the Save button. Since Edit Score is only accessible after 3 darts are thrown, all 3 segments should be valid (`'Miss'`, `'Bull'`, `'25'`, or `'SX'`/`'DX'`/`'TX'`).

## Features

- Ring/number picker for all 3 darts
- Per-dart score box border color overrides (optional)
- Optional score display transform
- Submit disabled until all 3 darts selected

## Color-Coded Borders (Optional)

```dart
List<Color?> _computeDartBorderColors(String playerId) {
  // Return list of 3 colors (one per dart)
  // null = use config default color
  return [Colors.green, Colors.red, null];
}
```

## Benefits

- ~860 lines of code eliminated across 2 game screens
- Consistent ring/number picker logic
- Game-specific visual identity maintained
- Bug fixes benefit all games

## Reference Implementations

- Carnival Derby: `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart`
- Target Tag: `lib/screens/games/target_tag/target_tag_game_screen.dart`
- Monster Mash: `lib/screens/games/monster_mash/monster_mash_game_screen.dart`

## Score Display Patterns

Games use one of two scoring display patterns for the D1/D2/D3 labels and Edit Score dialog:

### Pattern A: Total Score Display (Carnival Derby, Lunar Lander)

Shows the **calculated point value** (e.g., "60" for T20, "20" for S20). Used when the game's scoring is based on point values that affect player position/score.

- `EditScoreDialogConfig` factory includes `scoreDisplayTransform: _gameScoreDisplay`
- The transform converts segment strings to point values: S20→"20", D13→"26", T20→"60"
- **Provider must store raw segment strings** alongside calculated scores. The game model needs a `currentTurnDartSegments` field (`Map<String, List<String>>`) storing the original sector strings ('S20', 'D15', 'T20', 'Bull', 'Miss'). The game screen passes the raw sector string through to the provider, which stores it with each dart. The `onEditScore` handler reads `provider.getCurrentTurnDartSegments(playerId)` to populate `initialSegments`. Without this, converting calculated values back to segments is lossy (e.g., score 40 becomes 'S40' with no matching dartboard number). The field must be serialized for save/resume, cleared on turn advance, and rebuilt during edit score replay.
- **Test constraint:** Single values (S5, S10) cause duplicate text matches in the dialog because the score display AND number button show the same value. Tests MUST use Double or Triple values (D5, T5) so the score display differs from the number button.

### Pattern B: Dart Throw Display (Target Tag, Monster Mash, Reef Royale, Clockwork Quest)

Shows the **raw segment string** (e.g., "S20", "T20", "Bull"). Used when the game's scoring is based on targets hit.

- `EditScoreDialogConfig` factory does NOT include `scoreDisplayTransform` (default null)
- No duplicate text issue since "S20" ≠ "20"

**If unsure which pattern applies to a new game, ask the user before implementing.**

## Mandatory Tests

Every game MUST have the following edit score tests in `integration_test/[game]/edit_score/`:

- **`edit_creates_winner_stats_test.dart`** -- Position the game near the win condition, throw 3 non-winning darts, open Edit Score and change darts to winning values. Verify `hasWinner == true`, navigate to results, then verify player stats and victory music.

- **`edit_removes_winner_no_stats_test.dart`** -- Position the game near the win condition, throw 3 winning darts, open Edit Score and change darts to non-winning values. Verify `hasWinner == false`, verify game continues (NOT navigated to results), verify no player stats were updated.

## Related Documentation

- [Adding New Games](adding-games.md)
- [Shared Systems](../architecture/shared-systems.md#8-edit-score-dialog-component)
