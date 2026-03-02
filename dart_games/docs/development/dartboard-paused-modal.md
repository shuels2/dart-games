# Dartboard Paused Modal Component

## Purpose

The `DartboardPausedModal` widget displays a full-screen overlay when the dartboard connection is lost mid-game. It pauses gameplay with a "Game Paused" message and automatically dismisses when the dartboard reconnects. Each game provides its own visual styling via `DartboardPausedModalConfig` factory methods.

## File Location

```
lib/widgets/dartboard_paused_modal/
  dartboard_paused_modal.dart         # The widget (exports config)
  dartboard_paused_modal_config.dart  # Configuration class
```

## How It Works

- Renders a semi-transparent black overlay (`Colors.black.withOpacity(0.7)`)
- Centers a styled container with game-themed border, background, and shadow
- Shows a `wifi_off` icon, "Game Paused" title, and reconnection message
- Only appears for real dartboard connections (never in emulator mode)
- Auto-shows when `dartboardProvider.status` becomes `error` or `disconnected`
- Auto-dismisses when the dartboard reconnects (driven by `context.watch<DartboardProvider>()`)
- Wraps the container in a `ConstrainedBox` using `maxWidth`

## Configuration

### DartboardPausedModalConfig Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `backgroundColor` | `Color` | required | Inner container background color |
| `backgroundOpacity` | `double` | 0.95 | Background opacity |
| `borderColor` | `Color` | required | Container border color |
| `borderWidth` | `double` | 4.0 | Border width |
| `borderRadius` | `double` | 12.0 | Corner radius |
| `boxShadowColor` | `Color` | required | Shadow color |
| `boxShadowOpacity` | `double` | required | Shadow opacity |
| `iconColor` | `Color` | required | `wifi_off` icon color |
| `iconSize` | `double` | 48 | Icon size |
| `titleTextStyle` | `TextStyle` | required | "Game Paused" text style |
| `messageTextStyle` | `TextStyle` | required | Reconnection message text style |
| `maxWidth` | `double` | 420 | Max width constraint |
| `margin` | `EdgeInsets` | `all(16)` | Container margin |
| `padding` | `EdgeInsets` | `all(32)` | Container padding |

### Factory Methods

| Factory | Theme | Key Differences |
|---------|-------|-----------------|
| `.carnivalDerby()` | Canary Yellow border, Midnight Navy bg | LuckiestGuy/Bangers fonts, 56px icon |
| `.targetTag()` | Hot Pink border, Dark Navy bg | LuckiestGuy/Fredoka fonts |
| `.monsterMash()` | Ecto-Green border, Iron Gate bg | Creepster/PirataOne fonts, green glow shadow |
| `.reefRoyale()` | Seafoam Green border, Deep Reef Blue bg | Fredoka font, seafoam glow |

## Integration

### Basic Usage

```dart
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';

// In your game screen's Stack (after RemoveDartsModal):
if (!dartboardProvider.isEmulator &&
    dartboardProvider.status != DartboardConnectionStatus.connected &&
    dartboardProvider.status != DartboardConnectionStatus.emulator)
  DartboardPausedModal(
    config: DartboardPausedModalConfig.yourGame(),
  ),
```

### Widget Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `config` | `DartboardPausedModalConfig` | Yes | Visual styling configuration |

### Condition Logic

The modal shows when ALL of these are true:
- `!dartboardProvider.isEmulator` — not in emulator mode
- `status != DartboardConnectionStatus.connected` — not connected
- `status != DartboardConnectionStatus.emulator` — not emulator status

This means it appears for `disconnected`, `connecting`, and `error` states on real dartboard connections only.

## Adding a New Game

1. Add a factory method to `DartboardPausedModalConfig`:

```dart
factory DartboardPausedModalConfig.myNewGame() {
  return DartboardPausedModalConfig(
    backgroundColor: const Color(0xFF...),
    borderColor: const Color(0xFF...),
    boxShadowColor: const Color(0xFF...),
    boxShadowOpacity: 0.3,
    iconColor: const Color(0xFF...),
    titleTextStyle: GoogleFonts.myFont(
      color: const Color(0xFF...),
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    messageTextStyle: GoogleFonts.myFont(
      color: Colors.white,
      fontSize: 18,
    ),
  );
}
```

2. Add `DartboardPausedModal` to your game screen's Stack after the `RemoveDartsModal`.

## Current Usage

| Screen | Configuration |
|--------|--------------|
| Carnival Derby Game | `DartboardPausedModalConfig.carnivalDerby()` |
| Target Tag Game | `DartboardPausedModalConfig.targetTag()` |
| Monster Mash Game | `DartboardPausedModalConfig.monsterMash()` |
| Reef Royale Game | `DartboardPausedModalConfig.reefRoyale()` |

## Related Documentation

- [Shared Systems](../architecture/shared-systems.md) - System #12
- [Remove Darts Modal](remove-darts-modal.md) - Similar shared modal pattern
- [Dartboard Connection Info](dartboard-connection-info.md) - Connection status display
- [Adding New Games](adding-games.md)
- [Game Integration Requirements](game-integration.md)
