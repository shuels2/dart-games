# Target Tag - User Management Integration Test Plan

## Overview

This test plan covers Target Tag's integration with the global Dart Games user management system. These tests validate:
- Add player dialog functionality
- Win count tracking for winners and losers
- Game duration recording for ALL players
- Game history persistence
- Stats calculations across multiple games
- Solo and Team mode user management

**Important:** Target Tag differs from Carnival Derby in user management:
- **Target Tag:** ALL players (winners AND losers) receive game history entries with duration
- **Carnival Derby:** Only winners receive game history entries with duration

This design choice reflects that Target Tag is a competitive multiplayer experience where all participants' play time should be tracked, regardless of outcome.

**Note:** This test plan complements the announcement validation tests (TARGET_TAG_TEST_PLAN.md). These tests focus exclusively on user management integration.

---

## Test Suite: User Management Integration (12 Tests)

**Automation Status:**
- **Tests 1-3**: Manual UI tests (Add Player Dialog) - See `test/screens/games/target_tag/TARGET_TAG_MANUAL_UI_TESTS.md`
- **Tests 4-12**: Automated integration tests (✅ Implemented in `target_tag_user_management_test.dart`)

### Section 1: Add Player Dialog (3 Tests - MANUAL)

**Note:** These tests validate UI interactions in the Add Player dialog. They are performed manually because:
- The dialog has web-specific dependencies that complicate automated widget testing
- The validation logic is simple (empty name check)
- The underlying functionality (player creation, selection, persistence) is fully covered by automated provider tests
- Manual testing provides sufficient coverage for this low-risk UI component

**📋 Manual Test Procedures:** Detailed step-by-step instructions are available in:
`test/screens/games/target_tag/TARGET_TAG_MANUAL_UI_TESTS.md`

**Quick Reference (see manual test file for full details):**

#### Test 1: Add Player with Name Only
**Setup:**
- Open Target Tag menu screen
- Click "Add New Player" button

**Steps:**
1. Dialog opens with empty name field and no photo
2. Enter player name "Test Player"
3. Click "Add Player" button

**Expected Results:**
- Player is saved to global player list
- Player appears in available players section
- Player is automatically selected
- Dialog closes
- PlayerProvider.allPlayers contains the new player
- Player has no photo (photoPath is null)

---

#### Test 2: Add Player with Name and Photo
**Setup:**
- Open Target Tag menu screen
- Click "Add New Player" button

**Steps:**
1. Dialog opens with empty name field
2. Enter player name "Photo Player"
3. Click "GALLERY" button and select test photo
4. Photo preview appears in dialog
5. Click "Add Player" button

**Expected Results:**
- Player is saved with name "Photo Player"
- Player has photoPath set (data URL for web, file path for native)
- Player appears in available players with photo displayed
- Player is automatically selected
- Dialog closes

---

#### Test 3: Add Player Validation - Empty Name
**Setup:**
- Open Target Tag menu screen
- Click "Add New Player" button

**Steps:**
1. Dialog opens with empty name field
2. Leave name field empty
3. Click "Add Player" button

**Expected Results:**
- Error message appears: "Please enter a name"
- Dialog remains open
- Player is NOT saved
- PlayerProvider.allPlayers count unchanged

**Additional Step:**
4. Enter valid name "Valid Player"
5. Click "Add Player" button

**Expected Results:**
- Error message disappears
- Player is saved successfully
- Dialog closes

---

### Section 2: Win Tracking - Solo Mode (4 Tests)

#### Test 4: Solo Mode - Single Winner Records Stats
**Setup:**
- Create 2 players: Alice, Bob
- Start solo game with 3 shields
- Play game until Alice wins (Bob eliminated)

**Expected Results:**
- **Alice (Winner):**
  - gamesPlayed = 1
  - gamesWon = 1
  - gameHistory.length = 1
  - gameHistory[0].gameName = 'Target Tag'
  - gameHistory[0].duration is not null
  - gameHistory[0].timestamp is not null

