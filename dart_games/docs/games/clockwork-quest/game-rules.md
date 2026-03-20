# Clockwork Quest - Game Rules

## Overview

Clockwork Quest is a sequential dart progression game where players race through numbered gears 1-20 (or 1-21 with bullseye) in order. Hit your current target to advance to the next gear. The first player to complete all gears (and required laps) wins the Clockwork Crown!

## Setup

### Player Count
- **2-8 players**
- Uses DualPlayerListPanel (no teams)

### Game Options

| Option | Values | Effect |
|--------|--------|--------|
| **Include Bullseye** | ON/OFF | When ON, gear 21 (bullseye) becomes the final target after gear 20 |
| **D/T Count** | ON/OFF | When ON, doubles count as 2 advances, triples as 3 advances. When OFF, only singles count |
| **Speed Mode** | ON/OFF | When ON, players get 2 darts per turn instead of 3 |
| **Number of Laps** | 1-5 | Players must complete the full circuit this many times to win |

## Gameplay

### Turn Structure

1. **Player's Turn:** Player throws 3 darts (or 2 in Speed Mode)
2. **Dart Processing:** Each dart is checked against the player's current target
3. **Target Advancement:** When a dart hits the current target, player advances to next gear
4. **Turn End:** After all darts are thrown, next player's turn begins

### Target Progression

**Standard Mode (Bullseye OFF):**
- Players start at gear 1
- Must hit gears 1 → 2 → 3 → ... → 20 in order
- Each successful hit advances to the next gear
- Misses and wrong numbers do not advance

**Bullseye Mode (Bullseye ON):**
- Players start at gear 1
- Must hit gears 1 → 2 → 3 → ... → 20 → 21 (bullseye)
- Gear 21 is the bullseye target only
- All other rules apply

### D/T Count Option

**When OFF (default):**
- Only singles count
- Hitting S5 when on gear 5 = advance 1 gear (to gear 6)
- Hitting D5 when on gear 5 = advance 1 gear (to gear 6)
- Hitting T5 when on gear 5 = advance 1 gear (to gear 6)

**When ON:**
- Singles advance 1 gear
- Doubles advance 2 gears
- Triples advance 3 gears
- Example: Hitting T5 when on gear 5 = advance 3 gears (to gear 8)

### Multiple Laps

When Number of Laps is set to 2 or more:
- Players must complete the full circuit (1-20 or 1-21) multiple times
- After completing the final gear, player loops back to gear 1
- Lap counter increments
- Player wins when they complete the required number of laps

Example with 3 laps:
- Complete gears 1-20, lap 1 done, return to gear 1
- Complete gears 1-20, lap 2 done, return to gear 1
- Complete gears 1-20, lap 3 done, **GAME WON**

## Win Conditions

A player wins when they complete the **final target of the final lap**.

**Standard, 1 lap:** First to hit gear 20
**Bullseye, 1 lap:** First to hit gear 21 (bullseye)
**Standard, 3 laps:** First to hit gear 20 on lap 3
**Bullseye, 2 laps:** First to hit gear 21 (bullseye) on lap 2

## Dart Processing Logic

```
For each dart thrown:
  1. Check if dart hit equals player's current target
     - Gear 1-20: dart number must match target number
     - Gear 21: dart must be bullseye

  2. If match:
     a. If D/T Count OFF:
        - Advance 1 gear (regardless of multiplier)

     b. If D/T Count ON:
        - Single: Advance 1 gear
        - Double: Advance 2 gears
        - Triple: Advance 3 gears

     c. If advanced past final gear (20 or 21):
        - Increment lap counter
        - If lap counter >= numberOfLaps: PLAYER WINS
        - Else: Reset to gear 1, continue

  3. If no match:
     - No advancement, continue to next dart
```

## Scoring & Results

**Rankings:**
Players are ranked by:
1. **Winner** (if any) always rank 1
2. **Progress:** Further along = higher rank
   - Lap 2, Gear 15 > Lap 1, Gear 19
   - Gear 15 > Gear 10
3. **Ties:** Players tied on same gear/lap share rank

**Results Screen:**
- Winner name displayed prominently
- All players shown with:
  - Rank
  - Current gear (or "COMPLETE" for winner)
  - Current lap (if numberOfLaps > 1)

## Strategy Tips

- **Speed Mode:** Fewer darts means less margin for error, but faster games
- **D/T Count ON:** Skilled players can skip ahead with doubles/triples
- **Multiple Laps:** Tests consistency across multiple circuits
- **Bullseye Mode:** Adds one more precision challenge at the end
