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

## Testing

### Manual Testing
1. Run app without dartboard connected (emulator mode)
2. Verify FAB appears
3. Verify dartboard is visible by default
4. Click FAB to hide dartboard
5. Click FAB to show dartboard
6. Click dartboard segments - verify throws register
7. Connect to real dartboard - verify FAB and emulator disappear

### Unit Testing
Test your game logic with simulated dart throws, not the dartboard component itself.

## Reference Implementations

- **Carnival Derby:** `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart`
- **Target Tag:** `lib/screens/games/target_tag/target_tag_game_screen.dart`
- **Monster Mash:** `lib/screens/games/monster_mash/monster_mash_game_screen.dart`
- **Component Source:** `lib/widgets/dartboard_emulator/`

## Related Documentation

- [Adding New Games](adding-games.md)
- [Shared Systems - Dartboard Emulator](../architecture/shared-systems.md#6-in-game-dartboard-emulator-components)
- [Critical Rules - Dartboard Protection](../critical-rules/dartboard-protection.md)
- [Game Template - Components](../games/_GAME_TEMPLATE/components.md)