- **Bob (Loser):**
  - gamesPlayed = 1
  - gamesWon = 0
  - gameHistory.length = 1
  - gameHistory[0].gameName = 'Target Tag'
  - gameHistory[0].duration is not null (same duration as winner)
  - gameHistory[0].timestamp is not null

---

#### Test 5: Solo Mode - Multiple Games Accumulate History
**Setup:**
- Create 2 players: Charlie, David
- Play 3 solo games (Charlie wins 2, David wins 1)

**Steps:**
- Game 1: Charlie wins
- Game 2: David wins
- Game 3: Charlie wins

**Expected Results After 3 Games:**
- **Charlie:**
  - gamesPlayed = 3
  - gamesWon = 2
  - gameHistory.length = 3 (all games, winner or loser)
  - All history entries have gameName = 'Target Tag'
  - All history entries have unique IDs
  - All history entries have duration > 0

- **David:**
  - gamesPlayed = 3
  - gamesWon = 1
  - gameHistory.length = 3 (all games, winner or loser)
  - All history entries have gameName = 'Target Tag'
  - All history entries have duration > 0

---

#### Test 6: Solo Mode - Game Duration Accuracy
**Setup:**
- Create 2 players: Emily, Frank
- Start solo game

**Steps:**
1. Record game start time (from game.startedAt)
2. Play game for known duration (simulate specific throws)
3. Emily wins the game
4. Record end time
5. Calculate expected duration = end - start

**Expected Results:**
- **Emily (Winner):**
  - gameHistory[0].duration matches calculated duration (within 1 second tolerance)
  - Duration is reasonable (> 0, < 1 hour for test scenario)
  - Duration is stored in correct format

- **Frank (Loser):**
  - gameHistory[0].duration matches calculated duration (same as Emily)
  - Both players receive identical duration values
  - Duration represents the full game length from start to finish

---

#### Test 7: Solo Mode - Stats Persist Across App Restart
**Setup:**
- Create 2 players: Grace, Henry
- Play 1 game (Grace wins, Henry loses)
- Verify stats recorded

**Steps:**
1. Create new PlayerProvider instance (simulates app restart)
2. Call loadPlayers()
3. Retrieve both players' data

**Expected Results:**
- **Grace (Winner):**
  - gamesPlayed = 1
  - gamesWon = 1
  - gameHistory.length = 1
  - All game history data intact (gameName, duration, timestamp)

- **Henry (Loser):**
  - gamesPlayed = 1
  - gamesWon = 0
  - gameHistory.length = 1
  - All game history data intact (gameName, duration, timestamp)

- Both players' stats correctly loaded from SharedPreferences

---

### Section 3: Win Tracking - Team Mode (3 Tests)

#### Test 8: Team Mode - All Players Get Stats with Duration
**Setup:**
- Create 4 players: Alice, Bob, Charlie, Dave
- Teams: Team 1 (Alice, Bob), Team 2 (Charlie, Dave)
- Start team game with 3 shields
- Play until Team 1 wins

**Expected Results:**
- **Alice (Team 1 Winner):**
  - gamesPlayed = 1
  - gamesWon = 1
  - gameHistory.length = 1
  - gameHistory[0].gameName = 'Target Tag'
  - gameHistory[0].duration is not null

- **Bob (Team 1 Winner):**
  - gamesPlayed = 1
  - gamesWon = 1
  - gameHistory.length = 1
  - gameHistory[0].gameName = 'Target Tag'
  - gameHistory[0].duration is not null

- **Charlie (Team 2 Loser):**
  - gamesPlayed = 1
  - gamesWon = 0
  - gameHistory.length = 1
  - gameHistory[0].gameName = 'Target Tag'
  - gameHistory[0].duration is not null

- **Dave (Team 2 Loser):**
  - gamesPlayed = 1
  - gamesWon = 0
  - gameHistory.length = 1
  - gameHistory[0].gameName = 'Target Tag'
  - gameHistory[0].duration is not null

**Note:** All players (winners and losers) receive identical game duration in their history.

---

#### Test 9: Team Mode - Mixed Player History Across Multiple Games
**Setup:**
- Create 4 players: Alice, Bob, Charlie, Dave
- Game 1: Teams (Alice+Bob vs Charlie+Dave), Team 1 wins
- Game 2: Teams (Alice+Charlie vs Bob+Dave), Team 2 wins

