# Pirate's Grid - Implementation Notes

## Code Architecture

### Provider Pattern
**File:** `lib/providers/pirates_grid_provider.dart`

**State Management:**
```dart
class PiratesGridProvider extends ChangeNotifier {
  PiratesGridGame? _currentGame;

  PiratesGridGame? get currentGame => _currentGame;
  bool get isGameActive => _currentGame != null && !_currentGame!.isMatchOver;
  bool get hasWinner => _currentGame?.isMatchOver ?? false;
  bool get shouldPromptTakeout => _currentGame?.shouldPromptTakeout ?? false;
  String? get resumedSavedGameId => _resumedSavedGameId;
}
```

**Key Methods:**
- `startGame(playerIds, difficulty, bestOf, stealMode, speedPlay)` — Initializes `PiratesGridGame` with a freshly generated grid
- `processDartThrow(number, multiplier)` — Finds the matching cell, applies logic (plant/steal/miss/no-op), checks win/draw, returns `DartOutcome`
- `skipTurn()` — Marks remaining darts as skipped, advances to next player
- `handleTakeoutFinished()` — Called after RemoveDartsModal is dismissed; advances player if in Best Of mode and no match winner yet
- `saveGame(context)` — Serializes full game state via `SaveGameService`
- `resumeGame(savedGameId, context)` — Restores full game state from server

### Models
**File:** `lib/models/pirates_grid_game.dart`

**Core Data Structure:**
```dart
class PiratesGridGame {
  final String id;
  final DateTime startedAt;
  final List<String> playerIds;
  final TargetDifficulty difficulty;
  final int bestOf;             // 1, 3, or 5
  final bool stealModeEnabled;
  final bool speedPlayEnabled;

  // Grid state
  final List<List<GridCell>> grid;   // 3x3 matrix

  // Per-turn state
  final String activePlayerId;
  final List<DartThrow?> currentDarts;  // [dart0, dart1, dart2]
  final bool shouldPromptTakeout;

  // Per-round state
  final int currentRound;
  final int currentRoundStartingPlayerIndex;

  // Match state
  final Map<String, int> roundsWon;    // playerIds -> round wins
  final String? roundWinnerId;          // current round winner (null if ongoing/draw)
  final bool isRoundDraw;
  final List<GridPosition>? winningLine; // null if no winner yet

  // Match completion
  final String? matchWinnerId;
  final bool isMatchDraw;
}
```

**GridCell:**
```dart
class GridCell {
  final CellTarget target;    // the dart requirement for this cell
  final String? ownerId;      // null = empty, playerId = claimed
}
```

**CellTarget:**
```dart
class CellTarget {
  final int number;                     // 10-20, or 0 for Bull center
  final CellRequirement requirement;    // anyMultiplier / doubleOnly / tripleOnly / bull

  bool matches(int dartNumber, int dartMultiplier) { ... }
}
```

### Screen Architecture

#### Menu Screen
**File:** `lib/screens/games/pirates_grid/pirates_grid_menu_screen.dart`

- 2-column layout: left panel (how-to-play, scrollable) + right panel (settings + player list + start button)
- Settings: 2 rows of 2 option boxes (difficulty dropdown, best-of dropdown, steal mode toggle, speed play toggle)
- `DualPlayerListPanel` with max 2 players; start button disabled until exactly 2 players are selected
- `ResumeGameButton` in AppBar triggers `ResumeGameModal` when saved games exist

#### Game Screen
**File:** `lib/screens/games/pirates_grid/pirates_grid_game_screen.dart`

- Left panel (200px fixed): active player info, dart indicators, timer (conditional), skip turn button
- Center area: 3x3 grid of `GridCellWidget` + optional round tracker above + optional steal mode badge below
- Bottom area: `DartboardEmulatorSection` (when not connected to hardware)
- Outer-Stack modal pattern: game screen + save modal + remove darts modal + edit score dialog + dartboard paused modal + FAB (6 layers)
- Speed Play timer lives in screen state (`Timer.periodic`), NOT the provider — the provider only stores whether speed play is enabled

#### Results Screen
**File:** `lib/screens/games/pirates_grid/pirates_grid_results_screen.dart`

- Centered winner display card with title, avatar, name, and stats
- Rankings list (2 players — winner + loser / draw state for both)
- Three action buttons: Set Sail Again, New Voyage, Port Home

## Complex Algorithms

### GridTargetGenerator
**File:** `lib/screens/games/pirates_grid/utils/grid_target_generator.dart`
**Purpose:** Generates the deterministic 3x3 target layout for a given difficulty

