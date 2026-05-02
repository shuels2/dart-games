# Dartboard Emulator Component Integration

## Overview

**ALL games MUST use the shared dartboard emulator components.**

The dartboard emulator provides offline development and testing capabilities when a physical Scolia dartboard is not connected.

## Important Notes

**Purpose:**
- Allows development and testing WITHOUT physical hardware
- ONLY shown when `dartboardProvider.isEmulator` (emulator mode)
- Hidden when using a real Scolia dartboard (even if connection is lost mid-game)
- FAB button only appears in emulator mode

**NOT for end users:**
- Production users with physical dartboards won't see this
- Only appears for developers or when dartboard unavailable

## Components

The shared dartboard emulator system consists of three main components:

### 1. DartboardEmulatorController
- Manages show/hide state for dartboard emulator
- ChangeNotifier pattern
- Toggles dartboard visibility

### 2. DartboardEmulatorSection
- Renders dartboard container with optional disabled overlay
- Handles dart throw simulation
- "Remove Darts" button functionality
- Game-specific styling via config

### 3. DartboardEmulatorFAB
- Floating action button for show/hide toggle
- Only visible in emulator mode
- Game-specific styling via config

## Integration Pattern

### Step 1: Import Package

```dart
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
```

### Step 2: Create Controller and Key in State

```dart
class _YourGameScreenState extends State<YourGameScreen> {
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;

  @override
  void dispose() {
    _dartboardEmulatorController.dispose();
    // ... other dispose calls
    super.dispose();
  }
}
```

### Step 3: Add FAB to Scaffold

```dart
Scaffold(
  appBar: AppBar(/* ... */),
  body: /* ... */,
  floatingActionButton: DartboardEmulatorFAB(
    controller: _dartboardEmulatorController,
    isConnected: !dartboardProvider.isEmulator,
    config: DartboardFABConfig.yourGame(), // Create factory for your game
  ),
)
```

**FAB behavior:**
- Only visible when `dartboardProvider.isEmulator`
- Toggles dartboard visibility
- Uses game-specific styling

### Step 4: Add Dartboard Section to UI

```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: shouldPromptTakeout,
  dartboardKey: _dartboardKey,
  onDartThrow: (score, multiplier, baseScore, position) {
    if (_mockApi != null) {
      _mockApi!.simulateDartThrow(
        score: score,
        multiplier: multiplier,
        playerName: 'Player',
        baseScore: baseScore,
        widgetX: position.dx,
        widgetY: position.dy,
        widgetSize: 250,
      );
    }
  },
  onRemoveDarts: () {
    _mockApi?.simulateTakeoutFinished();
    // IMPORTANT: Do NOT call _dartboardKey.currentState?.removeDarts() here.
    // The button calls removeDarts() directly, which then fires this
    // callback automatically. Calling it here would create infinite recursion.
  },
  config: DartboardSectionConfig.yourGame(), // Create factory for your game
),
```

**Parameters:**
- `controller` - The emulator controller
- `isConnected` - Pass `!dartboardProvider.isEmulator` (hides emulator for real dartboard connections)
- `shouldPromptTakeout` - Whether to show "Remove Darts" button
- `dartboardKey` - GlobalKey for dartboard state
- `onDartThrow` - Callback when dart is thrown
- `onRemoveDarts` - Callback when darts are removed
- `config` - Visual styling configuration

### Step 5: Create Configuration Factory Methods

**File:** `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`

Add factory methods to the existing config classes:

```dart
// Add to DartboardSectionConfig class
factory DartboardSectionConfig.yourGame() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    borderRadius: BorderRadius.circular(12), // Optional
    disabledOverlayBackgroundColor: const Color(0xYOURCOLOR).withOpacity(0.9),
    disabledOverlayBorderColor: const Color(0xYOURBORDER),
    removeButtonBackgroundColor: const Color(0xYOURBUTTON),
    removeButtonBorderColor: const Color(0xYOURBORDER),
    removeButtonTextStyle: GoogleFonts.yourFont(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );
}

// Add to DartboardFABConfig class
factory DartboardFABConfig.yourGame() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    iconColor: Colors.white,
    textColor: Colors.white,
    textStyle: GoogleFonts.yourFont(fontWeight: FontWeight.bold),
  );
}
```

## Configuration Options

### DartboardSectionConfig

Controls the appearance of the dartboard container:

**Properties:**
- `backgroundColor` - Background color of dartboard container
- `borderRadius` - Corner radius (optional)
- `disabledOverlayBackgroundColor` - Overlay color when disabled
- `disabledOverlayBorderColor` - Border color when disabled
- `removeButtonBackgroundColor` - "Remove Darts" button background
- `removeButtonBorderColor` - "Remove Darts" button border
- `removeButtonTextStyle` - "Remove Darts" button text style

