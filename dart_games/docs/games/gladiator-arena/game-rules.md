# Gladiator Arena - Game Rules

## Objective

Be the first gladiator to accumulate the target number of Glory Points (default 200, configurable 100–500). Race hard — but watch out: if your score EXACTLY matches another player's score at the end of your turn, they get knocked back to zero!

## Setup

- **Players:** 2–8 (individual, no teams)
- **Starting Conditions:** All players begin at 0 Glory Points
- **Configuration Options:**
  - **Target Score (Champion's Goal):** Slider, 100–500 in steps of 25, default 200
  - **Double Finish (Champion's Strike):** Toggle ON/OFF, default ON
  - **Shield Round:** Toggle ON/OFF, default OFF
  - **Speed Play:** Toggle ON/OFF, default OFF

Characters are randomly assigned from the pool of 8 gladiator animals at the start of each game (same shuffle pattern as Lunar Lander / Reef Royale).

## How to Play

### Turn Structure

1. **Turn begins:** Active player's podium glows with Imperial Purple border. Name label appears below their podium. Speed Play timer starts at 25 seconds (if Speed Play ON).
2. **Throw 3 darts:** Player throws up to 3 darts. Each dart's score is added to the turn running total. Dart scores: single = face value, double = 2× face value, triple = 3× face value, Bullseye (inner bull) = 50, Outer Bull = 25.
3. **Turn ends:** After 3 darts (or Skip Turn, or Speed Play timer expiry), the turn is processed.
4. **Remove darts prompt:** When `shouldPromptTakeout` is true, the Remove Darts modal or DartboardEmulatorSection shows. Player removes darts.
5. **Score update and checks:** The prospective new score is evaluated (see Dart Processing Logic below).
6. **Next player:** Turn advances to the next player in rotation.

### Scoring (Glory Points)

| Dart Segment | Score |
|---|---|
| Single (S) | Face value (1–20) |
| Double (D) | Face value × 2 (2–40) |
| Triple (T) | Face value × 3 (3–60) |
| Outer Bull | 25 |
| Inner Bull (Bullseye) | 50 |

All darts thrown in a turn accumulate into a turn total. The turn total is added to the player's current score after all 3 darts are thrown (subject to bust rules below).

### Dart Processing Logic

```
For each dart thrown:
  1. Determine segment hit and multiplier (S/D/T/Bull)
  2. Calculate dart value (segment × multiplier; Bull inner=50, outer=25)
  3. Add dart value to turn running total

After all 3 darts (or skip / timer expiry):
  a. Prospective new score = current score + turn total
  b. If Double Finish ON:
     - If prospective > target: BUST — turn total voided, score unchanged
     - If prospective == target:
       - Last dart MUST be a double → if yes: VICTORY
       - If last dart is NOT a double: BUST
     - Otherwise: score = prospective new score
  c. If Double Finish OFF:
     - If prospective >= target: VICTORY (no overshoot bust, no double requirement)
     - Otherwise: score = prospective new score

KNOCKOFF CHECK (after score update; not run if VICTORY):
  For each OTHER player:
    - If current player's NEW score == other player's score:
      - If Shield Round is active: knockoff BLOCKED (Shield Block)
      - Otherwise: other player's score resets to 0 (KNOCKOFF)
```

## Special Mechanics

### Knockoff (Eliminator Rule)

The signature mechanic: if your score after a turn EXACTLY matches any other player's current score, that player is knocked off their podium back to zero. Multiple players can be knocked off in a single turn if the active player's new score matches more than one opponent.

**Edge cases:**
- A player CANNOT knock themselves off (self-score match is ignored)
- A knockoff resets the victim's score to 0 but does NOT reset the attacker's score
- If a player at score 0 is matched, no additional effect occurs (already at zero)
- Knockoff is evaluated AFTER the turn score is recorded, not during

### Bust (Double Finish ON only)

**Overshoot bust:** If the prospective new score exceeds the target, the entire turn's darts are voided and the score reverts to what it was before the turn.

**Non-double bust:** If the prospective score exactly equals the target but the final dart thrown was NOT a double, the turn is also voided.

Neither bust type applies when Double Finish is OFF.

### Champion's Strike (Double Finish)

**When ON:** The player must land their final dart on a double segment (D1–D20 or Outer Bull = D25) and that dart must bring the score to EXACTLY the target. This requires precision on the final throw.

**When OFF:** Any dart that brings the score to or above the target wins immediately. There is no overshoot bust and no double requirement.

### Shield Round

**When ON:** Every 5th round (rounds 5, 10, 15, …) is a Shield Round. A shield banner appears at the top of the game screen during these rounds. During a Shield Round, the knockoff check still runs but no player can have their score reset — the knockoff is blocked and the "Shields up!" announcement plays instead.

The Shield Round ends when the round ends. Non-5th rounds always allow knockoffs.

### Speed Play

**When ON:** A 25-second countdown timer appears in the AppBar actions area. The timer starts when the active player's turn begins. If the timer expires before the player throws all 3 darts, only the darts already thrown count toward the turn score. Remaining dart slots show "X" (timed out).

**Timer freeze:** The timer is cancelled (`_speedPlayTimer?.cancel()`) the moment `provider.shouldPromptTakeout` becomes true (3 darts thrown, Skip Turn pressed, or round transition). The timer is restarted by `_startSpeedPlayTimerForCurrentPlayer` at the start of the next player's turn. This prevents the timer from ticking through the remove-darts animation.

**Timer warning:** When the timer reaches 5 seconds remaining, the display turns Blood Red and the "Sands running out!" announcement fires.

## Win Conditions

**Double Finish ON:** A player wins by throwing a dart that is a double AND lands exactly on the target score. The prospective score must equal the target and the last thrown dart must be a double segment.

**Double Finish OFF:** A player wins by throwing any dart that brings their score to or above the target score. The first player to reach or exceed the target wins — no overshoot, no double requirement.

The game ends immediately when a winner is detected. The Results screen shows "Champion of the Arena."

## Edge Cases and Special Rules

- **Skip Turn with 0 darts:** Allowed; turn total is 0, score unchanged, knockoff check still runs (nothing can match if score didn't change)
- **Speed Play + Double Finish:** If the timer expires after the player threw a winning dart, the already-thrown darts are processed normally including victory detection
- **Shield Round + Double Finish:** A win during a Shield Round ends the game normally; the Shield Round only blocks knockoffs, not victories
- **Multiple knockoffs in one turn:** If the active player's new score matches two opponents simultaneously, both are knocked off
- **Edit Score:** Accessible only through the RemoveDartsModal's "Edit player score" button; after editing, the knockoff check is re-evaluated with the new score

## Strategy Tips

- **Aim for 20s and trebles early** to build a comfortable lead before opponents cluster near your score
- **With Double Finish ON, plan your approach** when within 40 points of the target — the "Double Range!" indicator appears to help
- **Watch opponents' scores:** intentionally avoid landing on a value that matches a strong opponent's score to deny them a knockoff
- **Shield Rounds** provide breathing room — use them to pile on points without fear of being knocked back
- **Beginners:** Turn off Double Finish and set Target Score near 100–150 for shorter, less frustrating games