The layout is hardcoded (not random) and matches the spec exactly:
- Easy: numbers 20, 18, 16, 19, 17, 15, 14, 12, 10 in row-major order; all accept `anyMultiplier`
- Medium: same numbers; all require `doubleOnly` (double OR triple both satisfy a `doubleOnly` cell)
- Hard: corners (0,0), (0,2), (2,0), (2,2) = T20, T16, T14, T10 (tripleOnly); edges (0,1), (1,0), (1,2), (2,1) = D18, D19, D15, D12 (doubleOnly); center (1,1) = Bull (number=0, bull requirement)

The `GridTargetGenerator` returns `List<List<CellTarget>>` — a 3x3 matrix indexed as `[row][col]`.

### ThreeInARowChecker
**File:** `lib/screens/games/pirates_grid/utils/three_in_a_row_checker.dart`
**Purpose:** Checks all 8 winning lines in a 3x3 grid

Checks 8 lines in a fixed order:
1. Row 0: (0,0), (0,1), (0,2)
2. Row 1: (1,0), (1,1), (1,2)
3. Row 2: (2,0), (2,1), (2,2)
4. Col 0: (0,0), (1,0), (2,0)
5. Col 1: (0,1), (1,1), (2,1)
6. Col 2: (0,2), (1,2), (2,2)
7. Diagonal TL→BR: (0,0), (1,1), (2,2)
8. Diagonal TR→BL: (0,2), (1,1), (2,0)

Returns `List<GridPosition>?` — the 3 positions of the winning line, or null if no winner.

**Complexity:** O(1) — always checks exactly 8 × 3 = 24 cells, independent of game state.

### CellTarget.matches(number, multiplier)
**Purpose:** Determines whether a dart hit satisfies the cell's requirement

```dart
bool matches(int number, int multiplier) {
  switch (requirement) {
    case CellRequirement.anyMultiplier:
      return this.number == number;
    case CellRequirement.doubleOnly:
      return this.number == number && multiplier >= 2;
    case CellRequirement.tripleOnly:
      return this.number == number && multiplier == 3;
    case CellRequirement.bull:
      // number 25 (outer bull) or 50 (inner bull) both satisfy Bull center
      return number == 25 || number == 50;
  }
}
```

## Gotchas and Quirks

### Bull Cell on Hard Difficulty — Number is 0
**Issue:** The center cell on Hard difficulty is a "Bull" cell. Its `CellTarget.number` is stored as `0` (a special sentinel), NOT as 25 or 50.

**Why it happens:** 25 and 50 are valid dart scores (outer/inner bull), so using either one as the "cell number" would conflict. Using 0 indicates "this is a bull cell" and the `matches()` method handles 25 and 50 as both valid hits.

**How to handle:** In any code that reads `cellTarget.number` for display purposes, check `if (requirement == CellRequirement.bull)` and show "Bull" rather than the number.

**Code location:** `GridTargetGenerator.generate()`, `CellTarget.matches()`, `GridCellWidget` label rendering.

### Speed Play Timer Lives in Screen State, NOT Provider
**Issue:** The `Timer.periodic` that drives the Speed Play countdown is owned by the game screen's `State`, not by `PiratesGridProvider`.

**Why it happens:** Flutter timers are not serializable and would introduce complex lifecycle issues in the provider. The provider only stores `speedPlayEnabled`. The timer starts fresh each time a player's turn begins in the screen.

**How to handle:** When saving/restoring a game, the timer state is NOT persisted. A resumed game simply starts the timer fresh on the first turn. This means a player cannot save a game and resume it with a partially elapsed timer — the timer always resets to 15 seconds on resume.

**Code location:** `_PiratesGridGameScreenState._startSpeedPlayTimer()`, `_handleTurnChange()`.

### Save/Restore Must Serialize Round State
**Issue:** Unlike a single-round game, Pirate's Grid Best Of matches have multi-round state that must survive save/restore.

**Required serialization fields:**
- `currentRound` — which round the match is on
- `roundsWon` — Map of playerIds to wins
- `currentRoundStartingPlayerIndex` — which player goes first in the current round
- `isRoundDraw` — whether the current round ended in a draw
- `matchWinnerId` — who won the match (null if ongoing)
- `isMatchDraw` — whether the match ended in a draw
- `winningLine` — the 3 cells forming the winning line (nullable)

The grid itself (`List<List<GridCell>>`) is the main payload and must be serialized in full.

### Outer-Stack Modal Pattern (6 Layers)
The game screen uses the standard 6-layer outer-Stack pattern:

1. Background + game content (scaffold body)
2. SaveGameModal overlay (when triggered by back button)
3. RemoveDartsModal overlay (when turn ends and emulator is used)
4. EditScoreDialog overlay (triggered from RemoveDartsModal)
5. DartboardPausedModal overlay (when dartboard disconnects)
6. DartboardEmulatorFAB (Positioned, bottom-right)

All 6 layers are children of a single `Stack` widget wrapping the `Scaffold`. Never add layers inside the Scaffold body.

