# [Game Name] - Component Configurations

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
  color: const Color(0xXXXXXX), // [Game theme color]
)
```

## Dartboard Emulator Components

### DartboardSectionConfig
**Factory Method:** `DartboardSectionConfig.[gameName]()`

**Configuration:**
```dart
factory DartboardSectionConfig.[gameName]() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xXXXXXX),
    borderRadius: BorderRadius.circular([value]),
    disabledOverlayBackgroundColor: const Color(0xXXXXXX).withOpacity([value]),
    disabledOverlayBorderColor: const Color(0xXXXXXX),
    removeButtonBackgroundColor: const Color(0xXXXXXX),
    removeButtonBorderColor: const Color(0xXXXXXX),
    removeButtonTextStyle: GoogleFonts.[fontName](
      fontSize: [size],
      fontWeight: FontWeight.[weight],
      color: [color],
    ),
  );
}
```

**Usage:**
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: [condition],
  dartboardKey: _dartboardKey,
  onDartThrow: [handler],
  onRemoveDarts: [handler],
  config: DartboardSectionConfig.[gameName](),
)
```

### DartboardFABConfig
**Factory Method:** `DartboardFABConfig.[gameName]()`

**Configuration:**
```dart
factory DartboardFABConfig.[gameName]() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xXXXXXX),
    iconColor: [color],
    textColor: [color],
    textStyle: GoogleFonts.[fontName](fontWeight: FontWeight.[weight]),
  );
}
```

**Usage:**
```dart
DartboardEmulatorFAB(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  config: DartboardFABConfig.[gameName](),
)
```

## Dialog Components

### Add Player Dialog
**Factory Method:** `AddPlayerDialogConfig.[gameName]()`

**Configuration:**
```dart
factory AddPlayerDialogConfig.[gameName]() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xXXXXXX).withOpacity([value]),
    textColor: [color],
    titleStyle: GoogleFonts.[fontName](
      fontSize: [size],
      fontWeight: FontWeight.[weight],
      color: [color],
    ),
    inputLabelStyle: GoogleFonts.[fontName](...),
    inputBorderColor: const Color(0xXXXXXX),
    inputFocusedBorderColor: const Color(0xXXXXXX),
    inputErrorBorderColor: [color],
    photoLabelStyle: GoogleFonts.[fontName](...),
    photoButtonColor: const Color(0xXXXXXX),
    photoButtonForegroundColor: [color],
    photoButtonBorderColor: const Color(0xXXXXXX),
    photoButtonTextStyle: GoogleFonts.[fontName](...),
    photoButtonWidth: [value or null],
    addButtonColor: const Color(0xXXXXXX),
    addButtonForegroundColor: [color],
    addButtonBorderColor: const Color(0xXXXXXX),
    addButtonTextStyle: GoogleFonts.[fontName](...),
    cancelButtonColor: const Color(0xXXXXXX),
    cancelButtonForegroundColor: [color],
    cancelButtonBorderColor: const Color(0xXXXXXX),
    cancelButtonTextStyle: GoogleFonts.[fontName](...),
    errorTextColor: [color],
  );
}
```

**Usage:**
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.[gameName](),
);
```

### Edit Score Dialog
**Factory Method:** `EditScoreDialogConfig.[gameName]()`

**Configuration:**
```dart
factory EditScoreDialogConfig.[gameName]() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xXXXXXX).withOpacity([value]),
    borderColor: const Color(0xXXXXXX),
    borderWidth: [value],
    titleStyle: GoogleFonts.[fontName](...),
    dartLabelStyle: GoogleFonts.[fontName](...),
    scoreBoxBackgroundColor: const Color(0xXXXXXX),
    scoreBoxDefaultBorderColor: [color],
    scoreTextStyle: GoogleFonts.[fontName](...),
    buttonUnselectedColor: const Color(0xXXXXXX),
    buttonUnselectedForeground: [color],
    buttonSelectedColor: const Color(0xXXXXXX),
    buttonSelectedForeground: [color],
    buttonTextStyle: GoogleFonts.[fontName](...),
    cancelButtonColor: [color],
    cancelButtonForeground: [color],
    cancelButtonTextStyle: GoogleFonts.[fontName](...),
    submitButtonColor: const Color(0xXXXXXX),
    submitButtonForeground: [color],
    submitButtonTextStyle: GoogleFonts.[fontName](...),
    // Optional: transform displayed score
    // scoreDisplayTransform: (segment) => [transformation],
  );
}
```

**Usage:**
```dart
showEditScoreDialog(
  context: context,
  playerName: [playerName],
  initialSegments: [segments],
  onSubmit: (newSegments) => [handler],
  config: EditScoreDialogConfig.[gameName](),
  // dartBorderColors: [optional list of colors],
);
```

## Play to Complete

### PlayToCompleteStrategy
**File:** `lib/services/play_to_complete/[game_name]_strategy.dart`

**Implementation:**
```dart
class [GameName]Strategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    return context.read<[GameName]Provider>().hasWinner;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<[GameName]Provider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    // Read current game state and settings from provider
    // Return optimal throw based on game rules and current state
    // Return null if game is done
  }
}
```

### PlayToCompleteButtonConfig
**Factory Method:** `PlayToCompleteButtonConfig.[gameName]()`

**Configuration:**
```dart
factory PlayToCompleteButtonConfig.[gameName]() {
  return PlayToCompleteButtonConfig(
    backgroundColor: const Color(0xXXXXXX),
    foregroundColor: [color],
    borderColor: const Color(0xXXXXXX),
    textStyle: GoogleFonts.[fontName](...),
  );
}
```

## Custom Components

### [Custom Component 1 Name]
**Description:** [What this component does]

**Usage:**
```dart
[Example code]
```

### [Custom Component 2 Name]
**Description:** [What this component does]

**Usage:**
```dart
[Example code]
```
