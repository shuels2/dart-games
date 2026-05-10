# Gladiator Arena - Component Configurations

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
  color: const Color(0xFFCD7F32), // Bronze
)
```

## Dartboard Emulator Components

### DartboardSectionConfig
**Factory Method:** `DartboardSectionConfig.gladiatorArena()`

**Configuration:**
```dart
factory DartboardSectionConfig.gladiatorArena() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xFFD2B48C), // Arena Sand
    borderRadius: BorderRadius.circular(8),
    disabledOverlayBackgroundColor: const Color(0xFFD2B48C).withOpacity(0.7),
    disabledOverlayBorderColor: const Color(0xFFCD7F32), // Bronze
    removeButtonBackgroundColor: const Color(0xFFCD7F32), // Bronze
    removeButtonBorderColor: const Color(0xFFDAA520), // Gladiator Gold
    removeButtonTextStyle: GoogleFonts.cinzel(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFF5F0E8), // Marble White
    ),
  );
}
```

**Usage:**
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: provider.shouldPromptTakeout,
  dartboardKey: _dartboardKey,
  onDartThrow: _handleDartThrow,
  onRemoveDarts: _handleRemoveDarts,
  config: DartboardSectionConfig.gladiatorArena(),
)
```

The `DartboardEmulatorSection` is mounted as a `Positioned(bottom: 0, left: 0, right: 0)` child of the **outer Stack** (sibling of Scaffold) — NOT inside the Scaffold body. This allows it to overlay the bottom of the game screen without consuming layout space. See the [Dartboard Emulator](../../development/dartboard-emulator.md) guide for the full outer-Stack pattern.

### DartboardFABConfig
**Factory Method:** `DartboardFABConfig.gladiatorArena()`

**Configuration:**
```dart
factory DartboardFABConfig.gladiatorArena() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xFFCD7F32), // Bronze
    iconColor: const Color(0xFFF5F0E8), // Marble White
    textColor: const Color(0xFFF5F0E8), // Marble White
    textStyle: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
  );
}
```

