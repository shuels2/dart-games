# Carnival Derby - Interactive UI Test Plan

## Overview
This document outlines comprehensive interactive UI tests for Carnival Derby covering menu setup, game progression, score tracking, announcement validation, and edge cases.

## Game Mechanics Summary

### Core Rules
- **Players:** 1-8 players
- **Target Score:** 20-250 points (slider with 46 divisions)
- **Game Modes:**
  - **Normal Mode** (Perfect Finish OFF): First to reach/exceed target wins
  - **Perfect Finish Mode** (Perfect Finish ON): Must hit exact score; going over causes bust (score stays at pre-bust value, turn ends)
- **Turn Structure:** 3 darts per turn
- **Scoring:** Standard dartboard scoring (single, double, triple, bullseye=50, outer bull=25, miss=0)

### Announcement Timing & Order

**During Game (Game Screen):**
1. First turn announcement - immediate on game start
2. Turn announcements - 500ms after takeout finished
3. Dart score announcements - immediate after dart throw
4. Bust sequence (Perfect Finish mode only):
   - Dart score → 1500ms → Bust announcement → 3000ms → Remove darts → 2000ms → takeout
5. Turn end (3rd dart or winner):
   - Dart score → 2500ms → Remove darts → takeout
6. Skip turn:
   - If darts thrown: 1500ms → Remove darts → 3500ms → takeout
   - If no darts thrown: 500ms → takeout (no announcements)

**Results Screen:**
1. Game complete announcement - immediate
2. Winner announcement - 3000ms after game complete

### Screen State Indicators
- **Current Player Section:** Shows player name, score, darts thrown (D1, D2, D3), target score, game mode
- **Race Track:** Shows all players' horses advancing based on score
- **Dartboard Section:** Interactive dartboard emulator (can be hidden/shown with FAB)
- **Remove Darts Modal:** Appears when `shouldPromptTakeout` is true, blocks dartboard

---

## Test Sections

### Section 1: Menu - Player Selection
**Purpose:** Validate player selection mechanics, auto-selection, and max player enforcement

#### Test 1.1: Basic Player Addition and Auto-Selection
**Steps:**
1. Navigate to Carnival Derby menu
2. Add Player 1
3. Verify Player 1 appears in list
4. Add Player 2
5. Verify both players remain in list

**Expected:**
- Player list shows both players
- Players auto-selected on creation
- Play button disabled with 0 selected
- Play button enabled with 1 selected

#### Test 1.2: Max Player Enforcement (8 Players)
**Steps:**
1. Navigate to Carnival Derby menu
2. Add 10 players total
3. Attempt to select all 10 players manually
4. Verify max 8 can be selected
5. Start game with exactly 8 players

**Expected:**
- Only first 8 players auto-selected
- 9th player not auto-selected
- Cannot manually select 9th player
- Play button enabled with 8 selected
- Game starts successfully

---

### Section 2: Menu - Target Score Settings
**Purpose:** Validate target score slider and Perfect Finish toggle

#### Test 2.1: Target Score Range Validation
**Steps:**
1. Navigate to Carnival Derby menu
2. Verify slider range 20-250 with 46 divisions
3. Set target to 20 (minimum)
4. Set target to 250 (maximum)
5. Set target to 150 (middle)

**Expected:**
- Slider allows 20-250 range
- Display shows "Target score: X points"
- Range label shows "Range: 20-250 points"

#### Test 2.2: Perfect Finish Toggle
**Steps:**
1. Navigate to Carnival Derby menu
2. Toggle "Perfect Finish" ON
3. Toggle "Perfect Finish" OFF

**Expected:**
- Toggle works

---

### Section 3: Game - Basic Race Mechanics (Normal Mode)
**Purpose:** Validate basic scoring, turn progression, and race advancement

#### Test 3.1: Single Player Quick Win (Normal Mode)
**Steps:**
1. Start game: 1 player, target 60, Perfect Finish OFF
2. Turn 1: Throw T20, T20, T20 (180 total - instant win)
3. Verify game won
4. Navigate to results screen

