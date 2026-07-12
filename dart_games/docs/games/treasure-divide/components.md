# Treasure Divide - Component Configurations

## Shared Global Components

### ResumeGameButton

**Description:** Icon button positioned above the "SET SAIL!" button (or in AppBar actions) for accessing saved games.

**File:** `lib/widgets/resume_game_button.dart`

**Documentation:** See [Save & Resume Game](../../development/save-resume-game.md#resume-game-button-menu-screen)

**Usage:**
```dart
ResumeGameButton(
  hasSavedGames: _hasSavedGames,
  onPressed: () => setState(() => _showResumeModal = true),
  color: const Color(0xFFFFD700), // Treasure Gold
)
```

## Dartboard Emulator Components

### DartboardSectionConfig

**Factory Method:** `DartboardSectionConfig.treasureDivide()`

**Configuration:**
```dart
factory DartboardSectionConfig.treasureDivide() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xFF008B8B),         // Ocean Teal
    borderRadius: BorderRadius.circular(8),
    disabledOverlayBackgroundColor: const Color(0xFF008B8B).withOpacity(0.6),
    disabledOverlayBorderColor: const Color(0xFFFFD700),  // Treasure Gold
    removeButtonBackgroundColor: const Color(0xFF8B6914),  // Plank Brown
    removeButtonBorderColor: const Color(0xFFFFD700),
    removeButtonTextStyle: GoogleFonts.merriweather(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFF8E7),  // Sail White
    ),
  );
}
```

**Usage:**
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: _shouldPromptTakeout,
  dartboardKey: _dartboardKey,
  onDartThrow: _handleDartThrow,
  onRemoveDarts: _handleRemoveDarts,
  config: DartboardSectionConfig.treasureDivide(),
)
```

### DartboardFABConfig

**Factory Method:** `DartboardFABConfig.treasureDivide()`

**Configuration:**
```dart
factory DartboardFABConfig.treasureDivide() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xFF008B8B),   // Ocean Teal
    iconColor: const Color(0xFFFFD700),          // Treasure Gold
    textColor: const Color(0xFFFFF8E7),          // Sail White
    textStyle: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
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
    config: DartboardFABConfig.treasureDivide(),
  ),
)
```

## Dialog Components

### Add Player Dialog

**Factory Method:** `AddPlayerDialogConfig.treasureDivide()`

**Configuration:**
```dart
factory AddPlayerDialogConfig.treasureDivide() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xFF008B8B).withOpacity(0.95),  // Ocean Teal
    textColor: const Color(0xFFFFF8E7),
    titleStyle: GoogleFonts.pirataOne(
      fontSize: 24,
      fontWeight: FontWeight.normal,
      color: const Color(0xFFFFD700),
    ),
    inputLabelStyle: GoogleFonts.merriweather(fontSize: 14, color: const Color(0xFFFFF8E7)),
    inputBorderColor: const Color(0xFF8B6914),
    inputFocusedBorderColor: const Color(0xFFFFD700),
    inputErrorBorderColor: const Color(0xFFC41E3A),
    photoLabelStyle: GoogleFonts.merriweather(fontSize: 14, color: const Color(0xFFFFF8E7)),
    photoButtonColor: const Color(0xFF8B6914),
    photoButtonForegroundColor: const Color(0xFFFFF8E7),
    photoButtonBorderColor: const Color(0xFFFFD700),
    photoButtonTextStyle: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
    photoButtonWidth: null,
    addButtonColor: const Color(0xFFFFD700),
    addButtonForegroundColor: const Color(0xFF008B8B),
    addButtonBorderColor: const Color(0xFFFFD700),
    addButtonTextStyle: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
    cancelButtonColor: const Color(0xFF8B6914),
    cancelButtonForegroundColor: const Color(0xFFFFF8E7),
    cancelButtonBorderColor: const Color(0xFF8B6914),
    cancelButtonTextStyle: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
    errorTextColor: const Color(0xFFC41E3A),
  );
}
```

**Usage:**
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.treasureDivide(),
);
```

