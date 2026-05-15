# Tiki Golf - Component Configurations

## Shared Global Components

### ResumeGameButton
**Description:** Icon button in the menu screen AppBar for accessing saved Tiki Golf games.

**File:** `lib/widgets/resume_game_button.dart`

**Documentation:** See [Save & Resume Game](../../development/save-resume-game.md#resume-game-button-menu-screen)

**Usage:**
```dart
ResumeGameButton(
  hasSavedGames: _hasSavedGames,
  onPressed: () => setState(() => _showResumeModal = true),
  color: const Color(0xFF00B4D8), // Lagoon Blue
)
```

The `ResumeGameButton` lives in the AppBar's `actions` list, immediately to the left of `DartboardConnectionInfo` — Target Tag's pattern. It renders only when saved Tiki Golf games exist; otherwise the slot is empty.

### TeamPlayerListPanel
**Description:** The unified player selection panel used in BOTH Solo and Team modes (Target Tag pattern). In Solo mode, the team UI sub-elements (team-assignment boxes, per-player team-assign trailing icons) are hidden; in Team + Manual mode, they appear.

**File:** `lib/widgets/player_list_panel/team_player_list_panel.dart`

**Usage:** The menu screen passes `isTeamMode` and `isManualTeamAssignment` flags to gate team UI:
- **Solo** (`isTeamMode: false`) — Player selection list only. Max 4 players. Header: `(N/4 selected)`.
- **Team + Random** (`isTeamMode: true, isManualTeamAssignment: false`) — Player selection list only (panel looks like Solo). No team boxes, no trailing icons, no Team Count dropdown.
- **Team + Manual** (`isTeamMode: true, isManualTeamAssignment: true`) — Player selection list + team-assignment boxes (row of team-crest tiles) + per-player team-assign trailing icons. Max 16 players. Header: `(N/16 selected)`.

**Key note on max-players:** Solo mode caps at 4; Team mode caps at 16. The `TeamPlayerListPanel` widget uses a `maxPlayersSoloMode: 4` field (added during Tiki Golf's Phase 4) alongside the existing `maxPlayers: 16` so the header count and `selectPlayer(maxPlayers:)` call use the mode-appropriate cap.

## Dartboard Emulator Components

### DartboardSectionConfig
**Factory Method:** `DartboardSectionConfig.tikiGolf()`

**Configuration:**
```dart
factory DartboardSectionConfig.tikiGolf() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xFF2D6A4F), // Palm Green
    borderRadius: BorderRadius.circular(12),
    disabledOverlayBackgroundColor: const Color(0xFF2D6A4F).withOpacity(0.70),
    disabledOverlayBorderColor: const Color(0xFF8B5E3C), // Tiki Brown
    removeButtonBackgroundColor: const Color(0xFF00B4D8), // Lagoon Blue
    removeButtonBorderColor: const Color(0xFF8B5E3C), // Tiki Brown
    removeButtonTextStyle: GoogleFonts.boogaloo(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFF5E1), // Sand White
    ),
  );
}
```

**Usage:**
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: provider.currentTurnEnded || provider.hasWinner,
  dartboardKey: _dartboardKey,
  onDartThrow: _handleDartThrow,
  onRemoveDarts: _handleRemoveDarts,
  config: DartboardSectionConfig.tikiGolf(),
)
```

**Critical:** `shouldPromptTakeout` is `currentTurnEnded || hasWinner` — NOT `dartsThrown >= 3 || hasWinner`. Tiki Golf has variable darts per turn; takeout only fires on actual turn-end, not after a fixed number of darts.

### DartboardFABConfig
**Factory Method:** `DartboardFABConfig.tikiGolf()`

**Configuration:**
```dart
factory DartboardFABConfig.tikiGolf() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xFF00B4D8), // Lagoon Blue
    iconColor: const Color(0xFFFFF5E1), // Sand White
    textColor: const Color(0xFFFFF5E1), // Sand White
    textStyle: GoogleFonts.boogaloo(fontWeight: FontWeight.bold),
  );
}
```

**Usage:** Mount as an outer-Stack child via `Positioned(right: 16, bottom: 16, child: ...)`, NOT in `Scaffold.floatingActionButton`. See [Outer-Stack Modal Architecture](../../development/game-integration.md#outer-stack-modal-architecture) for the full layer order.

## Dialog Components

### Add Player Dialog
**Factory Method:** `AddPlayerDialogConfig.tikiGolf()`

**Configuration:**
```dart
factory AddPlayerDialogConfig.tikiGolf() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.95), // Palm Green
    textColor: const Color(0xFFFFF5E1), // Sand White
    titleStyle: GoogleFonts.boogaloo(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFF5E1),
    ),
    inputLabelStyle: GoogleFonts.nunito(
      fontSize: 14,
      color: const Color(0xFFFFF5E1),
    ),
    inputBorderColor: const Color(0xFF8B5E3C), // Tiki Brown
    inputFocusedBorderColor: const Color(0xFF00B4D8), // Lagoon Blue
    inputErrorBorderColor: const Color(0xFFFF8C42), // Tropical Orange
    photoLabelStyle: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFFFFF5E1)),
    photoButtonColor: const Color(0xFF00B4D8),
    photoButtonForegroundColor: const Color(0xFFFFF5E1),
    photoButtonBorderColor: const Color(0xFF8B5E3C),
    photoButtonTextStyle: GoogleFonts.boogaloo(fontSize: 16),
    photoButtonWidth: null,
    addButtonColor: const Color(0xFF00B4D8), // Lagoon Blue
    addButtonForegroundColor: const Color(0xFFFFF5E1),
    addButtonBorderColor: const Color(0xFF8B5E3C),
    addButtonTextStyle: GoogleFonts.boogaloo(fontSize: 18),
    cancelButtonColor: const Color(0xFF8B5E3C), // Tiki Brown
    cancelButtonForegroundColor: const Color(0xFFFFF5E1),
    cancelButtonBorderColor: const Color(0xFF8B5E3C),
    cancelButtonTextStyle: GoogleFonts.boogaloo(fontSize: 18),
    errorTextColor: const Color(0xFFFF8C42), // Tropical Orange
  );
}
```

**Usage:**
```dart
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.tikiGolf(),
);
```

### Edit Score Dialog
**Factory Method:** `EditScoreDialogConfig.tikiGolf()`

**Tiki Golf specifics:** The Edit Score dialog renders **Max Darts dropdowns** (not always 3). The `maxDarts` value from the game settings determines how many dart slots appear. Each slot shows a dropdown for 1-20 (target numbers), "Miss", or "—". The score displayed per dart represents whether the target was hit on that dart, not a raw segment value.

**Configuration:**
```dart
factory EditScoreDialogConfig.tikiGolf() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.95),
    borderColor: const Color(0xFF8B5E3C), // Tiki Brown
    borderWidth: 2,
    titleStyle: GoogleFonts.boogaloo(
      fontSize: 22,
      color: const Color(0xFFFFF5E1),
    ),
    dartLabelStyle: GoogleFonts.boogaloo(fontSize: 16, color: const Color(0xFFFFF5E1)),
    scoreBoxBackgroundColor: const Color(0xFF2D6A4F),
    scoreBoxDefaultBorderColor: const Color(0xFF8B5E3C),
    scoreTextStyle: GoogleFonts.boogaloo(fontSize: 20, color: const Color(0xFFFFF5E1)),
    buttonUnselectedColor: const Color(0xFF2D6A4F),
    buttonUnselectedForeground: const Color(0xFFFFF5E1),
    buttonSelectedColor: const Color(0xFF00B4D8), // Lagoon Blue
    buttonSelectedForeground: const Color(0xFFFFF5E1),
    buttonTextStyle: GoogleFonts.boogaloo(fontSize: 16),
    cancelButtonColor: const Color(0xFF8B5E3C),
    cancelButtonForeground: const Color(0xFFFFF5E1),
    cancelButtonTextStyle: GoogleFonts.boogaloo(fontSize: 16),
    submitButtonColor: const Color(0xFF00B4D8),
    submitButtonForeground: const Color(0xFFFFF5E1),
    submitButtonTextStyle: GoogleFonts.boogaloo(fontSize: 18),
  );
}
```

**Usage:**
```dart
showEditScoreDialog(
  context: context,
  playerName: playerName,
  initialSegments: segments,
  onSubmit: (newSegments) => provider.updateAllDartScores(playerId, newSegments),
  config: EditScoreDialogConfig.tikiGolf(),
);
```

### Dartboard Paused Modal
**Factory Method:** `DartboardPausedModalConfig.tikiGolf()`

**Usage:** Standard integration — see [Dartboard Paused Modal](../../development/dartboard-paused-modal.md). Colors use Palm Green background, Tiki Brown border, Lagoon Blue resume button.

### Save Game Modal / Resume Game Modal
Standard integration using Palm Green / Tiki Brown / Lagoon Blue color scheme. See [Save & Resume Game](../../development/save-resume-game.md).

## Play to Complete

### PlayToCompleteStrategy
**File:** `lib/services/play_to_complete/tiki_golf_strategy.dart`

**Implementation:**
```dart
class TikiGolfStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    return context.read<TikiGolfProvider>().hasWinner;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    final provider = context.read<TikiGolfProvider>();
    return provider.currentTurnEnded || provider.hasWinner;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    final provider = context.read<TikiGolfProvider>();
    if (provider.hasWinner) return null;

    final game = provider.game;
    if (game == null) return null;

    // Always throw at the current hole's target number
    final targetNumber = game.holeTargets[game.currentHole - 1];
    return SimulatedThrow(number: targetNumber, ring: Ring.single);
  }
}
```

**Note:** The strategy always throws at the current hole's random target number (from `holeTargets`). When the target is hit on the first dart, `currentTurnEnded` becomes true and `shouldAutoTakeout` fires immediately.

### PlayToCompleteButtonConfig
**Factory Method:** `PlayToCompleteButtonConfig.tikiGolf()`

**Configuration:**
```dart
factory PlayToCompleteButtonConfig.tikiGolf() {
  return PlayToCompleteButtonConfig(
    backgroundColor: const Color(0xFF00B4D8), // Lagoon Blue
    foregroundColor: const Color(0xFFFFF5E1), // Sand White
    borderColor: const Color(0xFF8B5E3C), // Tiki Brown
    textStyle: GoogleFonts.boogaloo(fontWeight: FontWeight.bold),
  );
}
```

## Custom Components

### Mulligan Modal Variant (Splash + Mulligan Available)

When a player Splashes AND Mulligan is ON AND the player has their mulligan available, the standard `RemoveDartsModal` is replaced with a custom variant that renders two action buttons instead of the default "DARTS REMOVED" button.

**This is Tiki Golf's most significant UI deviation from the canonical pattern.**

**Variant layout:**
```
+----------------------------------------+
| Darts landed in: [hole theme image]   |
| [Hole target illustration]             |
|                                        |
|  That was a Splash!                    |
|  You have 1 mulligan remaining.        |
|  Use it for a do-over?                 |
|                                        |
|  [  USE MULLIGAN  ]  [ NEXT PLAYER ]  |
|  (Lagoon Blue)         (Hibiscus Pink) |
+----------------------------------------+
```

**Button actions:**
- **USE MULLIGAN** → calls `provider.useMulligan(playerId)` → player re-throws Max Darts
- **NEXT PLAYER** → calls `provider.confirmTurnEnd(playerId)` → Splash is final, advance turn

**Conditions for this variant:**
```dart
final showMulliganVariant = provider.currentTurnEnded &&
    provider.lastTurnWasSplash &&
    game.mulliganEnabled &&
    provider.playerMulliganAvailable[currentPlayerId] == true;
```

**Standard one-button takeout applies** when:
- Mulligan is OFF
- Player already used their mulligan (`playerMulliganAvailable[playerId] == false`)
- Turn ended by target hit (not a Splash)

### Dart Row with Variable Slots

The active player panel's dart indicator row renders **Max Darts slots** dynamically (3, 4, 5, or 6). Each slot shows:
- Empty: neutral (not yet thrown)
- Hit: Lagoon Blue with checkmark icon
- Miss: Tropical Orange with X icon

The slot width and height compress slightly at 5-6 darts to keep the row within the panel width.

```dart
Row(
  children: List.generate(game.maxDarts, (i) => DartSlotWidget(
    state: _getDartSlotState(i, dartsThrown, hitOnDart),
    isActive: i < dartsThrown,
  )),
)
```

### Hole Theme Display

The game screen shows the randomly-assigned hole theme image for the current hole in a prominent position. The image is loaded from `game.holeImagePaths[game.currentHole - 1]`.

```dart
Image.asset(
  game.holeImagePaths[game.currentHole - 1],
  width: 120,
  height: 120,
  fit: BoxFit.contain,
)
```

The hole name displayed ("Volcano", "Waterfall", etc.) is derived from the image path, not a fixed hole-name list.