**Expected Results After Game 1:**
- Alice: gamesPlayed=1, gamesWon=1, history.length=1
- Bob: gamesPlayed=1, gamesWon=1, history.length=1
- Charlie: gamesPlayed=1, gamesWon=0, history.length=1
- Dave: gamesPlayed=1, gamesWon=0, history.length=1

**Expected Results After Game 2:**
- Alice: gamesPlayed=2, gamesWon=1, history.length=2 (1 win, 1 loss)
- Bob: gamesPlayed=2, gamesWon=2, history.length=2 (2 wins)
- Charlie: gamesPlayed=2, gamesWon=0, history.length=2 (2 losses)
- Dave: gamesPlayed=2, gamesWon=1, history.length=2 (1 loss, 1 win)

**Note:** Each player's history reflects all games played, regardless of win/loss outcome.

---

#### Test 10: Team Mode - 3-Team Game Stats
**Setup:**
- Create 6 players forming 3 teams of 2
- Team 1 (Alice, Bob), Team 2 (Charlie, Dave), Team 3 (Eve, Frank)
- Start 3-team game
- Play until Team 2 wins

**Expected Results:**
- **Team 1 (Losers):** Alice and Bob have gamesPlayed=1, gamesWon=0, history.length=1
- **Team 2 (Winners):** Charlie and Dave have gamesPlayed=1, gamesWon=1, history.length=1
- **Team 3 (Losers):** Eve and Frank have gamesPlayed=1, gamesWon=0, history.length=1
- **All 6 players** have identical game duration in their history entries

---

### Section 4: Stats Calculations (2 Tests)

#### Test 11: Total Play Time Calculation
**Setup:**
- Create player: Isabel
- Play 3 games with specific durations (mix of wins and losses)

**Steps:**
1. Game 1: Duration = 3 minutes, Isabel wins
2. Game 2: Duration = 5 minutes, Isabel loses
3. Game 3: Duration = 4 minutes, Isabel wins
4. Call playerProvider.getPlayerTotalPlayTime(isabel.id)

**Expected Results:**
- Total play time = 12 minutes (3 + 5 + 4)
- Calculation includes all game history entries (both wins and losses)
- Duration is accurate to the second
- All games contribute to total play time regardless of outcome

---

#### Test 12: Average Game Duration by Game Name
**Setup:**
- Create player: Jack
- Play multiple games (mix of Target Tag and other games, mix of wins and losses)

**Steps:**
1. Target Tag Game 1: 6 minutes, Jack wins
2. Target Tag Game 2: 4 minutes, Jack loses
3. Target Tag Game 3: 8 minutes, Jack wins
4. Different Game (Carnival Derby): 10 minutes, Jack wins (to verify filtering)
5. Call playerProvider.getPlayerAverageGameDuration(jack.id, 'Target Tag')

**Expected Results:**
- Average Target Tag duration = 6 minutes (6 + 4 + 8) / 3
- Calculation includes all Target Tag games (both wins and losses)
- Carnival Derby game duration is NOT included in average
- Returns null if no games match the game name

---

## Implementation Notes

### Test Infrastructure Requirements

1. **Mock Target Tag Provider:**
   - Need to simulate complete games with controllable outcomes
   - Must track game.startedAt timestamp
   - Support both solo and team modes
   - Provide getWinners() method that returns Player objects

2. **Player Provider Integration:**
   - Use actual PlayerProvider (not mock) to test real integration
   - Use SharedPreferences.setMockInitialValues({}) for isolation
   - Test actual data persistence and retrieval

3. **Test Helpers:**
   - Helper to quickly complete a game with specified winner
   - Helper to create teams with player lists
   - Helper to verify stats match expected values
   - Duration manipulation for time-based tests

