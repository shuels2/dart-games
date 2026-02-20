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

## Related Documentation

- [Adding New Games](adding-games.md)
- [Shared Systems](../architecture/shared-systems.md#8-edit-score-dialog-component)
