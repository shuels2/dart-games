# Target Tag - Implementation Notes

## Code Architecture

### Provider Pattern
**File:** `lib/providers/target_tag_provider.dart`

**State Management:**
- Manages current game state (`TargetTagGame` model)
- Tracks waiting-for-takeout state (`_waitingForTakeout`)
- Provides getters for game status, shields, Tagged In status, eliminations
- Notifies listeners on all state changes

**Key Methods:**
- `startSoloGame(List<Player> players, int shieldMax, bool heroBonus)` - Initializes solo mode game
- `startTeamGame(Map<String, List<String>> teams, int shieldMax, bool heroBonus, [Map<String, String>? teamIconOverrides])` - Initializes team mode game
- `processDartThrow(int score, String multiplier, int baseScore, String segment)` - Records dart throw, processes shield changes, checks eliminations
- `skipTurn()` - Fills remaining dart slots with visual markers, sets waiting for takeout
- `updateAllDartScores(String playerId, List<String> newSegments)` - Replays turn with edited scores
- `handleTakeoutFinished()` - Advances to next player after darts removed
- `getShields(String playerId)` - Returns entity shields (player or team)
- `isTaggedIn(String playerId)` - Checks if entity is Tagged In
- `isEliminated(String playerId)` - Checks if entity is eliminated

**State Variables:**
- `_currentGame`: TargetTagGame? - Current game instance or null
- `_waitingForTakeout`: bool - Whether game is waiting for darts to be removed

### Models
**File:** `lib/models/target_tag_game.dart`

**Data Structure:**
```dart
class TargetTagGame {
  final String id;                        // Unique game identifier
  final GameMode mode;                    // solo or team
  final int shieldMax;                    // Max shields (1-10)
  final bool soloHeroBonus;              // Hero Bonus enabled
  final DateTime startedAt;               // Game start timestamp
  final int maxDartsPerTurn;             // Always 3 for Target Tag

  // Player management
  final List<String> playerIds;           // All players in turn order
  final Map<String, int> targetNumbers;   // playerId → target number (1-20)

  // Team mode specific
  final Map<String, String>? playerToTeam;        // playerId → teamId
  final Map<String, List<String>>? teamPlayers;   // teamId → [playerIds]
  final Map<String, String>? teamIcons;           // teamId → icon path

  // Hero Bonus
  final Map<String, int>? soloHeroBuffNumbers;         // playerId → buff number
  final Map<String, String>? soloHeroBuffMultipliers;  // playerId → "double" or "triple"

  // Runtime state (entity = playerId for solo, teamId for team)
  Map<String, int> shields;                // entityId → current shields
  Map<String, bool> taggedIn;             // entityId → Tagged In status
  Map<String, bool> eliminated;           // entityId → eliminated status
  Map<String, int> dartsThrown;           // playerId → darts thrown this turn
  Map<String, List<String>> currentTurnDarts;  // playerId → dart segments

  // Per-dart tracking for visual feedback
  Map<String, List<bool>> dartThrowTaggedInStatus;      // Was Tagged In when dart thrown
  Map<String, List<bool>> dartThrowHeroBonusHit;        // Was dart a Hero Bonus hit
  Map<String, List<bool>> dartThrowReachedMax;          // Did dart cause shields to reach max
  Map<String, List<bool>> dartThrowCausedElimination;   // Did dart eliminate opponent
  Map<String, List<bool>> dartThrowHitOpponentTarget;   // Did dart hit opponent target

  GameState state;                        // setup, playing, suddenDeath, finished
  int currentPlayerIndex;                 // Index of current player
  String? winnerId;                       // entityId (playerId or teamId)
}
```

**Key Responsibilities:**
- Store game configuration (mode, shield max, Hero Bonus, players, teams)
- Track shields, Tagged In status, eliminations per entity (player or team)
- Manage target number assignments (unique per player/team)
- Handle Hero Bonus assignments (unique numbers, random multiplier)
- Detect win conditions (last player/team standing)
- Support score editing via turn state reset

### Screen Architecture

#### Menu Screen
**File:** `lib/screens/games/target_tag/target_tag_menu_screen.dart`

**Purpose:** Configure game settings and select players/teams

**Key Components:**
- Game mode toggle (Solo vs Team)
- Shield Max slider (1-10)
- Hero Bonus toggle
- Player selection (2-10 players solo, 2-5 teams of 2)
- Team assignment UI (drag-and-drop)
- Add player button
- Start game button
- Pulse animation background effect

**State Management:**
- Uses `PlayerProvider` for player list management
- Local state for game settings (mode, shield max, Hero Bonus)
- Local state for team assignments
- Server API persistence for last-used settings

