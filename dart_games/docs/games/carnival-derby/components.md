# Carnival Derby - Component Configurations

## Dartboard Emulator Components

### DartboardSectionConfig
**Factory Method:** `DartboardSectionConfig.carnivalDerby()`

**Configuration:**
```dart
factory DartboardSectionConfig.carnivalDerby() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xFF2B1810), // Dark Chocolate Brown
    borderRadius: BorderRadius.circular(12),
    disabledOverlayBackgroundColor: const Color(0xFFE63946).withOpacity(0.9), // Lava Red overlay
    disabledOverlayBorderColor: const Color(0xFFFFD700), // Canary Yellow border
    removeButtonBackgroundColor: const Color(0xFFFFD700), // Canary Yellow
    removeButtonBorderColor: const Color(0xFFE63946), // Lava Red border
    removeButtonTextStyle: GoogleFonts.bangers(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF2B1810), // Dark text on yellow background
    ),
  );
}
```

**Usage:**
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: horseRaceProvider.shouldPromptTakeout,
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
  config: DartboardSectionConfig.carnivalDerby(),
)
```

### DartboardFABConfig
**Factory Method:** `DartboardFABConfig.carnivalDerby()`

**Configuration:**
```dart
factory DartboardFABConfig.carnivalDerby() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xFFE63946), // Lava Red
    iconColor: const Color(0xFFFFD700), // Canary Yellow
    textColor: Colors.white,
    textStyle: GoogleFonts.luckiestGuy(fontWeight: FontWeight.bold),
  );
}
```

**Usage:**
```dart
DartboardEmulatorFAB(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  config: DartboardFABConfig.carnivalDerby(),
)
```

## Dialog Components

### Add Player Dialog
**Factory Method:** `AddPlayerDialogConfig.carnivalDerby()`

**Configuration:**
```dart
factory AddPlayerDialogConfig.carnivalDerby() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xFF2B1810).withOpacity(0.95), // Dark Chocolate Brown
    textColor: const Color(0xFFFFD700), // Canary Yellow
    titleStyle: GoogleFonts.rye(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFD700),
    ),
    inputLabelStyle: GoogleFonts.montserrat(
      fontSize: 14,
      color: const Color(0xFFFFD700).withOpacity(0.9),
    ),
    inputBorderColor: const Color(0xFFFFD700).withOpacity(0.5),
    inputFocusedBorderColor: const Color(0xFFFFD700),
    inputErrorBorderColor: const Color(0xFFE63946), // Lava Red
    photoLabelStyle: GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFD700),
    ),
    photoButtonColor: const Color(0xFF48CAE4), // Electric Teal
    photoButtonForegroundColor: Colors.white,
    photoButtonBorderColor: const Color(0xFFFFD700),
    photoButtonTextStyle: GoogleFonts.bangers(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    photoButtonWidth: 130.0,
    addButtonColor: const Color(0xFFE63946), // Lava Red
    addButtonForegroundColor: Colors.white,
    addButtonBorderColor: const Color(0xFFFFD700),
    addButtonTextStyle: GoogleFonts.luckiestGuy(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    cancelButtonColor: const Color(0xFF8B5E3C), // Cedar
    cancelButtonForegroundColor: Colors.white,
    cancelButtonBorderColor: const Color(0xFFFFD700),
    cancelButtonTextStyle: GoogleFonts.montserrat(
      fontSize: 16,
    ),
    errorTextColor: const Color(0xFFE63946), // Lava Red
  );
}
```

**Usage:**
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.carnivalDerby(),
);
```

### Edit Score Dialog
**Factory Method:** `EditScoreDialogConfig.carnivalDerby()`

