# Lunar Lander - Component Configurations

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
  color: const Color(0xFFF26430), // Rocket Flame
)
```

## Dartboard Emulator Components

### DartboardSectionConfig
**Factory Method:** `DartboardSectionConfig.lunarLander()`

**Configuration:**
```dart
factory DartboardSectionConfig.lunarLander() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xFF0D1B2A),           // Space Black
    borderRadius: BorderRadius.circular(8),
    disabledOverlayBackgroundColor: const Color(0xFF1B4965).withOpacity(0.85), // Earth Blue
    disabledOverlayBorderColor: const Color(0xFFF26430), // Rocket Flame
    removeButtonBackgroundColor: const Color(0xFFF26430), // Rocket Flame
    removeButtonBorderColor: const Color(0xFFF26430),
    removeButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6), // Star White
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
  config: DartboardSectionConfig.lunarLander(),
)
```

### DartboardFABConfig
**Factory Method:** `DartboardFABConfig.lunarLander()`

**Configuration:**
```dart
factory DartboardFABConfig.lunarLander() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xFF1B4965), // Earth Blue
    iconColor: const Color(0xFFF26430),       // Rocket Flame
    textColor: const Color(0xFFFAFDF6),       // Star White
    textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
  );
}
```

**Usage:** mount as an outer-Stack child via `Positioned(right: 16, bottom: 16, child: ...)`, NOT in `Scaffold.floatingActionButton`. See [Outer-Stack Modal Architecture](../../development/game-integration.md#outer-stack-modal-architecture).

```dart
Positioned(
  right: 16, bottom: 16,
  child: DartboardEmulatorFAB(
    controller: _dartboardEmulatorController,
    isConnected: !dartboardProvider.isEmulator,
    config: DartboardFABConfig.lunarLander(),
  ),
)
```

## Dialog Components

### Add Player Dialog
**Factory Method:** `AddPlayerDialogConfig.lunarLander()`

**Configuration:**
```dart
factory AddPlayerDialogConfig.lunarLander() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.95), // Space Black
    textColor: const Color(0xFFFAFDF6),                          // Star White
    titleStyle: GoogleFonts.orbitron(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    inputLabelStyle: GoogleFonts.exo2(
      fontSize: 14,
      color: const Color(0xFFC0C0C0), // Rocket Silver
    ),
    inputBorderColor: const Color(0xFF1B4965),       // Earth Blue
    inputFocusedBorderColor: const Color(0xFFF26430), // Rocket Flame
    inputErrorBorderColor: const Color(0xFFE63946),  // Thruster Red
    photoLabelStyle: GoogleFonts.exo2(
      fontSize: 14,
      color: const Color(0xFFC0C0C0),
    ),
    photoButtonColor: const Color(0xFF1B4965),
    photoButtonForegroundColor: const Color(0xFFFAFDF6),
    photoButtonBorderColor: const Color(0xFFF26430),
    photoButtonTextStyle: GoogleFonts.orbitron(fontSize: 14),
    photoButtonWidth: null,
    addButtonColor: const Color(0xFFF26430),          // Rocket Flame
    addButtonForegroundColor: const Color(0xFFFAFDF6),
    addButtonBorderColor: const Color(0xFFF26430),
    addButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    cancelButtonColor: const Color(0xFF1B4965),
    cancelButtonForegroundColor: const Color(0xFFFAFDF6),
    cancelButtonBorderColor: const Color(0xFFC0C0C0),
    cancelButtonTextStyle: GoogleFonts.orbitron(fontSize: 16),
    errorTextColor: const Color(0xFFE63946),
  );
}
```

**Usage:**
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.lunarLander(),
);
```

### Edit Score Dialog
**Factory Method:** `EditScoreDialogConfig.lunarLander()`

