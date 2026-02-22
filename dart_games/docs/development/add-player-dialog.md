# Add Player Dialog Integration

## Overview

**ALL games and System Settings MUST use the shared Add Player dialog component.**

The Add Player dialog provides consistent player creation logic across all games and screens while allowing visual customization.

## Integration Pattern

### Step 1: Import Package

```dart
import '../../../widgets/add_player/add_player.dart';
```

### Step 2: Create Handler Method

```dart
void _handleAddPlayer() async {
  final player = await showAddPlayerDialog(
    context: context,
    config: AddPlayerDialogConfig.yourGame(),
  );

  if (player != null && mounted) {
    final playerProvider = context.read<PlayerProvider>();
    await playerProvider.savePlayer(player);

    // Optional: Auto-select player (games only)
    if (playerProvider.selectedPlayers.length < maxPlayers) {
      playerProvider.selectPlayer(player, maxPlayers: maxPlayers);
    }

    // Optional: Show success feedback (System Settings only)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Player "${player.name}" added')),
    );

    // Optional: Scroll to new player
    _scrollToNewPlayer();
  }
}
```

### Step 3: Call Handler from Button

```dart
ElevatedButton(
  onPressed: _handleAddPlayer,
  child: Text('Add Player'),
)
```

## Configuration

Create factory method in `lib/widgets/add_player/add_player_dialog_config.dart`:

```dart
factory AddPlayerDialogConfig.yourGame() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xYOURCOLOR).withOpacity(0.95),
    textColor: Colors.white,
    titleStyle: GoogleFonts.yourFont(/*...*/),
    inputLabelStyle: GoogleFonts.yourFont(/*...*/),
    inputBorderColor: const Color(0xYOURBORDER),
    inputFocusedBorderColor: const Color(0xYOURACCENT),
    photoButtonColor: const Color(0xYOURBUTTON),
    addButtonColor: const Color(0xYOURPRIMARY),
    cancelButtonColor: const Color(0xYOURSECONDARY),
    // ... other styling
  );
}
```

## Monster Mash-Specific Config Fields

Monster Mash introduced 6 new config fields for advanced customization:

- `customCancelButton` - Widget replacing the standard cancel button (e.g., StoneDialogButton)
- `customAddButton` - Widget replacing the standard add button (e.g., StoneDialogButton with lightning)
- `dialogInsetPadding` - Custom EdgeInsets for dialog edge padding (wider layout for stone buttons)
- `dialogContentWidth` - Custom double for content width (380px for Monster Mash)
- `photoIconShadows` - List of Shadow for camera/gallery icon glow effects
- `buttonPadding` - Custom EdgeInsets for button row padding

These fields are optional and only used when a game needs to replace standard buttons with custom widgets.

## Features

- Photo upload via camera or gallery
- Name validation (empty check)
- Photo preview with remove button
- Returns Player object if created, null if cancelled
- Custom button widget support (Monster Mash uses StoneDialogButton)

## Benefits

- ~750 lines of code eliminated across 3 locations
- Consistent player creation logic
- Game-specific visual identity maintained
- Centralized photo upload functionality

## Reference Implementations

- Carnival Derby: `lib/screens/games/carnival_horse_race/horse_race_menu_screen.dart`
- Target Tag: `lib/screens/games/target_tag/target_tag_menu_screen.dart`
- Monster Mash: `lib/screens/games/monster_mash/monster_mash_menu_screen.dart` (uses custom StoneDialogButton)
- System Settings: `lib/screens/options_screen.dart`

## Related Documentation

- [Adding New Games](adding-games.md)
- [Shared Systems](../architecture/shared-systems.md#7-add-player-dialog-component)