**Configuration:**
```dart
factory EditScoreDialogConfig.carnivalDerby() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.95), // Midnight Navy
    borderColor: const Color(0xFFFFD700), // Canary Yellow
    borderWidth: 4,
    titleStyle: GoogleFonts.luckiestGuy(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFD700),
    ),
    dartLabelStyle: GoogleFonts.bangers(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.white70,
    ),
    scoreBoxBackgroundColor: const Color(0xFF1B263B),
    scoreBoxDefaultBorderColor: const Color(0xFFFFD700),
    scoreTextStyle: GoogleFonts.bangers(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFD700),
    ),
    buttonUnselectedColor: const Color(0xFF415A77),
    buttonUnselectedForeground: Colors.white,
    buttonSelectedColor: const Color(0xFFFFD700), // Canary Yellow
    buttonSelectedForeground: Colors.black,
    buttonTextStyle: GoogleFonts.bangers(fontSize: 12, fontWeight: FontWeight.bold),
    cancelButtonColor: Colors.grey.withOpacity(0.85),
    cancelButtonForeground: Colors.white,
    cancelButtonTextStyle: GoogleFonts.bangers(fontSize: 16, fontWeight: FontWeight.bold),
    submitButtonColor: const Color(0xFFE63946).withOpacity(0.85), // Lava Red
    submitButtonForeground: Colors.white,
    submitButtonTextStyle: GoogleFonts.luckiestGuy(fontSize: 16, fontWeight: FontWeight.bold),
    scoreDisplayTransform: (segment) {
      // Show calculated point values instead of raw segment strings
      return _parseSegmentToScore(segment);
    },
  );
}
```

**Usage:**
```dart
showEditScoreDialog(
  context: context,
  playerName: currentPlayer.name,
  initialSegments: horseRaceProvider.getCurrentTurnDartScores(currentPlayer.id),
  onSubmit: (newSegments) =>
      horseRaceProvider.updateAllDartScores(currentPlayer.id, newSegments),
  config: EditScoreDialogConfig.carnivalDerby(),
  // No dartBorderColors - uniform Canary Yellow borders
);
```

## Custom Components

### RaceTrackWidget
**Description:** Displays the horse racing track with player positions

**File:** `lib/widgets/horse_race/race_track_widget.dart`

**Usage:**
```dart
RaceTrackWidget(
  players: players,
  currentGame: horseRaceProvider.currentGame!,
  horseRaceProvider: horseRaceProvider,
)
```

**Features:**
- Oval track visualization
- Horse icons positioned by score percentage
- Finish line marker at 100%
- Current player highlighting

### PlayerAvatarWidget
**Description:** Displays player avatar with horse icon and name

**File:** `lib/widgets/player_avatar_widget.dart`

**Usage:**
```dart
PlayerAvatarWidget(
  player: player,
  position: horseRaceProvider.getHorsePosition(player.id),
  isCurrentPlayer: currentPlayer?.id == player.id,
)
```

**Features:**
- Player photo or default icon
- Horse position indicator
- Current player highlighting with glow effect
- Score progress visualization

### CarnivalStringLights
**Description:** Decorative string lights overlay for carnival atmosphere

**File:** `lib/widgets/carnival_string_lights.dart`

**Usage:**
```dart
const CarnivalStringLights()
```

**Features:**
- Positioned across top of screen
- Canary Yellow glow effect
- Enhances carnival theme

### CarnivalTargetLogo
**Description:** Large centered carnival dartboard target logo

**File:** `lib/widgets/carnival_target_logo.dart`

**Usage:**
```dart
const CarnivalTargetLogo(size: 700.0)
```

**Features:**
- Centered behind content
- Provides visual depth
- Reinforces carnival theme

### PlayerSelectionCard
**Description:** Drag-and-drop player selection card for menu screen

**File:** `lib/widgets/player_selection_card.dart`

**Usage:**
```dart
PlayerSelectionCard(
  player: player,
  isSelected: isSelected,
  onTap: () => _handlePlayerToggle(player),
)
```

**Features:**
- Draggable between Available and Selected lists
- Visual selection state (Electric Teal when selected)
- Player photo and name display
- Carnival Derby color scheme