**Configuration:**
```dart
factory EditScoreDialogConfig.lunarLander() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.95),
    borderColor: const Color(0xFF1B4965),
    borderWidth: 2,
    titleStyle: GoogleFonts.orbitron(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    dartLabelStyle: GoogleFonts.exo2(
      fontSize: 14,
      color: const Color(0xFFC0C0C0),
    ),
    scoreBoxBackgroundColor: const Color(0xFF1B4965),
    scoreBoxDefaultBorderColor: const Color(0xFFC0C0C0),
    scoreTextStyle: GoogleFonts.orbitron(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    buttonUnselectedColor: const Color(0xFF1B4965),
    buttonUnselectedForeground: const Color(0xFFFAFDF6),
    buttonSelectedColor: const Color(0xFFF26430),
    buttonSelectedForeground: const Color(0xFFFAFDF6),
    buttonTextStyle: GoogleFonts.orbitron(fontSize: 13),
    cancelButtonColor: const Color(0xFF1B4965),
    cancelButtonForeground: const Color(0xFFFAFDF6),
    cancelButtonTextStyle: GoogleFonts.orbitron(fontSize: 14),
    submitButtonColor: const Color(0xFFF26430),
    submitButtonForeground: const Color(0xFFFAFDF6),
    submitButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    // scoreDisplayTransform maps score 0 to 'Miss' so the Save button stays
    // enabled when misses are present (see implementation-notes.md)
    scoreDisplayTransform: (segment) =>
        segment.score == 0 ? 'Miss' : segment.score.toString(),
  );
}
```

**Usage:**
```dart
showEditScoreDialog(
  context: context,
  playerName: provider.currentPlayerName,
  initialSegments: provider.currentTurnSegments,
  onSubmit: (newSegments) => provider.editScore(newSegments),
  config: EditScoreDialogConfig.lunarLander(),
);
```

## Player List Panel

### DualPlayerListPanelConfig
**Factory Method:** `DualPlayerListPanelConfig.lunarLander()`

**Important:** Lunar Lander uses `DualPlayerListPanel` (two side-by-side lists: Available and Selected). There is NO team mode and `TeamPlayerListPanel` must NOT be used.

**Configuration:**
```dart
factory DualPlayerListPanelConfig.lunarLander() {
  return DualPlayerListPanelConfig(
    backgroundColor: const Color(0xFF1B4965).withOpacity(0.8),
    borderColor: const Color(0xFFF26430),
    headerStyle: GoogleFonts.orbitron(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    playerTileStyle: GoogleFonts.exo2(
      fontSize: 14,
      color: const Color(0xFFFAFDF6),
    ),
    addButtonColor: const Color(0xFFF26430),
    addButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    maxPlayers: 8,
  );
}
```

## Modal Components

### RemoveDartsModalConfig
**Factory Method:** `RemoveDartsModalConfig.lunarLander()`

**Configuration:**
```dart
factory RemoveDartsModalConfig.lunarLander() {
  return RemoveDartsModalConfig(
    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.95),
    borderColor: const Color(0xFFF26430),
    titleStyle: GoogleFonts.orbitron(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    messageStyle: GoogleFonts.exo2(
      fontSize: 16,
      color: const Color(0xFFFAFDF6),
    ),
    primaryButtonColor: const Color(0xFFF26430),
    primaryButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    editScoreButtonColor: const Color(0xFF1B4965),
    editScoreButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 14,
      color: const Color(0xFFFAFDF6),
    ),
  );
}
```

### DartboardConnectionInfoConfig
**Factory Method:** `DartboardConnectionInfoConfig.lunarLander()`

**Configuration:**
```dart
factory DartboardConnectionInfoConfig.lunarLander() {
  return DartboardConnectionInfoConfig(
    connectedColor: const Color(0xFF52B788),   // Mission Green
    disconnectedColor: const Color(0xFFE63946), // Thruster Red
    textStyle: GoogleFonts.exo2(
      fontSize: 12,
      color: const Color(0xFFFAFDF6),
    ),
  );
}
```

### DartboardPausedModalConfig
**Factory Method:** `DartboardPausedModalConfig.lunarLander()`

