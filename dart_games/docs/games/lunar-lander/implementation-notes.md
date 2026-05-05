# Lunar Lander - Implementation Notes

## Code Architecture

### Provider Pattern
**File:** `lib/providers/lunar_lander_provider.dart`

**State managed:**
- `LunarLanderGame currentGame` — the full game model (configuration + runtime state)
- `bool hasWinner` — derived from `currentGame.winnerId != null`
- `bool shouldPromptTakeout` — true when 3 darts thrown and hardware dartboard not connected
- `String? resumedSavedGameId` — tracks which saved game was resumed (cleared on game completion)

**Key Methods:**
- `startGame(List<Player> players, int startingAltitude, bool hardLandingEnabled)` — initializes game with shuffled character assignments
- `processDartThrow(DartSegment segment)` — subtracts dart score from current player's altitude, enforces Hard Landing bust rule, detects win, increments dart counter
- `advanceToNextPlayer()` — called after Remove Darts; cycles to next player, resets dart counter
- `skipTurn()` — forfeits remaining darts, triggers takeout if needed, advances to next player
- `editScore(List<DartSegment> newSegments)` — replays all 3 darts from `turnStartAltitude`, re-evaluates bust/win
- `saveGame()` / `restoreGame(SavedGame)` — save/restore full game state via `SaveGameService`

### Models
**File:** `lib/models/lunar_lander_game.dart`

**Key fields:**
- `int startingAltitude` — configured starting altitude (100-500)
- `bool hardLandingEnabled` — Hard Landing option toggle
- `Map<String, int> playerAltitudes` — current altitude per player ID
- `Map<String, int> turnStartAltitudes` — altitude snapshot at start of current turn (for bust reversion)
- `int currentPlayerIndex` — index into ordered player ID list
- `int totalTurns` — total turns taken across all players (incremented once per turn)
- `List<DartSegment> currentTurnDarts` — up to 3 dart segments for this turn
- `String? winnerId` — set when a player achieves touchdown
- `Map<String, LunarLanderCharacter> characterAssignments` — per-player character assignment

**Factory:**
- `LunarLanderGame.create(players, startingAltitude, hardLandingEnabled)` — creates a new game with shuffled character assignments (see below)

### Screen Architecture

#### Menu Screen
**File:** `lib/screens/games/lunar_lander/lunar_lander_menu_screen.dart`

- Left panel: scrollable game description (How to Play, Beginner Tips)
- Right panel: settings row (altitude slider + hard landing toggle), DualPlayerListPanel, LAUNCH! button
- `initState` reads `provider.currentGame.startingAltitude` and `.hardLandingEnabled` to restore settings on CHANGE MISSION re-entry
- Auto-shows ResumeGameModal when `_hasSavedGames == true` on initial entry only

#### Game Screen
**File:** `lib/screens/games/lunar_lander/lunar_lander_game_screen.dart`

- Stack-based layout: background + game content + overlay modals (RemoveDartsModal, DartboardPausedModal)
- DartboardEmulatorSection rendered as a `Positioned` widget AFTER RemoveDartsModal in the Stack (see Stacking Modal Pattern below)
- Auto-navigates to results on win via `addPostFrameCallback` in `build`

#### Results Screen
**File:** `lib/screens/games/lunar_lander/lunar_lander_results_screen.dart`

- Rankings sorted by altitude ascending (0 first, highest altitude last)
- `_deleteResumedSavedGame()` runs independently via `addPostFrameCallback` (not awaited inline)

## Non-Obvious Implementation Details

### Random Character Assignment (Reef Royale Pattern)

Characters are assigned at game start using the shuffle pattern from Reef Royale. In `LunarLanderGame.create`:

```dart
final shuffled = List<LunarLanderCharacter>.from(LunarLanderCharacter.values)
  ..shuffle(Random());
final characterAssignments = <String, LunarLanderCharacter>{};
for (int i = 0; i < players.length; i++) {
  characterAssignments[players[i].id] = shuffled[i];
}
```

This ensures each player gets a unique character, assigned randomly each new game. The assignment is stored in the game model and persisted via save/restore.

### Stacking Modal Pattern

The DartboardEmulatorSection must remain interactive even when the RemoveDartsModal is visible. This is achieved by rendering the emulator AFTER the modal in the Stack's children list — later children render on top, so the emulator's "DARTS REMOVED" button stays tappable above the modal overlay.

```dart
Stack(
  children: [
    // ... background and game content ...
    if (_showRemoveDartsModal)
      RemoveDartsModal(config: RemoveDartsModalConfig.lunarLander(), ...),
    // Emulator rendered AFTER modal — its button stays tappable on top
    if (!dartboardProvider.isConnected)
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: DartboardEmulatorSection(
          config: DartboardSectionConfig.lunarLander(),
          ...
        ),
      ),
  ],
)
```

This matches the Clockwork Quest pattern. See `lib/screens/games/clockwork_quest/clockwork_quest_game_screen.dart` for the reference implementation.

### Auto-Show Resume Modal

`initState` sets `_showResumeModal = true` only on initial menu entry (when saved games exist). On subsequent re-checks (e.g., after CHANGE MISSION returns to menu), `initState` only updates `_hasSavedGames` without re-triggering the modal. This matches the Clockwork Quest pattern:

```dart
@override
void initState() {
  super.initState();
  _isFirstLoad = true;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final savedGames = await provider.getSavedGames();
    setState(() {
      _hasSavedGames = savedGames.isNotEmpty;
      if (_isFirstLoad && _hasSavedGames) {
        _showResumeModal = true;
      }
      _isFirstLoad = false;
    });
  });
}
```

