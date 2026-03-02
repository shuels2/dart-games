# Carnival Derby - Implementation Notes

## Code Architecture

### Provider Pattern
**File:** `lib/providers/horse_race_provider.dart`

**State Management:**
- Manages current game state (`HorseRaceGame` model)
- Tracks waiting-for-takeout state (`_waitingForTakeout`)
- Provides getters for game status, current player, scores
- Notifies listeners on all state changes

**Key Methods:**
- `startGame(List<Player> players, int targetScore, {bool exactScoreMode = false})` - Initializes new game with players and settings
- `processDartThrow(int score, {String? dartDisplay})` - Records dart throw, checks for bust/win, manages takeout state
- `skipTurn()` - Fills remaining dart slots with visual markers, sets waiting for takeout
- `updateAllDartScores(String playerId, List<String> newDartSegments)` - Replays turn with edited scores
- `handleTakeoutFinished()` - Advances to next player after darts removed
- `advanceToNextPlayer()` - Manually advance turn (testing/manual mode)
- `getHorsePosition(String playerId)` - Calculates position as percentage (0.0 to 1.0)

**State Variables:**
- `_currentGame`: HorseRaceGame? - Current game instance or null
- `_waitingForTakeout`: bool - Whether game is waiting for darts to be removed

### Models
**File:** `lib/models/horse_race_game.dart`

**Data Structure:**
```dart
class HorseRaceGame {
  final String id;                // Unique game identifier
  final List<String> playerIds;   // Ordered list of player IDs
  final int targetScore;          // Score to reach/exceed
  final bool exactScoreMode;      // Perfect Finish mode flag
  final DateTime startedAt;       // Game start timestamp

  // Runtime state
  GameState state;                // setup, playing, finished
  int currentPlayerIndex;         // Index of current player
  Map<String, int> scores;        // Player scores
  Map<String, int> dartsThrown;   // Darts thrown this turn
  Map<String, int> totalDartsThrown;  // Total darts across all turns
  Map<String, int> totalTurns;    // Total turns taken
  Map<String, List<String>> currentTurnDartScores;  // Dart displays this turn
  String? winnerId;               // Winner ID when game ends
  bool currentPlayerBusted;       // Bust flag for exact mode

  // Turn start state (for edit score)
  Map<String, int> turnStartScores;
  String? turnStartWinnerId;
  GameState turnStartState;
  bool turnStartCurrentPlayerBusted;
}
```

**Key Responsibilities:**
- Store game configuration (target score, exact mode, players)
- Track player scores and turn state
- Detect win conditions (exact or greater-than-equal)
- Handle bust logic in exact score mode
- Support score editing via turn state reset

### Screen Architecture

#### Menu Screen
**File:** `lib/screens/games/carnival_horse_race/horse_race_menu_screen.dart`

**Purpose:** Configure game settings and select players

**Key Components:**
- Two-column layout (description left, settings right)
- Target score slider (20-250)
- Exact score mode toggle
- Player selection with drag-and-drop
- Add player button
- Start game button (disabled until at least 1 player selected)
- Carnival decorations (string lights, target logo)
- Wood plank background with spotlight

**State Management:**
- Uses `PlayerProvider` for player list management
- Local state for target score and exact mode settings
- SharedPreferences persistence for last-used settings

#### Game Screen
**File:** `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart`

**Purpose:** Active gameplay with dart throwing and score tracking

**Key Components:**
- Race track visualization with horse positions
- Player score panels (scrollable)
- Current player highlighting with glow
- Skip turn button
- Edit score button
- Dartboard emulator section (when not connected)
- Game timer tracking
- Victory detection and navigation to results

**State Management:**
- Uses `HorseRaceProvider` for game state
- Uses `DartboardProvider` for dartboard connection
- Uses `PlayerProvider` for player data
- Local state for dartboard emulator controller, scroll controller, game completion flag

#### Results Screen
**File:** `lib/screens/games/carnival_horse_race/horse_race_results_screen.dart`

**Purpose:** Display winner and game statistics

