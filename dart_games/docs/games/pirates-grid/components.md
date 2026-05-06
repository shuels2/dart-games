# Pirate's Grid - Component Configurations

## Shared Global Components

### ResumeGameButton
**Description:** Icon button in menu screen AppBar for accessing saved games

**File:** `lib/widgets/resume_game_button.dart`

**Documentation:** See [Save & Resume Game](../../development/save-resume-game.md#resume-game-button-menu-screen)

**Usage:**
```dart
ResumeGameButton(
  hasSavedGames: _hasSavedGames,
  onPressed: () => setState(() => _showResumeModal = true),
  color: const Color(0xFFDAA520), // Treasure Gold
)
```

## Dartboard Emulator Components

### DartboardSectionConfig
**Factory Method:** `DartboardSectionConfig.piratesGrid()`

**Configuration:**
```dart
factory DartboardSectionConfig.piratesGrid() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xFF1B2838),          // Ocean Navy
    borderRadius: BorderRadius.circular(8),
    disabledOverlayBackgroundColor: const Color(0xFF1B2838).withOpacity(0.7),
    disabledOverlayBorderColor: const Color(0xFFCD7F32), // Compass Rose Bronze
    removeButtonBackgroundColor: const Color(0xFFCD7F32),
    removeButtonBorderColor: const Color(0xFFDAA520),
    removeButtonTextStyle: GoogleFonts.pirataOne(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFF5E6C8), // Parchment Tan
    ),
  );
}
```

**Usage:**
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: piratesGridProvider.shouldPromptTakeout,
  dartboardKey: _dartboardKey,
  onDartThrow: _handleDartThrow,
  onRemoveDarts: _handleRemoveDarts,
  config: DartboardSectionConfig.piratesGrid(),
)
```

### DartboardFABConfig
**Factory Method:** `DartboardFABConfig.piratesGrid()`

**Configuration:**
```dart
factory DartboardFABConfig.piratesGrid() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xFFCD7F32),   // Compass Rose Bronze
    iconColor: const Color(0xFFF5E6C8),         // Parchment Tan
    textColor: const Color(0xFFF5E6C8),
    textStyle: GoogleFonts.pirataOne(fontWeight: FontWeight.bold),
  );
}
```

**Usage:** Mount as an outer-Stack child via `Positioned(right: 16, bottom: 16, child: ...)`, NOT in `Scaffold.floatingActionButton`. See [Outer-Stack Modal Architecture](../../development/game-integration.md#outer-stack-modal-architecture) for the full layer order.

```dart
Positioned(
  right: 16, bottom: 16,
  child: DartboardEmulatorFAB(
    controller: _dartboardEmulatorController,
    isConnected: !dartboardProvider.isEmulator,
    config: DartboardFABConfig.piratesGrid(),
  ),
)
```

## Dialog Components

### Add Player Dialog
**Factory Method:** `AddPlayerDialogConfig.piratesGrid()`

**Configuration:**
```dart
factory AddPlayerDialogConfig.piratesGrid() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xFF1B2838).withOpacity(0.95), // Ocean Navy
    textColor: const Color(0xFFF5E6C8),                          // Parchment Tan
    titleStyle: GoogleFonts.pirataOne(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFDAA520), // Treasure Gold
    ),
    inputLabelStyle: GoogleFonts.lora(
      fontSize: 14,
      color: const Color(0xFFF5E6C8),
    ),
    inputBorderColor: const Color(0xFFCD7F32),          // Compass Rose Bronze
    inputFocusedBorderColor: const Color(0xFFDAA520),   // Treasure Gold
    inputErrorBorderColor: const Color(0xFF8B0000),     // Blood Red
    photoLabelStyle: GoogleFonts.lora(fontSize: 14, color: const Color(0xFFF5E6C8)),
    photoButtonColor: const Color(0xFF8B4513),          // Worn Leather Brown
    photoButtonForegroundColor: const Color(0xFFF5E6C8),
    photoButtonBorderColor: const Color(0xFFCD7F32),
    photoButtonTextStyle: GoogleFonts.pirataOne(fontSize: 14),
    photoButtonWidth: null,
    addButtonColor: const Color(0xFFCD7F32),            // Compass Rose Bronze
    addButtonForegroundColor: const Color(0xFFF5E6C8),
    addButtonBorderColor: const Color(0xFFDAA520),
    addButtonTextStyle: GoogleFonts.pirataOne(fontSize: 16, fontWeight: FontWeight.bold),
    cancelButtonColor: const Color(0xFF1A1A1A),         // Ink Black
    cancelButtonForegroundColor: const Color(0xFFF5E6C8),
    cancelButtonBorderColor: const Color(0xFFCD7F32),
    cancelButtonTextStyle: GoogleFonts.pirataOne(fontSize: 16),
    errorTextColor: const Color(0xFF8B0000),            // Blood Red
  );
}
```

**Usage:**
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.piratesGrid(),
);
```