#### Game Screen
**File:** `lib/screens/games/target_tag/target_tag_game_screen.dart`

**Purpose:** Active gameplay with shield building and elimination

**Key Components:**
- Active player panel (shields, target, Hero Bonus)
- Opponent targets grid
- Player tile list (scrollable)
- Skip turn button
- Edit score button
- Remove darts button
- Dartboard emulator section (when not connected)
- Game timer tracking
- Elimination detection and navigation to results

**State Management:**
- Uses `TargetTagProvider` for game state
- Uses `DartboardProvider` for dartboard connection
- Uses `PlayerProvider` for player data
- Local state for dartboard emulator controller, scroll controller

#### Results Screen
**File:** `lib/screens/games/target_tag/target_tag_results_screen.dart`

**Purpose:** Display winner(s) and game statistics

**Key Components:**
- Winner display with trophy and confetti
- Team winners displayed together (team mode)
- Final shields and statistics
- Play again button (restarts with same settings)
- Change settings button (returns to menu)
- Victory music playback

## Complex Algorithms

### Shield Calculation from Dart Hit
**Purpose:** Determine shield gain/loss based on dart hit and game state

**Implementation:**
```dart
void _processShieldChange(String playerId, int targetNumber, String multiplier, int baseScore) {
  final entityId = _getEntityId(playerId);
  final currentShields = shields[entityId] ?? 0;

  // Check if hitting own target
  final ownTarget = targetNumbers[playerId];
  if (baseScore == ownTarget) {
    // Build shields: +1 for single, +2 for double, +3 for triple
    final shieldGain = _getMultiplierValue(multiplier);
    final newShields = (currentShields + shieldGain).clamp(0, shieldMax);
    shields[entityId] = newShields;

    // Check if reached Tagged In status
    if (newShields >= shieldMax && !taggedIn[entityId]!) {
      taggedIn[entityId] = true;
      // Announcement: Tagged In
    }
  }

  // Check if hitting opponent target (only when Tagged In)
  else if (taggedIn[entityId]!) {
    final opponentEntityId = _findEntityByTarget(baseScore);
    if (opponentEntityId != null) {
      final opponentShields = shields[opponentEntityId] ?? 0;
      final newOpponentShields = (opponentShields - 1).clamp(0, shieldMax);
      shields[opponentEntityId] = newOpponentShields;

      // Check if opponent eliminated (hit at 0 shields)
      if (opponentShields == 0) {
        eliminated[opponentEntityId] = true;
        // Announcement: Eliminated
      }

      // Check if opponent lost Tagged In
      if (newOpponentShields < shieldMax && taggedIn[opponentEntityId]!) {
        taggedIn[opponentEntityId] = false;
        // Announcement: Tagged Out
      }
    }
  }

  // Check Hero Bonus hit
  if (soloHeroBonus && soloHeroBuffNumbers![playerId] == baseScore) {
    final requiredMultiplier = soloHeroBuffMultipliers![playerId];
    if (multiplier == requiredMultiplier) {
      // +1 shield from Hero Bonus
      final newShields = (currentShields + 1).clamp(0, shieldMax);
      shields[entityId] = newShields;
    }
  }
}
```

**Complexity:** O(1) - constant time map lookups and arithmetic

**Edge Cases:**
- Hitting own target while Tagged In still builds shields (defensive strategy)
- Hero Bonus only grants shield if correct multiplier hit
- Tagged In lost immediately when shields drop below max
- Elimination only occurs when hit at exactly 0 shields
- Multiple opponents can be eliminated in one turn

### Target Number Assignment
**Purpose:** Assign unique target numbers (1-20) to players/teams

**Implementation:**
```dart
static List<int> _assignTargetNumbers(int count) {
  final numbers = List.generate(20, (i) => i + 1); // 1-20
  numbers.shuffle();
  return numbers.take(count).toList();
}
```

**Complexity:** O(n) - shuffle and take

**Edge Cases:**
- Maximum 20 unique targets available (limits 10 teams max)
- Solo mode: one target per player
- Team mode: one target per team (all teammates share)

### Hero Bonus Assignment
**Purpose:** Assign unique Hero Bonus numbers and multipliers

**Implementation:**
```dart
final usedNumbers = targetNumbers.toSet();
final availableNumbers = List.generate(20, (i) => i + 1)
    .where((n) => !usedNumbers.contains(n))
    .toList()
  ..shuffle();

final random = Random();
final multiplierOptions = ['double', 'triple'];

for (int i = 0; i < playerCount; i++) {
  final buffNumber = availableNumbers[i];
  final buffMultiplier = multiplierOptions[random.nextInt(2)];

  soloHeroBuffNumbers[playerId] = buffNumber;
  soloHeroBuffMultipliers[playerId] = buffMultiplier;
}
```