4. **Target Tag Results Screen Implementation:**
   The actual results screen should call updatePlayerStats like this:
   ```dart
   // Calculate game duration
   final gameDuration = DateTime.now().difference(currentGame.startedAt);

   // Get winners
   final winners = targetTagProvider.getWinners(playerProvider.allPlayers);
   final winnerIds = winners.map((p) => p.id).toSet();

   // Update stats for ALL players (winners and losers)
   for (final playerId in currentGame.playerIds) {
     final isWinner = winnerIds.contains(playerId);
     await playerProvider.updatePlayerStats(
       playerId,
       won: isWinner,
       gameName: 'Target Tag',  // ALL players get game name
       gameDuration: gameDuration,  // ALL players get duration
     );
   }
   ```
   This differs from Carnival Derby where only winners receive gameName and gameDuration.

### Key Testing Patterns

**Pattern 1: Verify Winner and Loser Stats**
```dart
// Winner
expect(winner.gamesPlayed, expectedPlayed);
expect(winner.gamesWon, expectedWon);
expect(winner.gameHistory.length, expectedHistoryCount);
expect(winner.gameHistory.last.gameName, 'Target Tag');
expect(winner.gameHistory.last.duration, isNotNull);

// Loser (also gets history in Target Tag)
expect(loser.gamesPlayed, expectedPlayed);
expect(loser.gamesWon, expectedWon); // Will be 0 if they haven't won any
expect(loser.gameHistory.length, expectedHistoryCount);
expect(loser.gameHistory.last.gameName, 'Target Tag');
expect(loser.gameHistory.last.duration, isNotNull);

// Verify both have same duration for the same game
expect(winner.gameHistory.last.duration, loser.gameHistory.last.duration);
```

**Pattern 2: Duration Validation**
```dart
final startTime = game.startedAt;
// ... play game ...
final endTime = DateTime.now();
final expectedDuration = endTime.difference(startTime);

// Verify recorded duration matches
final recordedDuration = winner.gameHistory.last.duration;
expect(
  (recordedDuration.inSeconds - expectedDuration.inSeconds).abs(),
  lessThan(2), // Allow 1-2 second tolerance
);
```

**Pattern 3: Team Mode Winner Verification**
```dart
final winners = targetTagProvider.getWinners(playerProvider.allPlayers);
for (final winner in winners) {
  final player = playerProvider.getPlayerById(winner.id);
  expect(player.gamesWon, expectedWins);
  expect(player.gameHistory.length, expectedHistoryLength);
}
```

---

## Success Criteria

All 12 tests must pass with:
- ✅ Add player dialog correctly validates input and saves players
- ✅ Winners receive incremented gamesWon and gameHistory entries with duration
- ✅ Losers receive incremented gamesPlayed and gameHistory entries with duration
- ✅ All players in a game receive identical game duration (from start to finish)
- ✅ Game duration is accurately calculated and recorded for all participants
- ✅ Stats persist across app restarts (SharedPreferences integration)
- ✅ Solo mode correctly tracks individual player stats (winners and losers)
- ✅ Team mode correctly tracks stats for all team members (winners and losers)
- ✅ Mixed team compositions across games work correctly
- ✅ Total play time calculation is accurate (includes all games played)
- ✅ Average duration calculation filters by game name correctly (includes all games)

---

## Integration with Existing Tests

These tests complement the existing test suites:
- **TARGET_TAG_TEST_PLAN.md (32 tests):** Game logic and announcements
- **carnival_derby_user_management_test.dart (8 tests):** Reference implementation for user management pattern (NOTE: different behavior - Carnival Derby only tracks winners' durations)

**Key Difference from Carnival Derby:**
- Carnival Derby: `updatePlayerStats(winnerId, won: true, gameName: 'Carnival Derby', gameDuration: duration)` for winners only
- Target Tag: `updatePlayerStats(playerId, won: isWinner, gameName: 'Target Tag', gameDuration: duration)` for ALL players

Total Target Tag test coverage: 44 tests (32 announcements + 12 user management)

---

## Next Steps

1. Review this test plan for completeness
2. Create test implementation file: `test/screens/games/target_tag/target_tag_user_management_test.dart`
3. Create test helpers as needed
4. Run all tests and achieve 100% pass rate
5. Update CLAUDE.md with new test count (171 → 183 tests)