**Key Components:**
- Winner display with trophy icon and confetti
- Player photo and name
- Final score and turn statistics
- Play again button (restarts with same settings)
- Change settings button (returns to menu)
- Victory music playback

## Complex Algorithms

### Score Calculation from Sector
**Purpose:** Convert dartboard sector string to numeric score

**Implementation:**
```dart
int _calculateScore(String sector) {
  // Handle bullseye
  if (sector == 'Bull') return 50;
  if (sector == '25') return 25;
  if (sector == 'None' || sector == 'Miss') return 0;

  // Parse regular sectors (S20, D15, T19, s20)
  final match = RegExp(r'[A-Za-z](\d+)').firstMatch(sector);
  if (match == null) return 0;

  final baseNumber = int.parse(match.group(1)!);
  int multiplier = 1;

  if (sector.startsWith('D') || sector.startsWith('d')) {
    multiplier = 2;  // Double
  } else if (sector.startsWith('T') || sector.startsWith('t')) {
    multiplier = 3;  // Triple
  }
  // S/s = single (multiplier 1)

  return baseNumber * multiplier;
}
```

**Complexity:** O(1) - constant time regex match and arithmetic

**Edge Cases:**
- Bullseye and 25 handled explicitly
- Miss/None returns 0
- Invalid sectors return 0
- Inner single (s20) vs outer single (S20) both score same but stored differently

### Horse Position Calculation
**Purpose:** Calculate horse position as percentage of track (0.0 to 1.0)

**Implementation:**
```dart
double getHorsePosition(String playerId) {
  final score = getPlayerScore(playerId);
  final targetScore = _currentGame!.targetScore;

  if (targetScore == 0) return 0.0;

  final position = score / targetScore;
  return position.clamp(0.0, 1.0);
}
```

**Complexity:** O(1) - simple division and clamp

**Edge Cases:**
- Target score of 0 returns 0.0 (prevents division by zero)
- Scores above target clamped to 1.0 (100%)
- Scores below 0 clamped to 0.0 (start)

### Auto-Scroll to Current Player
**Purpose:** Keep current player visible in scrollable race lane list

**Implementation:**
```dart
void _scrollToCurrentPlayer() {
  if (!_scrollController.hasClients) return;

  final currentPlayerIndex = _currentGame.currentPlayerIndex;
  const estimatedTileHeight = 80.0;

  if (currentPlayerIndex == 0) {
    // First player - scroll to top
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  } else {
    // Position current player near top with one tile above for context
    final scrollOffset = (currentPlayerIndex - 1) * estimatedTileHeight;

    _scrollController.animateTo(
      scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
```

**Complexity:** O(1) - arithmetic and animation

**Edge Cases:**
- First player always scrolls to top
- Other players show one tile above for context
- Clamps to max scroll extent to prevent over-scroll
- Checks for scroll controller attachment before animating

## Gotchas and Quirks

### Bust Announcement Timing
**Issue:** In Perfect Finish mode, when a player busts, announcements must be sequenced correctly

**Why it happens:** Multiple announcements (dart score, bust, remove darts) need to play in order without overlap

**How to handle:** Use cascading `Future.delayed` calls with appropriate durations:
1. Announce dart score (~1.5s delay)
2. Announce bust (~3s delay)
3. Announce remove darts (~2s delay)
4. Simulate takeout (~500ms delay)

**Code location:** `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart` lines 164-199

### Edit Score Turn State Reset
**Issue:** Editing scores requires resetting to turn start state, then replaying all 3 darts

**Why it happens:** Ensures game state consistency and recalculates win/bust conditions correctly

**How to handle:**
1. Save turn start state when turn begins (`_saveTurnStartState()`)
2. On edit, call `resetToStartOfTurn(playerId)` to restore state
3. Replay all 3 darts with new values via `recordDartThrow()`
4. Recalculate waiting-for-takeout based on final state

**Code location:** `lib/providers/horse_race_provider.dart` lines 123-164

### Inner vs Outer Single Distinction
**Issue:** Carnival Derby distinguishes between inner single (s20) and outer single (S20) even though they score the same

**Why it happens:** Provides richer data for potential future features and maintains dartboard accuracy