**Complexity:** O(n) - filter, shuffle, assign

**Edge Cases:**
- Hero Bonus numbers cannot be same as any target number
- Multiplier randomly chosen (50% double, 50% triple)
- Team mode: all teammates share same Hero Bonus

### Team Turn Order
**Purpose:** Alternate players between teams for fair gameplay

**Implementation:**
```dart
static List<String> _buildTeamTurnOrder(Map<String, List<String>> teams) {
  final turnOrder = <String>[];
  final teamIds = teams.keys.toList();
  final maxPlayersPerTeam = teams.values.map((p) => p.length).reduce(max);

  // Alternate between teams: Team1-P1, Team2-P1, Team1-P2, Team2-P2
  for (int i = 0; i < maxPlayersPerTeam; i++) {
    for (final teamId in teamIds) {
      final players = teams[teamId]!;
      if (i < players.length) {
        turnOrder.add(players[i]);
      }
    }
  }

  return turnOrder;
}
```

**Complexity:** O(t × p) where t = teams, p = players per team

**Example:** Team1 [Alice, Bob], Team2 [Charlie, Diana]
→ Turn order: [Alice, Charlie, Bob, Diana]

## Gotchas and Quirks

### Shields vs Tagged In Timing
**Issue:** Player reaches Shield Max on dart 2, but should only be Tagged In after turn ends

**Why it happens:** Tagged In status checked immediately after each dart

**How to handle:** Track `reachedMax` flag per dart, announce Tagged In at turn end

**Code location:** `lib/providers/target_tag_provider.dart` processDartThrow()

### Edit Score Elimination Undo
**Issue:** Editing scores can revive eliminated players if changes undo eliminating hit

**Why it happens:** Turn state reset recalculates all game state from turn start

**How to handle:** Acceptable behavior - edit score allows full undo/redo of turn

**Code location:** `lib/providers/target_tag_provider.dart` updateAllDartScores()

### Team Mode Entity IDs
**Issue:** Shields/Tagged In/Eliminated tracked by teamId, not playerId

**Why it happens:** Teams share shields, so entity = teamId in team mode

**How to handle:** Always use `_getEntityId(playerId)` to get correct ID based on mode

**Code location:** `lib/models/target_tag_game.dart` entity resolution methods

## Performance Considerations

### Opponent Grid Rendering
**Concern:** Grid with 2-10 opponents re-renders frequently

**Mitigation:**
- Uses `Consumer<TargetTagProvider>` to rebuild only when state changes
- Grid items are stateless widgets
- No continuous animations on grid

**Monitoring:** Watch for frame drops with 10 players

### Per-Dart State Tracking
**Concern:** Multiple List<bool> maps track per-dart state for visual feedback

**Mitigation:**
- Lists capped at 3 elements (max darts)
- Cleared at turn end
- Only used for UI feedback, not core logic

**Monitoring:** Memory usage with many turns/players

## Integration Points

### Global User Management
**Integration:** Target Tag integrates with `PlayerProvider` for player data and statistics

**Key Methods Used:**
- `updatePlayerStats(playerId, won: bool, gameName: 'Target Tag', gameDuration: Duration)` - Called for all players (winners and losers) when game completes
- `savePlayer(player)` - Called when creating new player via Add Player dialog
- `allPlayers` - Accessed to get available player list in menu screen

**Implementation:**
```dart
// On game complete (results screen init)
final gameDuration = DateTime.now().difference(widget.game.startedAt);
final winners = widget.game.getWinners(playerProvider.allPlayers);
final winnerIds = winners.map((p) => p.id).toSet();

for (final playerId in widget.game.playerIds) {
  await playerProvider.updatePlayerStats(
    playerId,
    won: winnerIds.contains(playerId),
    gameName: 'Target Tag',
    gameDuration: gameDuration,  // Same duration for all players
  );
}
```

### Announcer System
**Integration:** Uses global `GameAnnouncementQueueService` via `TargetTagAnnouncementHelper`

**Helper Class:** `TargetTagAnnouncementHelper`

**Key Patterns:**
```dart
// Initialize in initState
final globalQueue = GameAnnouncementQueueService();
await globalQueue.loadSettings();
_audioQueue = TargetTagAnnouncementHelper(globalQueue);

// Announce with multiple players
_audioQueue?.announceTaggedIn(['Alice', 'Bob']);

// Dispose in dispose()
_audioQueue?.dispose();
```

