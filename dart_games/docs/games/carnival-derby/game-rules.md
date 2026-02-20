# Carnival Derby - Game Rules

## Objective
Be the first horse to cross the finish line by reaching or exceeding the target score!

Carnival Derby is a dartboard racing game where each player's horse advances along a track based on their dart scores. Players throw darts to accumulate points, with their position displayed as a percentage of the track completed. The first player to reach the target score wins the race.

## Setup
- **Players:** 1-8 players (solo or multiplayer)
- **Starting Conditions:** All players start at score 0 (beginning of track)
- **Configuration Options:**
  - **Target Score:** 20-250 points (default: 100)
  - **Game Mode:** Normal Mode or Perfect Finish Mode (see Game Modes below)

## How to Play

### Turn Structure
1. **Turn Start** - The current player's name is announced
2. **Throw Darts** - Player throws up to 3 darts on the dartboard
3. **Score Accumulation** - Each dart's score is added to the player's total
4. **Turn End** - After 3 darts (or manual advance), turn passes to next player
5. **Repeat** - Continue until a player reaches the target score

### Scoring/Progress
- Each dart throw adds points to the player's total score
- Player positions are displayed as horses on a race track
- Horse position = (Current Score / Target Score) × 100%
- Example: With target 100, a score of 75 shows horse at 75% of track

**Dart Scoring:**
- **Single (outer):** Face value (e.g., S20 = 20 points)
- **Single (inner):** Face value (e.g., s20 = 20 points)
- **Double:** 2× face value (e.g., D20 = 40 points)
- **Triple:** 3× face value (e.g., T20 = 60 points)
- **Outer Bull (25):** 25 points
- **Bullseye (Bull):** 50 points
- **Miss:** 0 points

### Special Mechanics

#### Skip Turn
Players can skip remaining darts in their current turn:
- Press "Skip Turn" button during their turn
- Visual markers (―) fill remaining dart slots
- Turn immediately advances to next player
- Useful for strategic play or when current score is sufficient

#### Edit Score
Players can correct dart scores if a throw was misrecorded:
- Press "Edit Score" button during turn review
- Adjust all 3 dart scores using ring/number picker
- Recalculates total score based on edited values
- Maintains game integrity while allowing error correction

#### Darts Removed / Take Out
After throwing 3 darts or skipping turn:
- Game waits for darts to be removed from physical dartboard
- Press "Darts Removed" button to confirm
- Turn advances to next player
- In emulator mode, virtual darts are cleared

## Game Modes

### Normal Mode (Race Mode)
**Default racing rules:**
- Players can exceed the target score
- First player to reach **or exceed** target score wins
- No penalty for going over the target
- Best for casual play and faster games

**Example:**
- Target: 100 points
- Player at 95 throws Bull (50)
- Final score: 145 (95 + 50) → **WINS!**

### Perfect Finish Mode (Exact Score)
**Challenge mode requiring precise scoring:**
- Players must hit the target score **exactly**
- If a dart would cause player to exceed target, they **bust**
- On bust: score remains unchanged, turn ends immediately
- Player must try again on their next turn

**Example:**
- Target: 100 points
- Player at 95 throws Bull (50)
- Would score 145 (95 + 50) → **BUST!**
- Score stays at 95, turn ends
- Player needs exactly 5 points (S5 or 25÷5 remaining darts)

**Perfect Finish Strategy:**
- Plan dart combinations to reach exact target
- Leave yourself with common finish combinations (e.g., 40 for D20)
- Risk vs. reward: high-scoring darts increase bust risk near target

## Win Conditions

### Normal Mode
- **First player to reach or exceed the target score wins**
- Win is detected immediately after dart lands
- Game announces winner and displays results screen

### Perfect Finish Mode
- **First player to hit the exact target score wins**
- Going over target results in bust (no win)
- Requires strategic dart selection near finish

## Edge Cases and Special Rules

- **Simultaneous Win:** Not possible - turns are sequential, first player to reach target in their turn wins
- **Bust on First Dart (Perfect Finish):** Turn ends immediately, score preserved, remaining darts not thrown
- **Bust on Second Dart (Perfect Finish):** Turn ends, only first dart score counted
- **Bust on Third Dart (Perfect Finish):** Turn ends, first two darts counted
- **Skip Turn with Zero Darts:** Allowed - advances turn without scoring
- **Edit Score After Win:** Editing scores after a win is detected may recalculate winner
- **Target Score Validation:** Menu enforces 20-250 range, must have at least 1 player selected

## Strategy Tips

**Normal Mode:**
- Aim for high-scoring segments (T20, T19, T18) to advance quickly
- Bullseye (50) is valuable for big jumps
- No need to calculate exact finish - go for maximum points

**Perfect Finish Mode:**
- Calculate remaining score before each throw
- Near finish, aim for segments that leave common doubles (D20, D16, etc.)
- Avoid high-scoring segments when close to target (risk of bust)
- Example finish combinations:
  - 50 remaining → Bull
  - 40 remaining → D20
  - 32 remaining → D16
  - 26 remaining → D13

**General Tips:**
- Consistent scoring beats high-risk throws
- Watch opponent positions to gauge urgency
- In Perfect Finish, sometimes lower scores are safer
- Use "Skip Turn" strategically if position is strong