**Configuration:**
```dart
factory DartboardPausedModalConfig.lunarLander() {
  return DartboardPausedModalConfig(
    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.95),
    borderColor: const Color(0xFFF26430),
    titleStyle: GoogleFonts.orbitron(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    messageStyle: GoogleFonts.exo2(
      fontSize: 16,
      color: const Color(0xFFFAFDF6),
    ),
  );
}
```

### SaveGameModalConfig
**Factory Method:** `SaveGameModalConfig.lunarLander()`

**Configuration:**
```dart
factory SaveGameModalConfig.lunarLander() {
  return SaveGameModalConfig(
    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.95),
    borderColor: const Color(0xFF1B4965),
    titleStyle: GoogleFonts.orbitron(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    messageStyle: GoogleFonts.exo2(
      fontSize: 14,
      color: const Color(0xFFFAFDF6),
    ),
    saveButtonColor: const Color(0xFFF26430),
    saveButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    dontSaveButtonColor: const Color(0xFF1B4965),
    dontSaveButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 14,
      color: const Color(0xFFFAFDF6),
    ),
    cancelButtonColor: const Color(0xFFE63946),
    cancelButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 14,
      color: const Color(0xFFFAFDF6),
    ),
  );
}
```

### ResumeGameModalConfig
**Factory Method:** `ResumeGameModalConfig.lunarLander()`

**Configuration:**
```dart
factory ResumeGameModalConfig.lunarLander() {
  return ResumeGameModalConfig(
    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.95),
    borderColor: const Color(0xFF1B4965),
    titleStyle: GoogleFonts.orbitron(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    gameNameStyle: GoogleFonts.orbitron(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFF26430),
    ),
    infoStyle: GoogleFonts.exo2(
      fontSize: 13,
      color: const Color(0xFFC0C0C0),
    ),
    resumeButtonColor: const Color(0xFFF26430),
    resumeButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFAFDF6),
    ),
    newGameButtonColor: const Color(0xFF1B4965),
    newGameButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 14,
      color: const Color(0xFFFAFDF6),
    ),
    deleteButtonColor: const Color(0xFFE63946),
    deleteButtonTextStyle: GoogleFonts.orbitron(
      fontSize: 12,
      color: const Color(0xFFFAFDF6),
    ),
  );
}
```

## Play to Complete

### PlayToCompleteStrategy
**File:** `lib/services/play_to_complete/lunar_lander_strategy.dart`

**Description:** Drives automated play-to-completion for testing. The strategy reads the current player's altitude and selects darts that efficiently reduce it toward zero. When Hard Landing is enabled, the strategy avoids going below zero. The strategy always returns valid dart throws until `hasWinner` becomes true.

**Implementation:**
```dart
class LunarLanderStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    return context.read<LunarLanderProvider>().hasWinner;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<LunarLanderProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<LunarLanderProvider>();
    if (provider.hasWinner) return null;
    final altitude = provider.currentPlayerAltitude;
    final hardLanding = provider.currentGame.hardLandingEnabled;
    // Strategy: throw T20 (60) when altitude > 60, or choose a dart
    // that reaches exactly 0 or below (if Hard Landing OFF), or exactly 0
    // (if Hard Landing ON), falling back to safe smaller values.
    return _selectDart(altitude, hardLanding);
  }
}
```

### PlayToCompleteButtonConfig
**Factory Method:** `PlayToCompleteButtonConfig.lunarLander()`

**Configuration:**
```dart
factory PlayToCompleteButtonConfig.lunarLander() {
  return PlayToCompleteButtonConfig(
    backgroundColor: const Color(0xFF52B788),   // Mission Green
    foregroundColor: const Color(0xFFFAFDF6),   // Star White
    borderColor: const Color(0xFF52B788),
    textStyle: GoogleFonts.orbitron(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );
}
```

## Custom Components

Lunar Lander does not define any game-specific custom widget classes. All shared widgets are used via their factory configurations above. The unique game UI elements (descent tracks, active player panel, rocket icons, dart indicators) are built inline within `LunarLanderGameScreen` using standard Flutter widgets.