**How to handle:** Store full sector string (S20 vs s20) in `currentTurnDartScores`, but both calculate to same score

**Code location:** `lib/models/horse_race_game.dart` `recordDartThrow()` method

## Performance Considerations

### Race Track Rendering
**Concern:** Race track widget with multiple horse positions could cause jank if re-rendered frequently

**Mitigation:**
- Uses `Consumer<HorseRaceProvider>` to only rebuild when game state changes
- Horse positions calculated once per score update
- No continuous animations on race track

**Monitoring:** Watch for frame drops during score updates with 8 players

### Scroll Controller Animation
**Concern:** Auto-scrolling to current player could conflict with manual scrolling

**Mitigation:**
- Checks `hasClients` before attempting scroll
- Uses smooth animation curve instead of instant jump
- Only triggers on turn advancement, not every dart

**Monitoring:** Test with rapid turn transitions and manual scrolling

## Integration Points

### Global User Management
**Integration:** Carnival Derby integrates with `PlayerProvider` for player data and statistics

**Key Methods Used:**
- `updatePlayerStats(playerId, won: bool, gameName: 'Carnival Derby', gameDuration: Duration)` - Called for all players (winners and losers) when game completes
- `savePlayer(player)` - Called when creating new player via Add Player dialog
- `allPlayers` - Accessed to get available player list in menu screen

**Implementation:**
```dart
// On game complete (results screen init)
final gameDuration = DateTime.now().difference(widget.game.startedAt);
final winnerId = widget.game.winnerId;

for (final playerId in widget.game.playerIds) {
  await playerProvider.updatePlayerStats(
    playerId,
    won: playerId == winnerId,
    gameName: 'Carnival Derby',
    gameDuration: gameDuration,  // Same duration for all players
  );
}
```

### Announcer System
**Integration:** Uses global `GameAnnouncementQueueService` via `CarnivalDerbyAnnouncementHelper`

**Helper Class:** `CarnivalDerbyAnnouncementHelper`

**Key Patterns:**
```dart
// Initialize in initState
final globalQueue = GameAnnouncementQueueService();
await globalQueue.loadSettings();
_audioQueue = CarnivalDerbyAnnouncementHelper(globalQueue);

// Announce turn
_audioQueue?.announceTurn(playerName);

// Announce dart with automatic sound effect
_audioQueue?.announceDart(score, multiplier);

// Announce bust
_audioQueue?.announceBust(playerName);

// Dispose in dispose()
_audioQueue?.dispose();
```

### Victory Music
**Integration:** Plays custom victory music from `VictoryMusicService` when winner announced

**Implementation:**
```dart
final musicService = VictoryMusicService();

if (await musicService.hasCustomMusic()) {
  final musicSource = await musicService.getRandomMusicSource();
  if (musicSource != null) {
    // Play using audio player (web or native)
  }
}
```

### Dartboard Emulator
**Integration:** Uses shared dartboard emulator components with Carnival Derby configuration

**Configuration:** `DartboardSectionConfig.carnivalDerby()` and `DartboardFABConfig.carnivalDerby()`

**Implementation:**
```dart
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  shouldPromptTakeout: horseRaceProvider.shouldPromptTakeout,
  dartboardKey: _dartboardKey,
  onDartThrow: (score, multiplier, baseScore, position) {
    _mockApi!.simulateDartThrow(...);
  },
  onRemoveDarts: () {
    _mockApi?.simulateTakeoutFinished();
  },
  config: DartboardSectionConfig.carnivalDerby(),
)
```

## Data Persistence

### Game State
**Storage:** Not persisted - games must be completed in one session

**Serialization:** `HorseRaceGame` has `toJson()` and `fromJson()` methods for potential future persistence

### Player Stats
**Storage:** SharedPreferences via `PlayerProvider`

**Data Tracked:**
- Games played: Incremented for all players in game
- Games won: Incremented only for winner
- Game duration: Recorded with identical duration for all players (winners and losers)
- Game name: "Carnival Derby"
- Timestamp: Game completion time

### Settings Persistence
**Storage:** SharedPreferences in menu screen

