# Lunar Lander - Game Rules

## Objective

Be the first astronaut to descend from orbit and land on the moon by reducing your altitude to exactly zero (or below zero when Hard Landing is disabled).

## Setup

- **Players:** 2-8 players (no team mode — individual play only)
- **Starting Conditions:** All players start at the configured Starting Altitude (default 200). Characters are randomly assigned from the pool of 8 astronaut animals at game start.
- **Configuration Options:**
  - Starting Altitude: slider 100-500 in increments of 10 (default 200)
  - Hard Landing: toggle ON/OFF (default OFF)

## How to Play

### Turn Structure

1. The active player throws up to 3 darts at the dartboard
2. Each dart's score is subtracted from the player's current altitude
3. After each dart, the altitude readout and descent track rocket position update immediately
4. If the altitude reaches 0 or goes below 0 (with Hard Landing OFF), the player wins immediately — remaining darts are not thrown
5. After 3 darts (or a bust with Hard Landing ON, or a win), the Remove Darts prompt appears and the turn advances to the next player

### Scoring/Progress

Each dart scores as follows:

| Dart Type | Score |
|-----------|-------|
| Single | Face value (1-20) |
| Double | Face value x 2 (2-40) |
| Triple | Face value x 3 (3-60) |
| Outer Bull | 25 |
| Inner Bull | 50 |
| Miss (score 0) | 0 (no change to altitude) |

All numbers count — there are no wasted throws in Lunar Lander. Even low-value darts advance the player toward the moon.

The descent track visualizes each player's progress: a rocket icon moves down a vertical track proportionally as altitude decreases. At starting altitude the rocket is at the top (ORBIT); at altitude 0 it reaches the bottom (MOON).

### Special Mechanics

#### Hard Landing OFF (Default)

When Hard Landing is disabled, altitude can go below zero. Any result of 0 or less wins the game immediately. The announcement is "Touchdown!" regardless of whether the landing was exact or an overshoot. This is the recommended setting for beginners and family play.

#### Hard Landing ON

When Hard Landing is enabled, going below 0 is a "Crash Landing" (bust):
- The turn is voided immediately
- The player's altitude reverts to their start-of-turn altitude
- Remaining darts in the turn are forfeited
- A crash animation plays (rocket shake + small explosion puff, rocket pulls back up)
- A "CRASH!" text overlay flashes in Thruster Red
- A "HARD LANDING" badge is displayed in the top bar area throughout the game

With Hard Landing ON, a player must reach exactly 0 to win.

#### Skip Turn

The active player may tap "Skip Turn" at any time to forfeit remaining darts and advance to the next player. The turn summary still records any darts already thrown that turn.

#### Edit Score

After 3 darts are thrown, the Remove Darts Modal includes an "Edit player score" button. This opens the EditScoreDialog allowing any of the 3 dart values to be corrected. The altitude is recalculated from the start-of-turn altitude using the corrected dart values, and all game rules (bust, win condition) are re-evaluated.

## Win Conditions

A player wins when their altitude reaches 0 or below:

| Hard Landing Setting | Altitude Result | Outcome |
|---------------------|-----------------|---------|
| OFF (default) | Exactly 0 | Touchdown - Win! |
| OFF (default) | Below 0 (negative) | Touchdown - Win! |
| ON | Exactly 0 | Touchdown - Win! |
| ON | Below 0 (negative) | Crash Landing - Bust (altitude reverts, continue playing) |

## Edge Cases and Special Rules

- **Exact 0 mid-turn:** If a dart brings altitude to exactly 0, the player wins immediately. Remaining darts in that turn are not thrown.
- **Negative altitude with Hard Landing OFF:** The player wins even if altitude is -5 or -50. The game ends on the first dart that brings altitude to 0 or below.
- **Miss (score 0):** A dart scoring 0 does not change altitude. The dart indicator shows "0" with Moon Dust Gray fill. The game continues to the next dart.
- **Multiple players at 0 in the same round:** The player who lands first (earlier in turn order) wins. Once a winner is declared the game ends.
- **Altitude readout when negative (Hard Landing OFF):** Displayed in Thruster Red color to indicate the overshoot state.

## Strategy Tips

- **Hard Landing OFF:** The most relaxed mode. Aim for high-scoring areas; any path to or past zero wins.
- **Hard Landing ON:** Think backwards from 0. What doubles or singles can reach exactly 0 from your current altitude? Keep track of common checkout combinations.
- **Lower starting altitude (100):** Games finish faster — great for younger players or quick rounds.
- **Higher starting altitude (500):** Longer games with more strategic play and more turns.