**Expected Announcements (in order):**
1. `"{Player}, it's your turn"` (1000ms after start)
2. `"triple 20 for 60"` (after dart 1)
3. `"triple 20 for 60"` (after dart 2)
4. `"triple 20 for 60"` (after dart 3)
5. `"{Player}, remove your darts"` (2500ms after dart 3)
6. *[Takeout completes, navigate to results]*
7. `"The game is complete"` (results screen, immediate)
8. `"{Player} is the winner"` (results screen, 3000ms later)

**Expected State:**
- Player score: 60 (≥ target, wins)
- Horse position: At finish line
- Game state: Winner detected
- Results screen shows winner

#### Test 3.2: Two Players Alternating Turns (Normal Mode)
**Steps:**
1. Start game: 2 players (Alice, Bob), target 100, Perfect Finish OFF
2. Alice Turn 1: S20, S20, S20 (60 total)
3. Bob Turn 1: S15, S15, S15 (45 total)
4. Alice Turn 2: D20 (40, total 100 - wins)

**Expected Announcements (in order):**
1. `"Alice, it's your turn"` (1000ms after start)
2. `"20"` (Alice dart 1)
3. `"20"` (Alice dart 2)
4. `"20"` (Alice dart 3)
5. `"Alice, remove your darts"` (2500ms after dart 3)
6. *[Takeout]*
7. `"Bob, it's your turn"` (500ms after takeout)
8. `"15"` (Bob dart 1)
9. `"15"` (Bob dart 2)
10. `"15"` (Bob dart 3)
11. `"Bob, remove your darts"` (2500ms after dart 3)
12. *[Takeout]*
13. `"Alice, it's your turn"` (500ms after takeout)
14. `"double 20 for 40"` (Alice dart 1, wins)
15. `"Alice, remove your darts"` (2500ms after dart)
16. *[Takeout, navigate to results]*
17. `"The game is complete"` (results)
18. `"Alice is the winner"` (results, 3000ms later)

**Expected State:**
- After Alice Turn 1: Alice=60, Bob=0
- After Bob Turn 1: Alice=60, Bob=45
- After Alice Turn 2: Alice=100 (winner), Bob=45
- Results show Alice as winner

#### Test 3.3: All Dart Types (Normal Mode)
**Steps:**
1. Start game: 1 player, target 200, Perfect Finish OFF
2. Turn 1: S20 (20), D20 (40 total), T20 (60 total)
3. Turn 2: Bullseye (50, total 110), 25/Outer Bull (25, total 135), Miss (0, total 135)
4. Turn 3: T20, T20, S5 (200 total - wins)

**Expected Announcements (in order):**
1. `"{Player}, it's your turn"` (1000ms after start)
2. `"20"` (single)
3. `"double 20 for 40"` (double)
4. `"triple 20 for 60"` (triple)
5. `"{Player}, remove your darts"`
6. *[Takeout]*
7. `"{Player}, it's your turn"`
8. `"Bullseye! 50 points!"` (bullseye)
9. `"25. Outer bull."` (outer bull)
10. `"Miss"` (miss)
11. `"{Player}, remove your darts"`
12. *[Takeout]*
13. `"{Player}, it's your turn"`
14. `"triple 20 for 60"`
15. `"triple 20 for 60"`
16. `"5"`
17. `"{Player}, remove your darts"`
18. *[Takeout, navigate to results]*
19. `"The game is complete"`
20. `"{Player} is the winner"` (3000ms later)

**Expected State:**
- Turn 1 scores: 20, 40, 60
- Turn 2 scores: 110, 135, 135
- Turn 3 scores: 160, 200 (winner)
- Dart display: D1/D2/D3 show correct scores

---

### Section 4: Game - Perfect Finish Mode (Bust Mechanics)
**Purpose:** Validate exact score requirement and bust behavior

#### Test 4.1: Simple Bust (Going Over)
**Steps:**
1. Start game: 1 player (Alice), target 50, Perfect Finish ON
2. Turn 1: S20 (20), T20 (80 total - BUST!)
3. Verify bust announcement and score reversion to 20 (the score before the bust)
4. Turn 2: S20 (20), S20 (40), S10 (50 - exact win)