### Victory Flow — Wait for DARTS REMOVED Before Navigating
**Issue:** If a winning dart is thrown, the match may be over immediately. But the RemoveDartsModal MUST appear before navigating to the results screen, so the physical darts are removed from the board.

**How to handle:** In `processDartThrow`, set `shouldPromptTakeout = true` even on a match-winning throw. The results navigation happens only in `handleTakeoutFinished` (after the player dismisses the RemoveDartsModal), not in `processDartThrow`.

**Code location:** `PiratesGridProvider.processDartThrow()`, `PiratesGridProvider.handleTakeoutFinished()`, `_PiratesGridGameScreenState._handleRemoveDarts()`.

## Performance Considerations

### Grid Rebuild on Every Dart Throw
**Concern:** The 3x3 grid (9 cells) rebuilds on every `notifyListeners()` call from the provider.

**Mitigation:** Each `GridCellWidget` uses `const` constructors where possible. The grid itself is a fixed 3x3 layout — no complex scrolling or large lists. Performance is negligible.

### Timer.periodic Side Effects
**Concern:** The Speed Play timer fires every second and calls `setState()` in the screen. If the screen is disposed while the timer is running, this could cause an error.

**Mitigation:** Always cancel the timer in `dispose()`. Also cancel it in `_handleTurnChange()` when the turn transitions to the next player.

## Integration Points

### Global User Management
The results screen calls `PlayerProvider.updatePlayerStats()` in `initState` once:
- Winner: `gamesPlayed + 1`, `gamesWon + 1`, gameHistory entry with `gameName: "Pirate's Grid"`
- Loser: `gamesPlayed + 1`, `gamesWon` unchanged, gameHistory entry

For draws, both players get `gamesPlayed + 1` and `gamesWon` unchanged.

### Announcer System
`PiratesGridAnnouncementHelper` wraps `GameAnnouncementQueueService`. Each announcement method calls `service.enqueue(QueuedAnnouncement(...))`. The MAX 2 rule is enforced in `processDartThrow` by selecting the highest-priority event and always adding Remove Darts unconditionally.

### Victory Music
`VictoryMusicService().initialize()` is called in `PiratesGridResultsScreen.initState()` alongside `_updatePlayerStats()`. The `victory_music_initialized_test.dart` UI test verifies this call happens.

### Dartboard Emulator
Configuration via `DartboardSectionConfig.piratesGrid()` and `DartboardFABConfig.piratesGrid()`. The emulator section is only rendered when `!dartboardProvider.isConnected`. The FAB is only rendered when `!dartboardProvider.isConnected`.

## Data Persistence

### Game State
**Storage:** Server API via `SaveGameService` (JSON payload)

**Key serialized fields:** All fields in `PiratesGridGame` including grid (3x3 matrix with cell owners), round state, match state, settings flags, and player IDs.

### Player Stats
**Storage:** Server API via `PlayerProvider`

**Data Tracked:**
- Games played: incremented on results screen for both players
- Games won: incremented for the match winner only (draws: no increment)
- Game history: one entry per match with `gameName: "Pirate's Grid"`, timestamps, duration

## Known Issues and Limitations

### Speed Play Timer Not Serialized
**Description:** The countdown timer state (how many seconds remain in the current turn) is lost when saving and restoring a game.

**Impact:** A resumed game always starts the timer from 15 seconds. Very minor UX inconvenience.

**Future Fix:** Not planned — the timer duration is short enough that this is acceptable.

### No 3-Player Support
**Description:** Pirate's Grid is strictly a 2-player game. The `DualPlayerListPanel` enforces this at the UI level, and the game model only supports 2 player IDs.

**Impact:** By design — tic-tac-toe is inherently a 2-player game.

## Future Enhancements

### Planned Features
- [ ] 4x4 grid variant for experienced players ("Large Grid" option)
- [ ] Configurable Speed Play timer duration (10s / 15s / 20s)
- [ ] "Hard Target only" variant where ALL cells require exact segment matches

### Technical Debt
- [ ] `GridCellWidget` could use `RepaintBoundary` to limit repaints to changed cells only
- [ ] The Speed Play timer logic in the screen state could be extracted to a dedicated `SpeedPlayTimerController` class for easier testing

## Reference Implementations

### Similar Patterns in Other Games
- **Random character assignment:** Lunar Lander uses a similar "fixed character pool + assignment on game start" pattern — but Pirate's Grid uses fixed mascot-per-player (Crossbones=P1, Redbeard=P2) rather than random assignment
- **Dual-player panel with max players:** Lunar Lander is the only other 2-player-capable game using `DualPlayerListPanel` with a fixed max
- **Best Of rounds:** No other game has multi-round Best Of logic — this is unique to Pirate's Grid in the current codebase
- **Outer-Stack modal pattern:** All games use the same 6-layer Stack pattern. Reference `clockwork_quest_game_screen.dart` for the canonical implementation.