### DartboardFABConfig

Controls the appearance of the floating action button:

**Properties:**
- `backgroundColor` - FAB background color
- `iconColor` - Icon color
- `textColor` - Text color
- `textStyle` - Text style

## Critical Structure Requirements

**When integrating the dartboard, follow this exact pattern:**

```dart
Widget _buildDartboardSection(bool disabled) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: YourGameBackgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      alignment: Alignment.center,  // CRITICAL: Centers dartboard and modal
      children: [
        // Dartboard
        AbsorbPointer(
          absorbing: disabled,
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: InteractiveDartboard(
              key: _dartboardKey,
              size: 250,  // MUST match widgetSize parameter
              onDartThrow: (score, multiplier, baseScore, position) {
                if (_mockApi != null) {
                  _mockApi!.simulateDartThrow(
                    score: score,
                    multiplier: multiplier,
                    playerName: 'Player',
                    baseScore: baseScore,
                    widgetX: position.dx,
                    widgetY: position.dy,
                    widgetSize: 250,  // MUST match size parameter
                  );
                }
              },
              onRemoveDarts: () {
                // Called when dartboard is cleared
              },
            ),
          ),
        ),
        // Modal overlay (if needed)
        if (disabled)
          Container(
            width: 250,  // MUST match dartboard size
            height: 250,
            decoration: BoxDecoration(
              color: YourGameColor.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: YourGameBorderColor,
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Your modal content
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
```

**CRITICAL Requirements:**
1. **Stack alignment:** MUST use `alignment: Alignment.center`
2. **Direct Stack children:** Dartboard and modal are direct children
3. **Consistent sizing:** All sizes MUST match exactly (250 in example)
4. **No extra wrappers:** Avoid nesting that changes dimensions
5. **Circular modal:** Use `BoxShape.circle` for overlay

**Common Mistakes:**
- ❌ Wrapping Stack in SizedBox with different dimensions
- ❌ Using Positioned.fill for modal (breaks alignment)
- ❌ Forgetting `alignment: Alignment.center` on Stack
- ❌ Mismatched size values between dartboard and widgetSize
- ❌ Over-nesting with multiple Containers

## Benefits of Shared Components

**Code Reduction:**
- Eliminates ~200 lines of code per game
- Removes duplicated dartboard logic
- Reduces maintenance burden

**Consistency:**
- Identical dartboard behavior across all games
- Bug fixes benefit all games automatically
- Shared testing reduces regression risk

**Customization:**
- Game-specific visual identity maintained
- Each game controls colors, fonts, styling
- Future games only need config objects

## MockScoliaApiService

Initialize the mock API service when in emulator mode:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final dartboardProvider = Provider.of<DartboardProvider>(context, listen: false);

    if (dartboardProvider.isEmulator) {
      // Initialize mock API for emulator mode
      _mockApi = MockScoliaApiService(dartboardProvider);
    }
  });
}
```

This allows the emulator to simulate dart throws and trigger game logic.

## Example: Target Tag Integration

```dart
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';

class _TargetTagGameScreenState extends State<TargetTagGameScreen> {
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;