**Expected Announcements (in order):**
1. `"Alice, it's your turn"` (1000ms)
2. `"20"` (dart 1)
3. `"triple 20 for 60"` (dart 2)
4. `"Alice, you busted and your turn is over"` (1500ms after dart 2)
5. `"Alice, remove your darts"` (3000ms after bust)
6. *[Takeout]*
7. `"Alice, it's your turn"` (500ms)
8. `"20"` (dart 1)
9. `"10"` (dart 2 - wins)
10. `"Alice, remove your darts"` (2500ms)
11. *[Takeout, navigate to results]*
12. `"The game is complete"`
13. `"Alice is the winner"` (3000ms)

**Expected State:**
- After dart 1 (S20): Alice=20
- After dart 2 (T20): Alice=20 (busted, stays at 20)
- Bust flag: true
- Turn 2 dart 2: Alice=50 (exact, wins)

#### Test 4.2: Bust on First Dart
**Steps:**
1. Start game: 1 player, target 30, Perfect Finish ON
2. Turn 1: D20 (40 - BUST on first dart!)
3. Turn 2: S20 (20), S10 (30 - exact win)

**Expected Announcements:**
1. `"{Player}, it's your turn"` (1000ms)
2. `"double 20 for 40"` (dart 1)
3. `"{Player}, you busted and your turn is over"` (1500ms)
4. `"{Player}, remove your darts"` (3000ms)
5. *[Takeout]*
6. `"{Player}, it's your turn"` (500ms)
7. `"20"`
8. `"10"` (wins)
9. `"{Player}, remove your darts"`
10. *[Takeout, navigate to results]*
11. `"The game is complete"`
12. `"{Player} is the winner"` (3000ms)

**Expected State:**
- After turn 1: Score=0 (busted on first dart)
- After turn 2: Score=30 (exact, wins)

#### Test 4.3: Multiple Busts Before Win
**Steps:**
1. Start game: 2 players (Alice, Bob), target 40, Perfect Finish ON
2. Alice Turn 1: Bullseye (50 - BUST!)
3. Bob Turn 1: T20 (60 - BUST!)
4. Alice Turn 2: D20 (40 - exact win)

**Expected Announcements:**
1. `"Alice, it's your turn"`
2. `"Bullseye! 50 points!"`
3. `"Alice, you busted and your turn is over"`
4. `"Alice, remove your darts"`
5. *[Takeout]*
6. `"Bob, it's your turn"`
7. `"triple 20 for 60"`
8. `"Bob, you busted and your turn is over"`
9. `"Bob, remove your darts"`
10. *[Takeout]*
11. `"Alice, it's your turn"`
12. `"double 20 for 40"`
13. `"Alice, remove your darts"`
14. *[Takeout, navigate to results]*
15. `"The game is complete"`
16. `"Alice is the winner"` (3000ms)

**Expected State:**
- Alice after turn 1: 0 (busted)
- Bob after turn 1: 0 (busted)
- Alice after turn 2: 40 (exact, wins)

#### Test 4.4: Close Call (Just Under, Then Exact)
**Steps:**
1. Start game: 1 player, target 100, Perfect Finish ON
2. Turn 1: T20, S20, S15 (95 total - safe, 5 under)
3. Turn 2: S5 (100 - exact win)

**Expected Announcements:**
1. `"{Player}, it's your turn"`
2. `"triple 20 for 60"`
3. `"20"`
4. `"15"`
5. `"{Player}, remove your darts"`
6. *[Takeout]*
7. `"{Player}, it's your turn"`
8. `"5"` (wins)
9. `"{Player}, remove your darts"`
10. *[Takeout, navigate to results]*
11. `"The game is complete"`
12. `"{Player} is the winner"`

**Expected State:**
- After turn 1: 95 (5 under target, safe)
- After turn 2: 100 (exact, wins)
- No bust

---

### Section 5: Game - Skip Turn Functionality
**Purpose:** Validate skip turn behavior with and without darts thrown

#### Test 5.1: Skip Turn with Darts Thrown
**Steps:**
1. Start game: 2 players (Alice, Bob), target 60, Perfect Finish OFF
2. Alice Turn 1: S20 (20), click SKIP TURN
3. Verify misses added for remaining darts
4. Bob Turn 1: T20 (60 - wins)