### Edit Score Dialog

**Factory Method:** `EditScoreDialogConfig.treasureDivide()`

**Configuration:**
```dart
factory EditScoreDialogConfig.treasureDivide() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xFF008B8B).withOpacity(0.95),
    borderColor: const Color(0xFFFFD700),
    borderWidth: 2,
    titleStyle: GoogleFonts.pirataOne(fontSize: 22, color: const Color(0xFFFFD700)),
    dartLabelStyle: GoogleFonts.merriweather(fontSize: 14, color: const Color(0xFFFFF8E7)),
    scoreBoxBackgroundColor: const Color(0xFF8B6914),
    scoreBoxDefaultBorderColor: const Color(0xFFFFD700),
    scoreTextStyle: GoogleFonts.pirataOne(fontSize: 20, color: const Color(0xFFFFD700)),
    buttonUnselectedColor: const Color(0xFF8B6914),
    buttonUnselectedForeground: const Color(0xFFFFF8E7),
    buttonSelectedColor: const Color(0xFFFFD700),
    buttonSelectedForeground: const Color(0xFF008B8B),
    buttonTextStyle: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
    cancelButtonColor: const Color(0xFF8B6914),
    cancelButtonForeground: const Color(0xFFFFF8E7),
    cancelButtonTextStyle: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
    submitButtonColor: const Color(0xFFFFD700),
    submitButtonForeground: const Color(0xFF008B8B),
    submitButtonTextStyle: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
  );
}
```

**Note:** Edit Score is accessible ONLY through RemoveDartsModal — there is no standalone Edit Score button on the main game screen.

**Usage:**
```dart
showEditScoreDialog(
  context: context,
  playerName: playerName,
  initialSegments: segments,
  onSubmit: (newSegments) => _handleEditScore(newSegments),
  config: EditScoreDialogConfig.treasureDivide(),
);
```

### TeamPlayerListPanel Config

**Factory Method:** `TeamPlayerListPanelConfig.treasureDivide()`

```dart
factory TeamPlayerListPanelConfig.treasureDivide() {
  return TeamPlayerListPanelConfig(
    minPlayers: 2,
    minPlayersTeamMode: 3,
    maxPlayersSolo: 8,
    maxPlayers: 10,
    maxTeams: 5,
    maxPlayersPerTeam: 2,
  );
}
```

**Note:** Always use `TeamPlayerListPanel` (NOT `DualPlayerListPanel`). The same panel serves both Solo and Team modes; `isTeamMode` and `isManualTeamAssignment` flags toggle the crew UI. See [Player List Panel](../../development/player-list-panel.md).

### Remove Darts Modal Config

**Factory Method:** `RemoveDartsModalConfig.treasureDivide()`

Styled with Ocean Teal background, Treasure Gold borders, PirataOne title font.

### Save Game Modal Config

**Factory Method:** `SaveGameModalConfig.treasureDivide()`

Styled with Ocean Teal background, Treasure Gold accents, Merriweather body font.

### Resume Game Modal Config

**Factory Method:** `ResumeGameModalConfig.treasureDivide()`

Styled with Ocean Teal background, Treasure Gold highlights for the saved game list.

### Dartboard Connection Info Config

**Factory Method:** `DartboardConnectionInfoConfig.treasureDivide()`

Styled with Ocean Teal / Treasure Gold theme to match AppBar.

## Play to Complete

### TreasureDivideStrategy

**File:** `lib/services/play_to_complete/treasure_divide_strategy.dart`

**Implementation:**
```dart
class TreasureDivideStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    return context.read<TreasureDivideProvider>().hasWinner;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<TreasureDivideProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<TreasureDivideProvider>();
    if (provider.hasWinner) return null;

    final target = provider.currentTarget;
    // For sentinel targets, map to an appropriate dart value:
    //   kTargetAnyDouble → D20 (score = 40)
    //   kTargetAnyTriple → T20 (score = 60)
    //   kTargetBull → Bull (score = 50)
    // For numeric targets, throw a Single of that number.
    // Returns a SimulatedThrow with the segment that hits the current target.
    return _pickThrowForTarget(target, provider.isTeamMode);
  }
}
```