**Persisted Settings:**
- Target score (int)
- Exact score mode (bool)

**Implementation:**
```dart
// Save settings when changed
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('horse_race_target_score', targetScore);
await prefs.setBool('horse_race_exact_score_mode', exactScoreMode);

// Load settings on menu screen init
final prefs = await SharedPreferences.getInstance();
setState(() {
  _targetScore = prefs.getInt('horse_race_target_score') ?? 100;
  _exactScoreMode = prefs.getBool('horse_race_exact_score_mode') ?? false;
});
```

## Known Issues and Limitations

### No Mid-Game Save
**Description:** Games cannot be paused and resumed later

**Impact:** Players must complete game in one session

**Workaround:** Keep games short by using lower target scores

**Future Fix:** Implement game state persistence and resume functionality

### Max 8 Players
**Description:** Hard limit of 8 players enforced in UI

**Impact:** Cannot play with more than 8 players

**Workaround:** Run multiple games in sequence

**Future Fix:** Consider team mode or spectator slots

## Future Enhancements

### Planned Features
- [ ] Multiplayer network support (players on different devices)
- [ ] Handicap system for mixed skill levels
- [ ] Tournament bracket mode
- [ ] Replay/highlight system
- [ ] Custom horse avatar selection

### Enhancement Ideas
- [ ] Animated horse galloping sprites
- [ ] Photo finish camera for close races
- [ ] Crowd cheering sound effects
- [ ] Leaderboard for fastest times to target
- [ ] Achievement system (win by exactly 1 point, etc.)

### Technical Debt
- [ ] Refactor announcement timing to use queue promises instead of nested Future.delayed
- [ ] Extract magic numbers (tile height, animation durations) to constants
- [ ] Add unit tests for edge cases in score calculation
- [ ] Optimize wood plank texture loading (currently 10.5MB)

## Development Tips

### Common Tasks

#### Adding a New Announcement
1. Add method to `CarnivalDerbyAnnouncementHelper` class
2. Define message text and sound effect
3. Call from game screen at appropriate trigger point
4. Test with different announcer personalities

#### Adding a New Sound Effect
1. Add MP3 file to `assets/games/carnival_derby/sounds/`
2. Define `SoundEffectConfig` in `CarnivalDerbySoundEffects` class
3. Reference in announcement helper method
4. Update `assets.md` documentation

#### Modifying Game Rules
1. Update `HorseRaceGame` model if data structure changes
2. Update `HorseRaceProvider` logic methods
3. Update `game-rules.md` documentation
4. Add/update tests in `test/screens/games/carnival_horse_race/`
5. Run full test suite to verify no regressions

### Debugging Tips

#### Issue: Announcements Not Playing
**Symptom:** Darts land but no voice announcements
**Debug Steps:**
1. Check `_audioQueue` is initialized (not null)
2. Verify `GameAnnouncementQueueService` settings loaded
3. Check System Settings > Announcer > Voice Enabled
4. Look for browser permission issues (web)

#### Issue: Scores Not Updating
**Symptom:** Darts land but scores don't change
**Debug Steps:**
1. Check `processDartThrow()` is being called
2. Verify `_currentGame` is not null
3. Check if waiting for takeout (blocks new throws)
4. Confirm player ID matches current player

#### Issue: Edit Score Not Working
**Symptom:** Editing scores doesn't update game state
**Debug Steps:**
1. Verify all 3 dart segments provided
2. Check player ID matches current player
3. Confirm segments parse correctly (S20, D15, etc.)
4. Check `resetToStartOfTurn()` restores correct state

## Reference Implementations

### Similar Patterns in Other Games
- Turn-based gameplay: Target Tag uses similar turn advancement logic
- Edit score dialog: Target Tag has same pattern with different config
- Announcer integration: Target Tag shows complete announcement helper implementation
- Victory music: Target Tag demonstrates identical integration pattern

### External Resources
- Flutter Provider package: https://pub.dev/packages/provider
- Google Fonts package: https://pub.dev/packages/google_fonts
- SharedPreferences package: https://pub.dev/packages/shared_preferences