**Expected Announcements:**
1. `"Alice, it's your turn"`
2. `"20"` (dart 1)
3. `"Alice, remove your darts"` (1500ms after skip)
4. *[Takeout after 3500ms]*
5. `"Bob, it's your turn"` (500ms)
6. `"triple 20 for 60"`
7. `"Bob, remove your darts"`
8. *[Takeout, navigate to results]*
9. `"The game is complete"`
10. `"Bob is the winner"`

**Expected State:**
- Alice after skip: 20 (1 dart thrown + 2 misses added)
- Alice dart display: D1=20, D2=Miss, D3=Miss
- Bob wins with 60

#### Test 5.2: Skip Turn with No Darts Thrown
**Steps:**
1. Start game: 2 players (Alice, Bob), target 60, Perfect Finish OFF
2. Alice Turn 1: Click SKIP TURN immediately (no darts)
3. Bob Turn 1: D20, D20, D20 (120 - wins)

**Expected Announcements:**
1. `"Alice, it's your turn"`
2. *[No remove darts announcement - skip with 0 darts]*
3. `"Bob, it's your turn"` (500ms after takeout)
4. `"double 20 for 40"`
5. `"double 20 for 40"`
6. `"double 20 for 40"`
7. `"Bob, remove your darts"`
8. *[Takeout, navigate to results]*
9. `"The game is complete"`
10. `"Bob is the winner"`

**Expected State:**
- Alice after skip: 0 (3 misses added)
- Alice dart display: D1=Miss, D2=Miss, D3=Miss
- Bob wins with 120

---

### Section 6: Game - Edit Score Functionality
**Purpose:** Validate edit score modal and score recalculation

#### Test 6.1: Edit Score During Remove Darts Modal (Normal Mode)
**Steps:**
1. Start game: 1 player, target 100, Perfect Finish OFF
2. Turn 1: S20, S20, S20 (60)
3. While remove darts modal showing, click "Edit player score"
4. Change all 3 darts: D1=T20, D2=T20, D3=S20 (140 total)
5. Click "Update score"
6. Verify score updated and game won

**Expected State:**
- Before edit: Score=60, darts=S20/S20/S20
- After edit: Score=140 (wins), darts=T20/T20/S20
- Game state: Winner detected
- Navigate to results screen

#### Test 6.2: Edit Score with Bust (Perfect Finish Mode)
**Steps:**
1. Start game: 1 player, target 80, Perfect Finish ON
2. Turn 1: S20, S15, S10 (45)
3. Edit score: Change to T20, T20, T20 (180 - BUST!)
4. Verify bust detected and score reverts
5. Remove darts and continue
6. Turn 2: D20, S10, S5 (80 - exact win)

**Expected State:**
- Before edit: Score=45, no bust
- After edit: Score=60 (after processing T20, T20, then bust on 3rd T20)
- Bust flag: true
- Turn 2: Score=80 (exact win)

---

### Section 7: Game - Multi-Player Race
**Purpose:** Validate multiple players racing to finish

#### Test 7.1: 4-Player Race with Leaderboard Changes
**Steps:**
1. Start game: 4 players (Alice, Bob, Charlie, Diana), target 150, Perfect Finish OFF
2. Round 1: Alice=60, Bob=45, Charlie=80, Diana=20
3. Round 2: Alice=120, Bob=100, Charlie=140, Diana=80
4. Round 3: Charlie wins with 180

**Expected State:**
- Leaderboard updates each turn
- Visual race track shows relative positions
- Charlie's horse crosses finish line first
- Results screen shows correct final standings

#### Test 7.2: 8-Player Maximum Capacity
**Steps:**
1. Start game: 8 players, target 100, Perfect Finish OFF
2. All players throw T20 each turn
3. All reach 60 after turn 1
4. All reach 120 after turn 2 (all win simultaneously)

**Expected State:**
- Game handles 8 players smoothly
- All 8 horses visible on race track
- First player to throw winning dart is declared winner
- Results screen shows all 8 players in final standings

---

### Section 8: Edge Cases
**Purpose:** Validate unusual scenarios and boundary conditions

#### Test 8.1: Minimum Target Score (20 points)
**Steps:**
1. Start game: 1 player, target 20, Perfect Finish ON
2. Turn 1: S20 (exact win)

**Expected:**
- Game starts successfully
- Single S20 wins
- Results screen appears