### Edit Score Dialog
**Factory Method:** `EditScoreDialogConfig.piratesGrid()`

**Pattern:** Pattern B — no `scoreDisplayTransform`. Segments display as raw dart notation (e.g., "S20", "D17", "Bull"). This is appropriate because Pirate's Grid scores are based on the dart segment hit, not a transformed score value.

**Configuration:**
```dart
factory EditScoreDialogConfig.piratesGrid() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xFF1B2838).withOpacity(0.95),
    borderColor: const Color(0xFFCD7F32),               // Compass Rose Bronze
    borderWidth: 2.0,
    titleStyle: GoogleFonts.pirataOne(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFDAA520),
    ),
    dartLabelStyle: GoogleFonts.pirataOne(fontSize: 14, color: const Color(0xFFF5E6C8)),
    scoreBoxBackgroundColor: const Color(0xFF8B4513),   // Worn Leather Brown
    scoreBoxDefaultBorderColor: const Color(0xFFCD7F32),
    scoreTextStyle: GoogleFonts.pirataOne(fontSize: 14, color: const Color(0xFFF5E6C8)),
    buttonUnselectedColor: const Color(0xFF1A1A1A),
    buttonUnselectedForeground: const Color(0xFFF5E6C8),
    buttonSelectedColor: const Color(0xFFCD7F32),
    buttonSelectedForeground: const Color(0xFFF5E6C8),
    buttonTextStyle: GoogleFonts.pirataOne(fontSize: 13),
    cancelButtonColor: const Color(0xFF1A1A1A),
    cancelButtonForeground: const Color(0xFFF5E6C8),
    cancelButtonTextStyle: GoogleFonts.pirataOne(fontSize: 14),
    submitButtonColor: const Color(0xFFCD7F32),
    submitButtonForeground: const Color(0xFFF5E6C8),
    submitButtonTextStyle: GoogleFonts.pirataOne(fontSize: 14, fontWeight: FontWeight.bold),
    // No scoreDisplayTransform — raw segment notation shown (e.g., "S20", "D17", "Bull")
  );
}
```

**Usage:**
```dart
showEditScoreDialog(
  context: context,
  playerName: playerName,
  initialSegments: initialSegments,
  onSubmit: (newSegments) => _handleEditScore(newSegments),
  config: EditScoreDialogConfig.piratesGrid(),
);
```

### DartboardConnectionInfoConfig
**Factory Method:** `DartboardConnectionInfoConfig.piratesGrid()`

Used in all 3 AppBars (menu, game, results).

### DualPlayerListPanelConfig
**Factory Method:** `DualPlayerListPanelConfig.piratesGrid()`

Pirate's Grid enforces exactly 2 players. The config sets `maxPlayers: 2` so the start button is enabled at exactly 2 players selected and disabled otherwise.

### RemoveDartsModalConfig
**Factory Method:** `RemoveDartsModalConfig.piratesGrid()`

### DartboardPausedModalConfig
**Factory Method:** `DartboardPausedModalConfig.piratesGrid()`

