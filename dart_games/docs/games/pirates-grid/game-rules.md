# Pirate's Grid - Game Rules

## Objective

Be the first captain to plant your pirate flags in 3 squares in a row (horizontal, vertical, or diagonal) on the 3x3 treasure map grid. In Best Of mode, win more rounds than your opponent to become Captain of the Seas.

## Setup

- **Players:** Exactly 2 (no team mode, no solo mode)
- **Starting Conditions:** All 9 grid squares are empty. Each player has 0 flags planted and 0 rounds won. The grid target layout is generated based on the selected Target Difficulty.
- **Configuration Options:**
  - Target Difficulty: Easy (default), Medium, or Hard — controls what dart hits claim each square
  - Best Of: 1 (default), 3, or 5 — controls how many rounds are played to determine the match winner
  - Steal Mode: OFF (default) / ON — when ON, hitting an opponent's claimed square replaces their flag
  - Speed Play: OFF (default) / ON — when ON, a 15-second timer ends the turn automatically

## How to Play

### Turn Structure
1. The active player's panel highlights — their name and flags count are shown prominently
2. The player throws up to 3 darts at the dartboard
3. For each dart thrown:
   - The game determines which grid cell (if any) the dart's target matches
   - If the dart matches a cell requirement and the cell is empty, the player's flag is planted
   - If Steal Mode is ON and the dart matches a cell owned by the opponent, the flag is replaced
   - Dart indicators in the player panel fill in as darts are thrown
4. After 3 darts (or after a skip turn, or after Speed Play timer expires), the RemoveDartsModal appears (when using the emulator) — the player removes their darts and the next turn begins
5. If 3-in-a-row is detected at any point during the turn, the round ends immediately

### Scoring and Progress

**Flags planted:** Each successful hit that claims or steals a square adds one flag to that player's count.

**Rounds won:** When a player achieves 3-in-a-row, they win the current round and earn one round win toward the match.

**Draw:** If all 9 squares are filled with no 3-in-a-row, the round is a draw. Neither player earns a round win. The match continues to the next round (in Best Of mode) until the match result is determined.

### Dart Processing Logic

For each dart thrown:
1. Determine the number hit and multiplier (Single/Double/Triple/Bull)
2. Find which grid cell requires this exact target based on difficulty:
   - **Easy:** Any hit on the number claims the square (S/D/T all work)
   - **Medium:** Must hit the double or triple segment (single hits do NOT count)
   - **Hard:** Must match exact requirement (T cells = triple only, D cells = double only, center = Bull inner or outer)
3. If no matching cell exists for the dart: "Miss" — no effect, turn continues
4. If the matching cell is found:
   - Empty: plant current player's flag in that cell
   - Already claimed by current player: no effect (already yours)
   - Claimed by opponent AND Steal Mode OFF: no effect (dart is wasted)
   - Claimed by opponent AND Steal Mode ON: replace opponent's flag with yours (mutiny!)
5. After any flag is planted, check all 8 lines for 3-in-a-row; if found, round ends immediately

## Grid Target Layouts

### Easy Targets — Any segment on the number claims the square
```
+------+------+------+
|  20  |  18  |  16  |
+------+------+------+
|  19  |  17  |  15  |
+------+------+------+
|  14  |  12  |  10  |
+------+------+------+
```

### Medium Targets — Must hit Double or Triple
```
+------+------+------+
| D20  | D18  | D16  |
+------+------+------+
| D19  | D17  | D15  |
+------+------+------+
| D14  | D12  | D10  |
+------+------+------+
```

### Hard Targets — Corners=Triple, Edges=Double, Center=Bull
```
+------+------+------+
|  T20 |  D18 |  T16 |
+------+------+------+
|  D19 | Bull |  D15 |
+------+------+------+
|  T14 |  D12 |  T10 |
+------+------+------+
```

## Special Mechanics

### Steal Mode (Mutiny)
When Steal Mode is ON, no square is safe. If a player hits the dart target for a square already claimed by their opponent, the opponent's flag is forcibly replaced with the attacker's flag. A Sword Clash sound plays and a "Mutiny!" announcement fires. This creates a highly dynamic game where early-game advantages can be undone at any time.

### Best Of Rounds
- **Best Of 1:** Single round. The round winner is the match winner.
- **Best Of 3:** First to win 2 rounds wins the match. Maximum 3 rounds played.
- **Best Of 5:** First to win 3 rounds wins the match. Maximum 5 rounds played.
- **Between rounds:** A brief "Round X Complete!" overlay appears, then the grid resets to empty and the next round begins. The player who went second in the previous round goes first in the next round (starting player alternates each round).
- **Match draw:** All rounds played and neither player reached the required win count (only possible when all rounds end in a draw — a rare scenario).

### Speed Play Timer
When Speed Play is ON, a 15-second countdown timer appears in the active player's panel. Colors change as the timer decreases:
- 15-6 seconds: Treasure Gold
- 5-3 seconds: Compass Rose Bronze
- 2-0 seconds: Blood Red (pulsing animation)

At 5, 4, 3, 2, and 1 seconds, a Timer Tick sound plays. When the timer reaches 0, the turn automatically ends and remaining darts are forfeited. The timer resets to 15 at the start of each player's turn.

## Win Conditions

- **Round win:** First player to get 3 in a row (horizontal, vertical, or diagonal)
- **Round draw:** All 9 squares are filled with no 3-in-a-row anywhere
- **Match win:** First player to reach the required round wins (1 for Bo1, 2 for Bo3, 3 for Bo5)
- **Match draw:** All rounds played, neither player reached the required win count (all-draws scenario)

## Edge Cases and Special Rules

- **Draw detection:** The draw check runs after each dart is processed. A full grid with no winner triggers the draw immediately — the turn does not need to fully complete.
- **Steal Mode with 3-in-a-row:** When a stolen square completes 3-in-a-row, the thief wins the round. The winning line uses the thief's flag color.
- **Speed Play timer expiration:** All remaining darts are forfeited. The RemoveDartsModal still appears to prompt dart removal.
- **Already-claimed (own cell):** Hitting a number that maps to your own claimed cell has no effect. The "Yer flag already flies there, captain!" announcement plays.
- **Already-claimed (opponent, Steal OFF):** Hitting the opponent's cell when Steal Mode is OFF also has no effect. The "That square is defended!" announcement plays.
- **Winning line glow:** All 3 cells in the winning line receive a Treasure Gold pulsing glow animation and sparkle overlay. The winning line is stored in the model (`winningLine`) and persists on the results screen.
- **Save/restore mid-match:** The full match state is serialized — current round, rounds won per player, current grid state, starting player index for the current round, and any win/draw flags. Resuming a saved Best Of 3 or 5 match restores exactly where the players left off.

## Strategy Tips

- **Easy difficulty:** Focus on the corners (20, 16, 14, 10) first — each corner is part of 2 lines (1 row/column + 1 diagonal).
- **Center cell (17 on Easy/Medium, Bull on Hard):** The center square is part of 4 different lines (2 diagonals, 1 row, 1 column) — it is the most valuable cell on the board.
- **Steal Mode:** If Steal Mode is ON, don't over-commit to filling one row. Your opponent can undo your progress at any time.
- **Best Of 5:** Draws are neutral — neither player gains, and the grid resets. Consider whether to push for a win or risk a full-grid draw.