  @override
  void dispose() {
    _dartboardEmulatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = Provider.of<DartboardProvider>(context);

    return Scaffold(
      appBar: AppBar(/* ... */),
      body: Column(
        children: [
          // Game UI
          // ...

          // Dartboard section
          DartboardEmulatorSection(
            controller: _dartboardEmulatorController,
            isConnected: !dartboardProvider.isEmulator,
            shouldPromptTakeout: _shouldShowRemoveDarts(),
            dartboardKey: _dartboardKey,
            onDartThrow: (score, multiplier, baseScore, position) {
              _mockApi?.simulateDartThrow(
                score: score,
                multiplier: multiplier,
                playerName: 'Player',
                baseScore: baseScore,
                widgetX: position.dx,
                widgetY: position.dy,
                widgetSize: 250,
              );
            },
            onRemoveDarts: () {
              _mockApi?.simulateTakeoutFinished();
            },
            config: DartboardSectionConfig.targetTag(),
          ),
        ],
      ),
      floatingActionButton: DartboardEmulatorFAB(
        controller: _dartboardEmulatorController,
        isConnected: !dartboardProvider.isEmulator,
        config: DartboardFABConfig.targetTag(),
      ),
    );
  }
}
```

## Play to Complete

The Play to Complete feature auto-plays a game from the current state to completion using simulated dart throws. Each game implements a strategy that determines the optimal throw based on current game state and settings.

### Architecture

**Strategy Interface** (`lib/widgets/dartboard_emulator/play_to_complete_strategy.dart`):
- `SimulatedThrow` — data class with `score`, `multiplier`, `baseScore`
- `PlayToCompleteStrategy` — abstract class with three methods:
  - `getNextThrow(context)` — returns the next throw to make, or null if done
  - `isGameComplete(context)` — checks if game has a winner
  - `shouldAutoTakeout(context)` — checks if darts need to be removed

**Runner** (`lib/widgets/dartboard_emulator/play_to_complete_runner.dart`):
- Async loop: check complete → check takeout → get throw → simulate → delay → repeat
- Timing: 250ms between throws, 200ms for takeout handling
- Cancellable via `cancel()`, cleaned up via `dispose()`

**Strategies** (`lib/services/play_to_complete/`):
- `carnival_derby_strategy.dart` — Perfect Finish exact-finish logic
- `clockwork_quest_strategy.dart` — Sequential/speed mode target progression
- `reef_royale_strategy.dart` — Target claiming with active target awareness
- `monster_mash_strategy.dart` — HP/buff-aware combat
- `target_tag_strategy.dart` — Shield building and opponent elimination

### Game Screen Integration

Each game screen needs:

1. **Runner field**: `PlayToCompleteRunner? _playToCompleteRunner;`
2. **`_onPlayToComplete()` method**: Creates strategy + runner, hides dartboard, sets auto-playing
3. **`_onCancelAutoPlay()` method**: Cancels runner, shows dartboard, clears auto-playing
4. **Auto-play guards**: Skip announcement delays and takeout chains when `controller.isAutoPlaying`
5. **Wire callbacks**: Pass `onPlayToComplete` and `playToCompleteConfig` to `DartboardEmulatorSection`, pass `onCancelAutoPlay` to `DartboardEmulatorFAB`
6. **Dispose**: `_playToCompleteRunner?.dispose()` in `dispose()`

### Button Configuration

Add a factory to `PlayToCompleteButtonConfig` in `dartboard_emulator_config.dart`:

```dart
factory PlayToCompleteButtonConfig.yourGame() {
  return PlayToCompleteButtonConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    foregroundColor: Colors.white,
    borderColor: const Color(0xYOURBORDER),
    textStyle: GoogleFonts.yourFont(/* ... */),
  );
}
```

### FAB Cancel Mode

When `controller.isAutoPlaying` is true, the FAB shows a red "Cancel Auto-Play" button instead of the normal show/hide toggle. Pressing it calls the `onCancelAutoPlay` callback.

### UI Integration Tests

Every game must have Play to Complete UI tests in `integration_test/<game>/play_to_complete/`:
- `default_settings_test.dart` — default settings complete successfully
- Settings-specific tests for each game-critical setting
- `mid_game_test.dart` — throws manual darts first, then auto-completes

Tests use `PlayToCompleteHelpers.tapPlayToComplete()` and `waitForGameCompletion()` from `integration_test/shared/play_to_complete_helpers.dart`.

## Testing

### Manual Testing
1. Run app without dartboard connected (emulator mode)
2. Verify FAB appears
3. Verify dartboard is visible by default
4. Click FAB to hide dartboard
5. Click FAB to show dartboard
6. Click dartboard segments - verify throws register
7. Connect to real dartboard - verify FAB and emulator disappear
8. Click Play to Complete - verify game auto-plays to results screen
9. Click Cancel during auto-play - verify it stops and dartboard reappears

### Unit Testing
Test your game logic with simulated dart throws, not the dartboard component itself.

## Reference Implementations

- **Carnival Derby:** `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart`
- **Target Tag:** `lib/screens/games/target_tag/target_tag_game_screen.dart`
- **Monster Mash:** `lib/screens/games/monster_mash/monster_mash_game_screen.dart`
- **Reef Royale:** `lib/screens/games/reef_royale/reef_royale_game_screen.dart`
- **Clockwork Quest:** `lib/screens/games/clockwork_quest/clockwork_quest_game_screen.dart`
- **Component Source:** `lib/widgets/dartboard_emulator/`
- **Strategies:** `lib/services/play_to_complete/`

## Related Documentation

- [Adding New Games](adding-games.md)
- [Shared Systems - Dartboard Emulator](../architecture/shared-systems.md#6-in-game-dartboard-emulator-components)
- [Critical Rules - Dartboard Protection](../critical-rules/dartboard-protection.md)
- [Game Template - Components](../games/_GAME_TEMPLATE/components.md)
