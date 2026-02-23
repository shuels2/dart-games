# Dartboard Connection Info Component

## Purpose

The `DartboardConnectionInfo` widget displays dartboard name, type (emulator vs hardware), and connection status in a single compact row. It replaces the previous two-widget approach (`CompactDartboardInfo` + `DartboardStatusIndicator`) with a unified, theme-able component.

## File Location

```
lib/widgets/dartboard_connection_info/
  dartboard_connection_info.dart         # The widget
  dartboard_connection_info_config.dart  # Configuration class
```

## How It Works

- Uses `Consumer<DartboardProvider>` internally for reactive state updates
- Returns `SizedBox.shrink()` if no dartboard is configured
- Shows dartboard name + type icon (computer icon for emulator, developer_board for hardware)
- Shows "Emulator" label when in emulator mode
- Shows connection status icon + text when using hardware dartboard (not shown for emulator)
- All visual properties controlled via `DartboardConnectionInfoConfig`

## Configuration

### DartboardConnectionInfoConfig Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `backgroundColor` | `Color` | required | Container background color |
| `backgroundOpacity` | `double` | 0.95 | Opacity of background |
| `borderRadius` | `double` | 8.0 | Corner radius |
| `emulatorBorderColor` | `Color` | required | Border color when using emulator |
| `hardwareBorderColor` | `Color` | required | Border color when using hardware |
| `borderWidth` | `double` | 1.5 | Border width |
| `nameTextStyle` | `TextStyle` | required | Style for dartboard name |
| `statusTextStyle` | `TextStyle` | required | Style for status text |
| `emulatorLabelTextStyle` | `TextStyle` | required | Style for "Emulator" label |
| `emulatorIconColor` | `Color` | required | Icon color in emulator mode |
| `hardwareIconColor` | `Color` | required | Icon color in hardware mode |
| `connectedColor` | `Color` | green | Connected status color |
| `connectingColor` | `Color` | orange | Connecting status color |
| `disconnectedColor` | `Color` | red | Disconnected status color |
| `errorColor` | `Color` | red | Error status color |
| `iconSize` | `double` | 18.0 | Size of icons |
| `padding` | `EdgeInsets` | h:12, v:6 | Container padding |

### Factory Methods

| Factory | Theme | Font |
|---------|-------|------|
| `.homeScreen()` | White background, blue/orange | Default |
| `.carnivalDerby()` | Midnight Navy, Canary Yellow/Electric Teal | Montserrat |
| `.targetTag()` | Dark navy, Hot Pink/Neon Green | Fredoka |
| `.monsterMash()` | Iron Gate, Ecto-Green/Parchment | Montserrat |
| `.reefRoyale()` | Deep Reef Blue, Seafoam Green/Sunlit Aqua | Fredoka |

## Integration

### In AppBar Actions (Most Common)

```dart
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';

// In your Scaffold's AppBar:
AppBar(
  title: Text('Game Title'),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: DartboardConnectionInfo(
        config: DartboardConnectionInfoConfig.targetTag(),
      ),
    ),
  ],
)
```

### In Custom Top Bar Row

```dart
Widget _buildTopBar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        // ... back button, title, etc.
        const Spacer(),
        DartboardConnectionInfo(
          config: DartboardConnectionInfoConfig.reefRoyale(),
        ),
      ],
    ),
  );
}
```

### As Positioned Overlay (Results Screens)

```dart
Stack(
  children: [
    // ... background, confetti, main content
    Positioned(
      top: 8,
      right: 16,
      child: SafeArea(
        child: DartboardConnectionInfo(
          config: DartboardConnectionInfoConfig.reefRoyale(),
        ),
      ),
    ),
  ],
)
```

## Adding a New Game

When creating a new game, add a factory method to `DartboardConnectionInfoConfig`:

```dart
factory DartboardConnectionInfoConfig.myNewGame() {
  return DartboardConnectionInfoConfig(
    backgroundColor: const Color(0xFF...),  // Game's dark/panel color
    emulatorBorderColor: const Color(0xFF...),  // Game's accent color
    hardwareBorderColor: const Color(0xFF...),  // Game's secondary color
    nameTextStyle: GoogleFonts.myFont(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF...),  // Light text color
    ),
    statusTextStyle: GoogleFonts.myFont(
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
    emulatorLabelTextStyle: GoogleFonts.myFont(
      fontSize: 10,
      color: const Color(0xFF...),  // Accent color
    ),
    emulatorIconColor: const Color(0xFF...),
    hardwareIconColor: const Color(0xFF...),
    connectedColor: const Color(0xFF...),  // Game's "success" color
    connectingColor: const Color(0xFF...),  // Game's "warning" color
    disconnectedColor: const Color(0xFF...),  // Game's "danger" color
    errorColor: const Color(0xFF...),
  );
}
```

Then add the widget to all 3 game screens (menu, game, results).

## Current Usage

| Screen | Integration |
|--------|------------|
| Home Screen | AppBar actions |
| Carnival Derby Menu | AppBar actions |
| Carnival Derby Game | AppBar actions |
| Carnival Derby Results | AppBar actions |
| Target Tag Menu | AppBar actions |
| Target Tag Game | AppBar actions |
| Target Tag Results | AppBar actions |
| Monster Mash Menu | AppBar actions |
| Monster Mash Game | AppBar actions |
| Monster Mash Results | AppBar actions |

## Related Documentation

- [Shared Systems](../architecture/shared-systems.md) - System #9
- [Adding New Games](adding-games.md)
- [Game Integration Requirements](game-integration.md)