**Usage:** Mount as an outer-Stack child via `Positioned(right: 16, bottom: 16, child: ...)`, NOT in `Scaffold.floatingActionButton`. See [Outer-Stack Modal Architecture](../../development/game-integration.md#outer-stack-modal-architecture).

```dart
Positioned(
  right: 16, bottom: 16,
  child: DartboardEmulatorFAB(
    controller: _dartboardEmulatorController,
    isConnected: !dartboardProvider.isEmulator,
    config: DartboardFABConfig.gladiatorArena(),
  ),
)
```

## Dialog Components

### Add Player Dialog
**Factory Method:** `AddPlayerDialogConfig.gladiatorArena()`

**Configuration:** Arena Sand background, Marble White text, Bronze input borders, Gladiator Gold focused borders, Bronze add button, Colosseum Gray cancel button, Cinzel font throughout.

**Usage:**
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.gladiatorArena(),
);
```

### Edit Score Dialog
**Factory Method:** `EditScoreDialogConfig.gladiatorArena()`

**Configuration:** Arena Sand background with opacity, Bronze border, Cinzel title style, Gladiator Gold selected button, Bronze submit button, score display uses Pattern A (plain running total — no S/D/T transform needed since Edit Score shows individual dart segments directly).

**Usage:**
```dart
showEditScoreDialog(
  context: context,
  playerName: playerName,
  initialSegments: provider.currentDartSegments,
  onSubmit: (newSegments) => provider.updateAllDartScores(newSegments),
  config: EditScoreDialogConfig.gladiatorArena(),
);
```

Note: The `scoreDisplayTransform` is not needed for Gladiator Arena — the Edit Score dialog displays individual dart segment labels (S20, D10, T5, etc.) which is already the correct format. The provider uses the standard `Map<String, String>` dart segment approach.

### DualPlayerListPanel
**Factory Method:** `DualPlayerListPanelConfig.gladiatorArena()`

**Configuration:** Bronze accent for selected state, Gladiator Gold for player tile highlight, Marble White text, max 8 players, no team mode.

**Usage:**
```dart
DualPlayerListPanel(
  config: DualPlayerListPanelConfig.gladiatorArena(),
  onAddPlayerPressed: _showAddPlayerDialog,
)
```

### RemoveDartsModal
**Factory Method:** `RemoveDartsModalConfig.gladiatorArena()`

**Configuration:** Arena Sand background, Marble White text, Bronze "Remove Darts" button, Gladiator Gold border, "Edit player score" button uses Imperial Purple.

**Usage:** Standard integration via `shouldPromptTakeout` + `RemoveDartsModal` in the outer Stack when `!dartboardProvider.isConnected`.

### DartboardConnectionInfo
**Factory Method:** `DartboardConnectionInfoConfig.gladiatorArena()`

**Configuration:** Placed in AppBar actions (rightmost slot) for all three screens.

### SaveGameModal
**Factory Method:** `SaveGameModalConfig.gladiatorArena()`

**Configuration:** Arena Sand background, Bronze "Save & Leave" button, Marble White text, Cinzel font.

**Usage:** Triggered by the AppBar back button on the game screen.

### ResumeGameModal
**Factory Method:** `ResumeGameModalConfig.gladiatorArena()`

**Configuration:** Matches the game's Arena Sand / Bronze / Gladiator Gold palette.

**Usage:** Shown from menu screen when `_showResumeModal` is true.

## Play to Complete

### PlayToCompleteStrategy
**File:** `lib/services/play_to_complete/gladiator_arena_strategy.dart`
**Class:** `GladiatorArenaStrategy`

**Strategy pattern (Miss + Miss + winner-dart):** The strategy sends a Miss on dart 1, a Miss on dart 2, then a winning dart on dart 3. This ensures the turn total equals exactly the winning dart value, letting the provider's victory logic fire cleanly after a minimal number of darts.

- When Double Finish is ON: dart 3 is `D20` (double 20 = 40 points) — this is both a double AND scores enough to win from 0 (target defaulting to 200 requires multiple turns; the strategy works across turns until the score reaches target - 40, then sends D20 to finish)
- When Double Finish is OFF: dart 3 is `S20` (single 20) to score the final needed points

The strategy reads `gladiatorArenaProvider.currentPlayerScore`, `gladiatorArenaProvider.targetScore`, and `gladiatorArenaProvider.doubleFinishEnabled` each turn to decide the correct final dart.

**Implementation:**
```dart
class GladiatorArenaStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    return context.read<GladiatorArenaProvider>().hasWinner;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<GladiatorArenaProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<GladiatorArenaProvider>();
    if (provider.hasWinner) return null;
    // Miss, Miss, then scoring dart on dart 3
    // (see gladiator_arena_strategy.dart for full implementation)
  }
}
```

### PlayToCompleteButtonConfig
**Factory Method:** `PlayToCompleteButtonConfig.gladiatorArena()`

**Configuration:**
```dart
factory PlayToCompleteButtonConfig.gladiatorArena() {
  return PlayToCompleteButtonConfig(
    backgroundColor: const Color(0xFFDAA520), // Gladiator Gold
    foregroundColor: const Color(0xFFF5F0E8), // Marble White
    borderColor: const Color(0xFFCD7F32),     // Bronze
    textStyle: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
  );
}
```

## Custom Components

### Arena Podium Display
**Description:** The central visual of the game screen. Shows all players (2–8) as vertical podium bars in a horizontal row. Each podium's height is proportional to the player's score relative to the target score. The active player's podium has an Imperial Purple glow border and Gladiator Gold drop-shadow. Knocked-off players have their podium collapse to height 0 with a shake animation.

**Key rendering decisions:**
- Podium width = `(availableWidth - margins) / playerCount`, clamped 80–150px
- Podium bar color = Gladiator Gold for active player, player accent color for others
- Character image (60×60) sits on top of the bar; name label only appears for the active player (below the arena floor bar)
- `Double Range!` indicator only appears above the active player's podium when Double Finish is ON and the player is within double-finish range

### Elimination Zone
**Description:** A 60px strip at the bottom of the center area that displays the most recent knockoff event: "{victim} was knocked off by {attacker}!" in Lato 14pt Blood Red. The zone fades out after 5 seconds and is hidden when no recent knockoff occurred.
