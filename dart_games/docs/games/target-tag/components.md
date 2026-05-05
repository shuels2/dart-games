# Target Tag - Component Configurations

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
  color: Colors.white,
)
```

## Dartboard Emulator Components

### DartboardSectionConfig
**Factory Method:** `DartboardSectionConfig.targetTag()`

**Configuration:**
```dart
factory DartboardSectionConfig.targetTag() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xFF0A1929), // Dark Navy
    borderRadius: BorderRadius.circular(12),
    disabledOverlayBackgroundColor: const Color(0xFF1E293B).withOpacity(0.9), // Slate overlay
    disabledOverlayBorderColor: const Color(0xFFFF007A), // Hot Pink border
    removeButtonBackgroundColor: const Color(0xFF00FFA3), // Neon Green
    removeButtonBorderColor: const Color(0xFFFF007A), // Hot Pink border
    removeButtonTextStyle: GoogleFonts.fredoka(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0A1929), // Dark text on green background
    ),
  );
}
```

**Usage:**
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: targetTagProvider.shouldPromptTakeout,
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
  },
  config: DartboardSectionConfig.targetTag(),
)
```

### DartboardFABConfig
**Factory Method:** `DartboardFABConfig.targetTag()`

**Configuration:**
```dart
factory DartboardFABConfig.targetTag() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xFFFF007A), // Hot Pink
    iconColor: Colors.white,
    textColor: Colors.white,
    textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
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
    config: DartboardFABConfig.targetTag(),
  ),
)
```

## Dialog Components

### Add Player Dialog
**Factory Method:** `AddPlayerDialogConfig.targetTag()`

**Configuration:**
```dart
factory AddPlayerDialogConfig.targetTag() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xFF0A1929).withOpacity(0.95), // Dark Navy
    textColor: const Color(0xFF00FFA3), // Neon Green
    titleStyle: GoogleFonts.fredoka(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF00FFA3),
    ),
    inputLabelStyle: GoogleFonts.fredoka(
      fontSize: 14,
      color: const Color(0xFF00FFA3).withOpacity(0.9),
    ),
    inputBorderColor: const Color(0xFF00FFA3).withOpacity(0.5),
    inputFocusedBorderColor: const Color(0xFF00FFA3),
    inputErrorBorderColor: const Color(0xFFFF007A), // Hot Pink
    photoLabelStyle: GoogleFonts.fredoka(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF00FFA3),
    ),
    photoButtonColor: const Color(0xFFFF007A), // Hot Pink
    photoButtonForegroundColor: Colors.white,
    photoButtonBorderColor: const Color(0xFF00FFA3),
    photoButtonTextStyle: GoogleFonts.fredoka(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    photoButtonWidth: 130.0,
    addButtonColor: const Color(0xFF00FFA3), // Neon Green
    addButtonForegroundColor: const Color(0xFF0A1929), // Dark text
    addButtonBorderColor: const Color(0xFFFF007A),
    addButtonTextStyle: GoogleFonts.fredoka(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    cancelButtonColor: const Color(0xFF475569), // Slate
    cancelButtonForegroundColor: Colors.white,
    cancelButtonBorderColor: const Color(0xFF00FFA3),
    cancelButtonTextStyle: GoogleFonts.fredoka(
      fontSize: 16,
    ),
    errorTextColor: const Color(0xFFFF007A), // Hot Pink
  );
}
```

**Usage:**
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.targetTag(),
);
```

### Edit Score Dialog
**Factory Method:** `EditScoreDialogConfig.targetTag()`

**Configuration:**
```dart
factory EditScoreDialogConfig.targetTag() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xFF0F172A).withOpacity(0.95), // Dark Navy
    borderColor: const Color(0xFFFF007A), // Hot Pink
    borderWidth: 4,
    titleStyle: GoogleFonts.fredoka(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF00FFA3), // Neon Green
    ),
    dartLabelStyle: GoogleFonts.fredoka(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.white70,
    ),
    scoreBoxBackgroundColor: const Color(0xFF1E293B),
    scoreBoxDefaultBorderColor: const Color(0xFF00FFA3), // Neon Green
    scoreTextStyle: GoogleFonts.fredoka(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    buttonUnselectedColor: const Color(0xFF334155),
    buttonUnselectedForeground: Colors.white,
    buttonSelectedColor: const Color(0xFF00FFA3), // Neon Green
    buttonSelectedForeground: Colors.black,
    buttonTextStyle: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold),
    cancelButtonColor: Colors.grey.withOpacity(0.85),
    cancelButtonForeground: Colors.white,
    cancelButtonTextStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
    submitButtonColor: const Color(0xFFFF007A).withOpacity(0.85), // Hot Pink
    submitButtonForeground: Colors.white,
    submitButtonTextStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
    // No scoreDisplayTransform - shows raw segment strings (S20, D15, etc.)
  );
}
```

**Usage:**
```dart
showEditScoreDialog(
  context: context,
  playerName: currentPlayer.name,
  initialSegments: targetTagProvider.getCurrentTurnDarts(currentPlayer.id),
  onSubmit: (newSegments) =>
      targetTagProvider.updateAllDartScores(currentPlayer.id, newSegments),
  config: EditScoreDialogConfig.targetTag(),
  dartBorderColors: _computeDartBorderColors(currentPlayer.id),
);
```

## Custom Components

### ActivePlayerPanelWidget
**Description:** Displays the active player's shields, target, Hero Bonus, and elimination status

**File:** `lib/widgets/target_tag/active_player_panel_widget.dart`

**Usage:**
```dart
ActivePlayerPanelWidget(
  player: currentPlayer,
  shields: shields,
  shieldMax: shieldMax,
  isTaggedIn: isTaggedIn,
  isEliminated: isEliminated,
  targetNumber: targetNumber,
  heroBonusNumber: heroBonusNumber,
  heroBonusMultiplier: heroBonusMultiplier,
)
```

**Features:**
- Large player photo display
- Shield count with visual bar
- Tagged In badge (hot pink)
- Target number display
- Hero Bonus display (if applicable)
- Elimination overlay (if eliminated)

### TeamModeIndicatorWidget
**Description:** Shows team icon, shields, and Tagged In status for team mode

**Usage:**
```dart
TeamModeIndicatorWidget(
  teamId: teamId,
  teamIcon: teamIconPath,
  shields: teamShields,
  shieldMax: shieldMax,
  isTaggedIn: isTeamTaggedIn,
)
```

**Features:**
- Team icon display
- Team shield count
- Tagged In badge for team
- Visual differentiation from solo mode

### OpponentTargetsGrid
**Description:** Grid display of all opponents with their targets and shield counts

**Usage:**
```dart
OpponentTargetsGrid(
  opponents: opponents,
  currentPlayerId: currentPlayerId,
  getShields: (playerId) => provider.getShields(playerId),
  isTaggedIn: (playerId) => provider.isTaggedIn(playerId),
  isEliminated: (playerId) => provider.isEliminated(playerId),
)
```

**Features:**
- Grid layout of opponent tiles
- Shows target numbers
- Shield count indicators
- Tagged In visual state
- Eliminated state (strikethrough, opacity)