### Victory Music
**Integration:** Plays custom victory music from `VictoryMusicService` when winner announced

**Implementation:** Same pattern as Carnival Derby

### Dartboard Emulator
**Integration:** Uses shared dartboard emulator components with Target Tag configuration

**Configuration:** `DartboardSectionConfig.targetTag()` and `DartboardFABConfig.targetTag()`

## Data Persistence

### Game State
**Storage:** Not persisted - games must be completed in one session

**Serialization:** `TargetTagGame` has `toJson()` and `fromJson()` methods for potential future persistence

### Player Stats
**Storage:** Server API via `PlayerProvider`

**Data Tracked:**
- Games played: Incremented for all players
- Games won: Incremented for winners only
- Game duration: Recorded with identical duration for all players
- Game name: "Target Tag"
- Timestamp: Game completion time

### Settings Persistence
**Storage:** Server API via `ApiClient`

**Persisted Settings:**
- Game mode (solo/team)
- Shield Max (int)
- Hero Bonus enabled (bool)

## Known Issues and Limitations

### Max 10 Players
**Description:** Hard limit of 10 players in solo mode, 5 teams (10 players) in team mode

**Impact:** Cannot play with more than 10 total players

**Workaround:** Run multiple games

**Future Fix:** Consider 20-player support with smaller UI elements

### No Sudden Death
**Description:** Sudden Death mode exists in model but not implemented in UI

**Impact:** Games can theoretically run forever if no one eliminated

**Workaround:** Players can manually end game

**Future Fix:** Implement time limit and Sudden Death UI

## Future Enhancements

### Planned Features
- [ ] Sudden Death time limit mode
- [ ] Power-ups (double shield gain, shield steal, etc.)
- [ ] Spectator mode for eliminated players
- [ ] Replay system to review eliminations
- [ ] Statistics tracking (most eliminations, fastest Tagged In, etc.)

### Enhancement Ideas
- [ ] Custom target number selection
- [ ] Animated shield effects
- [ ] Elimination celebration animations
- [ ] Team chat/strategy planning time
- [ ] Leaderboards for elimination streaks

### Technical Debt
- [ ] Implement Sudden Death UI
- [ ] Optimize opponent grid for 10 players
- [ ] Add unit tests for team mode edge cases
- [ ] Refactor entity ID resolution into helper class

## Development Tips

### Common Tasks

#### Adding a New Announcement
1. Add method to `TargetTagAnnouncementHelper` class
2. Define message text and sound effect
3. Call from game screen at appropriate trigger point
4. Test with different player counts (1, 2, 3+)

#### Adding a New Sound Effect
1. Add MP3 file to `assets/games/target_tag/sounds/`
2. Define `SoundEffectConfig` in `TargetTagSoundEffects` class
3. Reference in announcement helper method
4. Update `assets.md` documentation

#### Modifying Game Rules
1. Update `TargetTagGame` model if data structure changes
2. Update `TargetTagProvider` logic methods
3. Update `game-rules.md` documentation
4. Add/update tests in `test/screens/games/target_tag/`
5. Run full test suite to verify no regressions

### Debugging Tips

#### Issue: Shields Not Updating
**Symptom:** Darts land but shields don't change
**Debug Steps:**
1. Check if hitting correct target number
2. Verify entity ID resolution (player vs team)
3. Check if Tagged In when trying to attack
4. Confirm opponent target number matches dart

#### Issue: Tagged In Status Not Working
**Symptom:** Player reaches Shield Max but not Tagged In
**Debug Steps:**
1. Verify shields exactly equal shieldMax (not greater)
2. Check entity ID (player vs team mode)
3. Confirm `taggedIn` map updated
4. Look for announcement trigger

#### Issue: Eliminations Not Detected
**Symptom:** Hitting opponent at 0 shields doesn't eliminate
**Debug Steps:**
1. Verify current player is Tagged In
2. Confirm opponent actually at 0 shields (not 1)
3. Check dart hit opponent's target number
4. Verify entity ID resolution

## Reference Implementations

### Similar Patterns in Other Games
- Turn-based gameplay: Carnival Derby uses similar turn advancement
- Edit score dialog: Carnival Derby has same pattern with different config
- Announcer integration: Carnival Derby shows complete announcement helper
- Victory music: Carnival Derby demonstrates identical pattern

### External Resources
- Flutter Provider package: https://pub.dev/packages/provider
- Google Fonts package: https://pub.dev/packages/google_fonts
- Dart Shelf server: https://pub.dev/packages/shelf