#### Test 8.2: Maximum Target Score (250 points)
**Steps:**
1. Start game: 1 player, target 250, Perfect Finish OFF
2. Multiple turns to reach 250+
3. Win detected when ≥250

**Expected:**
- Game progresses normally
- Score tracking accurate
- Win detected at correct threshold

#### Test 8.3: All Misses Turn
**Steps:**
1. Start game: 2 players, target 60, Perfect Finish OFF
2. Alice Turn 1: Miss, Miss, Miss (0)
3. Bob Turn 1: T20 (60 - wins)

**Expected Announcements:**
1. `"Alice, it's your turn"`
2. `"Miss"` (dart 1)
3. `"Miss"` (dart 2)
4. `"Miss"` (dart 3)
5. `"Alice, remove your darts"`
6. *[Takeout]*
7. `"Bob, it's your turn"`
8. `"triple 20 for 60"`
9. `"Bob, remove your darts"`
10. *[Takeout, navigate to results]*
11. `"The game is complete"`
12. `"Bob is the winner"`

**Expected State:**
- Alice: Score=0, D1=Miss, D2=Miss, D3=Miss
- Bob wins with 60

---

### Section 9: Results Screen
**Purpose:** Validate results screen display and actions

#### Test 9.1: Results Screen Content
**Steps:**
1. Complete game with winner
2. Verify results screen displays:
   - "Winner!" title
   - Winner avatar and name
   - Final score
   - Final standings table
   - Play Again button
   - Change settings button
   - Home button

**Expected:**
- All elements visible
- Confetti animation plays
- Victory music plays
- Announcements: Game complete → Winner

#### Test 9.2: Play Again (Same Settings)
**Steps:**
1. Complete game
2. Click "Play Again"
3. Verify new game starts with same players/settings

**Expected:**
- Navigate to game screen
- Same players
- Same target score
- Same Perfect Finish setting
- Scores reset to 0

#### Test 9.3: Change Settings
**Steps:**
1. Complete game
2. Click "Change game players and settings"
3. Verify menu loads with previous settings

**Expected:**
- Navigate to menu
- Players preselected
- Target score preserved
- Perfect Finish setting preserved

---

## Test Infrastructure Requirements

### Mock Services Needed
1. **MockCarnivalDerbyAudioQueue** - Captures announcements without playing audio
2. **MockScoliaApiService** - Simulates dart throws (already exists)
3. **MockHorseRaceProvider** - If needed for state verification

### Helper Functions Required
1. `navigateToCarnivalDerbyMenu()` - Navigate from home to menu
2. `addPlayer(name)` - Add player via NEW PLAYER button
3. `selectPlayer(name)` - Toggle player selection
4. `setTargetScore(score)` - Set slider value
5. `togglePerfectFinish()` - Toggle exact score mode
6. `startGame()` - Click START RACE button
7. `throwDart(number, multiplier)` - Simulate dart throw
8. `throwBullseye()` - Throw bullseye (50)
9. `throwOuterBull()` - Throw outer bull (25)
10. `throwMiss()` - Simulate miss
11. `clickDartsRemoved()` - Click DARTS REMOVED button
12. `clickSkipTurn()` - Click SKIP TURN button
13. `getMockApi(tester)` - Get MockScoliaApiService
14. `verifyAnnouncements(expected[])` - Verify announcement order
15. `verifyPlayerScore(playerName, expectedScore)` - Verify current score
16. `verifyDartDisplay(D1, D2, D3)` - Verify dart scores shown

### Pump Sequences
- After navigation: `pump() → pump(1s) → pump() → pump(5s) → pump() → pump() → pump()`
- After dart throw: `pump() → pump(300ms) → pump()`
- After button click: `pump() → pump(500ms) → pump() → pump() → pump()`

---

## Success Criteria
- All menu validations pass
- All game mechanics tests pass
- All announcement sequences match exactly
- Perfect Finish mode bust logic works correctly
- Skip turn works with/without darts
- Edit score recalculates properly
- Multi-player races work smoothly
- Results screen displays correctly
- All edge cases handled

---

## Notes
- Tests should be isolated (each test starts fresh)
- SharedPreferences cleared before each test
- Use emulator mode for consistent dartboard behavior
- Announcement validation critical - must match exact order and timing
- State verification after each action
- Visual elements validated (scores, standings, race positions)