### Auto-Navigate on Win

The game screen's `build` method schedules `_handleGameWon()` via `addPostFrameCallback` when `provider.hasWinner` becomes true. This avoids calling `Navigator.push` during a build:

```dart
@override
Widget build(BuildContext context) {
  final provider = context.watch<LunarLanderProvider>();
  if (provider.hasWinner && !_navigatingToResults) {
    _navigatingToResults = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleGameWon());
  }
  // ... rest of build ...
}
```

This matches the Clockwork Quest pattern.

### Restore Last-Game Settings on Menu Re-Entry

When the player taps CHANGE MISSION (results → menu), `initState` reads `provider.currentGame.startingAltitude` and `.hardLandingEnabled` (when set) and pre-populates the menu sliders/toggles:

```dart
@override
void initState() {
  super.initState();
  final currentGame = context.read<LunarLanderProvider>().currentGame;
  if (currentGame != null) {
    _startingAltitude = currentGame.startingAltitude;
    _hardLandingEnabled = currentGame.hardLandingEnabled;
  } else {
    _startingAltitude = 200; // default
    _hardLandingEnabled = false; // default
  }
}
```

### totalTurns Increment Pattern

`totalTurns` is incremented ONLY in `processDartThrow` on the FIRST dart of the turn (when `currentTurnDarts.isEmpty` before the dart is added) — NOT in `advanceToNextPlayer`. This matches the Target Tag pattern. Rationale: a "turn" is defined as the first dart thrown, not the turn advance action, which prevents edge cases where skipped turns or timed-out turns could have ambiguous turn counts.

### announceRemoveDarts UNCONDITIONAL

`announceRemoveDarts()` is called OUTSIDE the precedence-selection if/else chain in `_processDartThrow`. It appears at two locations in the game screen:

1. After the 3rd dart is processed (around game screen line ~200)
2. After a bust is processed with Hard Landing ON (around line ~642)

This ensures "Remove your darts" always plays regardless of which moment announcement (Touchdown, Crash Landing, etc.) won the precedence contest.

### _deleteResumedSavedGame Runs Independently

On the results screen, the saved game deletion runs independently in `addPostFrameCallback`, not awaited inline after `_updatePlayerStats`. This prevents a race condition where a slow save-game delete could block the stats update or cause a "context mounted" warning:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _updatePlayerStats();   // stats update
    _playVictoryMusic();          // music trigger
  });
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _deleteResumedSavedGame(); // independent delete
  });
}
```

### Edit Score Miss Handling

The `EditScoreDialogConfig.lunarLander()` uses a `scoreDisplayTransform` that maps `segment.score == 0` to the string `'Miss'` (not `'-'`). This is important because the dialog's Save button enable/disable logic checks whether any dart has a non-empty display — mapping to `'Miss'` ensures the Save button stays enabled when misses are present in the current turn.

### Spec Drift: Dropped Options

The Lunar Lander spec (Section 7) defines exactly 2 options: Starting Altitude and Hard Landing. However, spec Sections 12A, 12B, and 14 contain references to "Double Out" and "Speed Play" as options — these appear to be copy-paste residue from other games' spec sections and were treated as spec drift. Only the 2 options in Section 7 were implemented. The test files confirm: no "Double Out" or "Speed Play" logic exists in the game.

### Save/Restore Migration: None Required

Lunar Lander does not add any new server-side database tables or schema changes. The save/restore mechanism stores the game state as a JSON blob in the existing `saved_games` table. New optional fields are added to the JSON schema only — deserialization uses safe defaults for missing fields, maintaining backward compatibility without any data migration.

## Integration Points

### Global User Management
- Results screen `initState` calls `provider.updatePlayerStats(winner, losers, duration)` via `addPostFrameCallback`
- `gameHistory` entry uses `gameName: 'Lunar Lander'`

### Announcement System
- `LunarLanderAnnouncementHelper` wraps `GameAnnouncementQueueService`
- Game screen initializes helper in `initState` via `addPostFrameCallback` (allows async settings load)

### Victory Music
- Results screen `initState` calls `_playVictoryMusic()` which initializes `VictoryMusicService` if needed

### Dartboard Emulator
- Rendered at BOTTOM of game screen (full-width Positioned)
- `DartboardSectionConfig.lunarLander()` and `DartboardFABConfig.lunarLander()` provide theming
- `shouldPromptTakeout` controls the disabled overlay (blue overlay + "Remove your darts" prompt)

### Save & Resume
- `SaveGameService` stores full `LunarLanderGame` JSON
- `LunarLanderProvider.saveGame()` serializes via `currentGame.toJson()`
- `LunarLanderProvider.restoreGame(savedGame)` deserializes via `LunarLanderGame.fromJson(savedGame.gameState)`
- `resumedSavedGameId` tracks the active resume; results screen deletes it on game completion

## Known Issues and Limitations

None beyond the chromedriver teardown flake documented in [testing.md](testing.md#known-issues).

## Reference Implementations

### Similar Patterns in Other Games
- **Random character assignment:** `lib/providers/reef_royale_provider.dart` — `ReefRoyaleGame.create()` shuffle pattern
- **Stacking modal + emulator positioning:** `lib/screens/games/clockwork_quest/clockwork_quest_game_screen.dart`
- **Auto-show resume modal / auto-navigate on win:** `lib/screens/games/clockwork_quest/clockwork_quest_menu_screen.dart` and `clockwork_quest_game_screen.dart`
- **totalTurns on first dart:** `lib/providers/target_tag_provider.dart` — `processDartThrow`