### SaveGameModalConfig
**Factory Method:** `SaveGameModalConfig.piratesGrid()`

Shown when the player taps the back button from the game screen. Themed with pirate vocabulary ("Abandon ship?" / "Save yer progress").

### ResumeGameModalConfig
**Factory Method:** `ResumeGameModalConfig.piratesGrid()`

Shown on the menu screen when saved games exist. Allows players to resume a previous Best Of match mid-game.

### PlayToCompleteButtonConfig
**Factory Method:** `PlayToCompleteButtonConfig.piratesGrid()`

```dart
factory PlayToCompleteButtonConfig.piratesGrid() {
  return PlayToCompleteButtonConfig(
    backgroundColor: const Color(0xFFDAA520),   // Treasure Gold
    foregroundColor: const Color(0xFF1A1A1A),   // Ink Black
    borderColor: const Color(0xFFCD7F32),        // Compass Rose Bronze
    textStyle: GoogleFonts.pirataOne(fontSize: 14, fontWeight: FontWeight.bold),
  );
}
```

## Play to Complete

### PlayToCompleteStrategy
**File:** `lib/services/play_to_complete/pirates_grid_strategy.dart`

**Implementation:**
```dart
class PiratesGridStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    return context.read<PiratesGridProvider>().hasWinner;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<PiratesGridProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<PiratesGridProvider>();
    if (provider.hasWinner) return null;
    final game = provider.currentGame;
    if (game == null) return null;

    // Find the first unclaimed cell (or stealable cell in Steal Mode)
    // Generate a SimulatedThrow that satisfies the cell's requirement:
    //   anyMultiplier -> S20 (single 20 is always valid for Easy)
    //   doubleOnly    -> D20 (double 20)
    //   tripleOnly    -> T20 (triple 20, or the specific required number with triple)
    //   bull          -> 50 (inner bull)
    return _getThrowForNextCell(game);
  }
}
```

**Strategy details:**
- Targets the first empty cell (by row-major order); when Steal Mode is ON and no empty cells remain, targets the first stealable opponent cell
- For Easy difficulty: generates `SimulatedThrow(number: cellNumber, multiplier: 1)` (single)
- For Medium difficulty: generates `SimulatedThrow(number: cellNumber, multiplier: 2)` (double)
- For Hard difficulty: triple cells get `multiplier: 3`, double cells get `multiplier: 2`, Bull cell gets `SimulatedThrow(number: 50, multiplier: 1)` (inner bull)
- After each successful throw, the provider's `processDartThrow` handles win detection automatically

### PlayToCompleteButtonConfig
**Factory Method:** `PlayToCompleteButtonConfig.piratesGrid()` in `dartboard_emulator_config.dart`

## Custom Components

### ThreeInARowChecker
**Description:** Checks all 8 possible winning lines in a 3x3 grid and returns the winning line positions if found, or null if no winner.

**File:** `lib/screens/games/pirates_grid/utils/three_in_a_row_checker.dart`

**Usage:**
```dart
final checker = ThreeInARowChecker();
final winningLine = checker.check(grid, playerId);
// Returns List<GridPosition>? — the 3 positions forming a line, or null
```

Checks 8 lines: 3 horizontal (rows 0-2), 3 vertical (columns 0-2), 2 diagonal (top-left→bottom-right, top-right→bottom-left).

### GridTargetGenerator
**Description:** Generates the deterministic 3x3 grid target layout for a given difficulty setting.

**File:** `lib/screens/games/pirates_grid/utils/grid_target_generator.dart`

**Usage:**
```dart
final generator = GridTargetGenerator();
final grid = generator.generate(difficulty: TargetDifficulty.hard);
// Returns List<List<CellTarget>> — 3x3 matrix of CellTarget objects
// Each CellTarget has: number, requiredMultiplier (any/doubleOnly/tripleOnly/bull)
```

The layout is fully deterministic (no randomness) and matches the target tables in the spec exactly. The center cell on Hard is the Bull cell (number 0, special "bull" requirement).