**Key design notes:**
- `winnerId` is designated by the strategy itself — it picks one player/crew to "win" (generally the first selected) and routes all simulated throws through that player's turn while allowing all others to hit normally (so no one is penalized by halving)
- For `kTargetAnyDouble`, simulates D20 (any double counts)
- For `kTargetAnyTriple`, simulates T20 (any triple counts)
- For `kTargetBull`, simulates inner bull (50)
- The strategy ensures `shouldAutoTakeout` returns `true` when `provider.shouldPromptTakeout` is true

### PlayToCompleteButtonConfig

**Factory Method:** `PlayToCompleteButtonConfig.treasureDivide()`

```dart
factory PlayToCompleteButtonConfig.treasureDivide() {
  return PlayToCompleteButtonConfig(
    backgroundColor: const Color(0xFFFFD700),  // Treasure Gold
    foregroundColor: const Color(0xFF008B8B),  // Ocean Teal
    borderColor: const Color(0xFFFFD700),
    textStyle: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
  );
}
```

## Custom Components

### PirateAvatarWidget

**Description:** Renders a player's avatar photo with pirate-themed accessory sprites overlaid at face-landmark-derived anchor points. Supports 8 distinct pirate themes (Captain, First Mate, Bosun, Navigator, Lookout, Cook, Gunner, Cabin Boy). Falls back to heuristic anchor placement when `faceLandmarks` is null.

**File:** `lib/widgets/treasure_divide/pirate_avatar_widget.dart`

**Constructor parameters:**
| Parameter | Type | Purpose |
|---|---|---|
| `playerId` | `String` | Looks up the player in `PlayerProvider` to fetch avatar + `faceLandmarks` |
| `themeIndex` | `int` (0..7) | Index into the 8 themes; from the saved game's `playerPirateThemes` map |
| `size` | `double` | Render dimension (square), e.g. 24, 40, 48, 80, 120 |
| `borderColor` | `Color?` | Optional border (active-player highlight, winner's golden ring) |

**Usage:**
```dart
PirateAvatarWidget(
  playerId: player.id,
  themeIndex: game.playerPirateThemes[player.id] ?? 0,
  size: 80,
  borderColor: const Color(0xFFFFD700),  // Treasure Gold for winner
)
```

**Renders in:** Active Player Panel, per-player/per-crew bottom strip tiles, Results screen winner display, Results screen rankings. Does NOT render in the menu's Available/Selected player lists (plain `PlayerAvatarWidget` is used there).

### TreasureMapWidget

**Description:** The dominant centrepiece of the game screen. Renders the treasure map parchment with islands laid out on a winding path. Highlights the current island with a pulsing glow, marks completed islands with a check, and shows "???" on future islands when Custom Targets is ON.

**File:** `lib/widgets/treasure_divide/treasure_map_widget.dart`

**Key props:**
- `currentRound` (int) — the round index currently active (0-based)
- `totalRounds` (int) — 7, 9, or 12
- `targets` (List) — the target sequence (may contain sentinel constants)
- `customTargetsEnabled` (bool) — shows "???" on future islands if true
- `activePlayerTreasure` (int) — treasure total to display on the chest in the corner
- `isHalved` (bool) — triggers the chest-tip animation

**Usage:**
```dart
TreasureMapWidget(
  currentRound: provider.currentRound,
  totalRounds: provider.totalRounds,
  targets: provider.targetSequence,
  customTargetsEnabled: provider.customTargetsEnabled,
  activePlayerTreasure: provider.activePlayerTreasure,
  isHalved: provider.lastRoundWasHalved,
)
```
