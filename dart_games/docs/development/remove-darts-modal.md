# Remove Darts Modal Component

## Purpose

The `RemoveDartsModal` widget displays a full-screen overlay prompting the current player to remove their darts from the board. It appears when the turn ends and no physical dartboard is connected (`shouldPromptTakeout && !dartboardProvider.isConnected`). Each game provides its own visual styling via `RemoveDartsModalConfig` factory methods.

## File Location

```
lib/widgets/remove_darts_modal/
  remove_darts_modal.dart         # The widget (exports config)
  remove_darts_modal_config.dart  # Configuration class
```

## How It Works

- Renders a semi-transparent black overlay (`Colors.black.withOpacity(0.7)`)
- Centers a styled container with game-themed border, background, and shadow
- Shows a `pan_tool` icon, the player's name, and "Remove Your Darts" instruction
- Includes an "Edit player score" button that triggers an `onEditScore` callback
- The `showEditScoreDialog()` call stays in each game screen (passed as `onEditScore`), since each game uses its own provider, `EditScoreDialogConfig`, and optional `dartBorderColors`
- When `maxWidth` is not infinite, wraps the container in a `ConstrainedBox`

## Configuration

### RemoveDartsModalConfig Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `backgroundColor` | `Color` | required | Inner container background color |
| `backgroundOpacity` | `double` | 0.95 | Background opacity |
| `borderColor` | `Color` | required | Container border color |
| `borderWidth` | `double` | 4.0 | Border width |
| `borderRadius` | `double` | 12.0 | Corner radius |
| `boxShadowColor` | `Color` | required | Shadow color |
| `boxShadowOpacity` | `double` | required | Shadow opacity |
| `iconColor` | `Color` | required | `pan_tool` icon color |
| `iconSize` | `double` | 48 | Icon size |
| `playerNameTextStyle` | `TextStyle` | required | Player name text style |
| `instructionTextStyle` | `TextStyle` | required | "Remove Your Darts" text style |
| `buttonBackgroundColor` | `Color` | required | Edit button background |
| `buttonForegroundColor` | `Color` | required | Edit button text color |
| `buttonBorderSide` | `BorderSide?` | null | Optional button border |
| `buttonTextStyle` | `TextStyle` | required | Edit button text style |
| `buttonBorderRadius` | `double` | 8.0 | Button corner radius |
| `editButtonText` | `String` | `'Edit player score'` | Button label text |
| `maxWidth` | `double` | `double.infinity` | Max width constraint |
| `margin` | `EdgeInsets` | `all(16)` | Container margin |
| `padding` | `EdgeInsets` | `all(24)` | Container padding |

### Factory Methods

| Factory | Theme | Key Differences |
|---------|-------|-----------------|
| `.carnivalDerby()` | Canary Yellow border, Midnight Navy bg | LuckiestGuy/Bangers fonts, 64px icon, larger padding/margin |
| `.targetTag()` | Hot Pink border, Dark Navy bg | Fredoka font, 400px max width |
| `.monsterMash()` | Lime Green border, Iron Gate bg | Creepster/PirataOne fonts, green glow shadow, 400px max width |
| `.reefRoyale()` | Seafoam Green border, Deep Reef Blue bg | Fredoka font, seafoam glow, 400px max width |

## Integration

### Basic Usage

```dart
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';

// In your game screen's Stack:
if (shouldPromptTakeout && !dartboardProvider.isConnected)
  RemoveDartsModal(
    config: RemoveDartsModalConfig.targetTag(),
    playerName: currentPlayer?.name ?? 'Player',
    editScoreButtonKey: YourGameKeys.editScoreButton,
    onEditScore: () {
      if (currentPlayer == null) return;
      final yourProvider =
          Provider.of<YourProvider>(context, listen: false);
      showEditScoreDialog(
        context: context,
        playerName: currentPlayer.name,
        initialSegments: yourProvider.getCurrentTurnDarts(currentPlayer.id),
        onSubmit: (newSegments) =>
            yourProvider.updateAllDartScores(currentPlayer.id, newSegments),
        config: EditScoreDialogConfig.yourGame(),
      );
    },
  ),
```

### Widget Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `config` | `RemoveDartsModalConfig` | Yes | Visual styling configuration |
| `playerName` | `String` | Yes | Name to display in the modal |
| `editScoreButtonKey` | `Key?` | No | Widget key for the edit button (for testing) |
| `onEditScore` | `VoidCallback?` | No | Callback when edit button is pressed |

## Adding a New Game

1. Add a factory method to `RemoveDartsModalConfig`:

```dart
factory RemoveDartsModalConfig.myNewGame() {
  return RemoveDartsModalConfig(
    backgroundColor: const Color(0xFF...),
    borderColor: const Color(0xFF...),
    boxShadowColor: const Color(0xFF...),
    boxShadowOpacity: 0.5,
    iconColor: Colors.white,
    playerNameTextStyle: GoogleFonts.myFont(
      color: const Color(0xFF...),
      fontSize: 24,
    ),
    instructionTextStyle: GoogleFonts.myFont(
      color: Colors.white,
      fontSize: 20,
    ),
    buttonBackgroundColor: const Color(0xFF...),
    buttonForegroundColor: Colors.white,
    buttonTextStyle: GoogleFonts.myFont(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    maxWidth: 400,
  );
}
```

2. Use `RemoveDartsModal` in your game screen's Stack where the overlay should appear.

## Current Usage

| Screen | Configuration |
|--------|--------------|
| Carnival Derby Game | `RemoveDartsModalConfig.carnivalDerby()` |
| Target Tag Game | `RemoveDartsModalConfig.targetTag()` |
| Monster Mash Game | `RemoveDartsModalConfig.monsterMash()` |
| Reef Royale Game | `RemoveDartsModalConfig.reefRoyale()` |

## Related Documentation

- [Shared Systems](../architecture/shared-systems.md) - System #10
- [Edit Score Dialog](edit-score-dialog.md) - Used within the modal's edit button callback
- [Adding New Games](adding-games.md)
- [Game Integration Requirements](game-integration.md)
