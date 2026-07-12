# Treasure Divide - Game Rules

## Objective

Accumulate the most gold (score) after all rounds complete by hitting each round's target number on the dartboard. But beware — miss all your darts in a round and HALF your treasure spills overboard! The player (or crew) with the highest total after all rounds is crowned Pirate Captain.

## Setup

- **Players:** Solo: 2-8 individual pirates; Team: 3-10 players in doubles crews of 2 (up to 5 crews)
- **Starting Conditions:** All players start with 0 gold. The target sequence is fixed (or randomized if Custom Targets ON). The first round target is displayed on the treasure map.
- **Configuration Options:** Number of Rounds (7/9/12), Quarter It (ON/OFF), Custom Targets (ON/OFF), Game Mode (Solo/Team), Team Assignment (Random/Manual)

## How to Play

### Turn Structure

1. The active player's name and current target are displayed (Active Player Panel on the left; treasure map in the center)
2. The player throws up to 3 darts at the current round's target (6 darts for a Solo crew player in Team mode)
3. Each dart that hits the target scores face value × multiplier (Single = 1×, Double = 2×, Triple = 3×); each miss scores 0
4. After all darts are thrown (or Skip Turn is tapped), the turn ends:
   - **At least 1 dart hit:** round haul is added to the player's (or crew's) running total — "SAFE!"
   - **All darts missed:** running total is halved (÷2 with Quarter It OFF, ÷4 with Quarter It ON) — "HALVED!" or "QUARTERED!"
5. Play passes to the next player/crew. After all players complete a round, the next round begins.

### Scoring

Scores are computed by hitting the round's specific target:

| Round target | What counts | Score per hit |
|---|---|---|
| Number (e.g., 20) | Any segment of that number | face value × multiplier |
| Any Double | Any double segment | face value × 2 |
| Any Triple | Any triple segment | face value × 3 |
| Bull | Outer bull or inner bull | 25 or 50 |

Halved/quartered totals are **floored** (integer division, round down). A total of 0 stays 0.

### Halving on Whiff

If a player misses ALL darts in a round (no dart hits the current target):
- **Quarter It OFF:** `total = floor(total / 2)` — "Treasure overboard! Half the loot is gone!"
- **Quarter It ON:** `total = floor(total / 4)` — "A storm hits! Three-quarters of the treasure is lost!"

Hitting the target even once (for any score) prevents halving entirely.

## Target Sequences

### Standard 9-Round Sequence (default)

| Round | Target |
|-------|--------|
| 1 | 20 |
| 2 | 19 |
| 3 | 18 |
| 4 | Any Double |
| 5 | 17 |
| 6 | 16 |
| 7 | 15 |
| 8 | Any Triple |
| 9 | Bull |

### Short 7-Round Sequence

Rounds: 20, 19, 18, Any Double, 17, Any Triple, Bull

### Long 12-Round Sequence

Rounds: 20, 19, 18, Any Double, 17, 16, 15, Any Triple, 14, 13, 12, Bull

### Sentinel Targets

Three special target constants are used in the model to represent non-numeric rounds:
- `kTargetAnyDouble` — "Any Double" round (any double segment on any number)
- `kTargetAnyTriple` — "Any Triple" round (any triple segment on any number)
- `kTargetBull` — "Bull" round (outer bull = 25, inner bull = 50)

### Custom Targets (when enabled)

- Random numbers 1–20 (no duplicates) replace the numeric rounds
- Any Double and Any Triple slots remain at their fixed positions (rounds 4 and 8 for 9 rounds; 4 and 6 for 7 rounds; 4, 8, and 11 for 12 rounds)
- Bull is always the final round
- Future island numbers display "???" on the map until that round becomes active

## Game Modes

### Solo Mode (2-8 players)

Each selected pirate plays every round in selection order. Each player has their own independent treasure total. Hit the round target at least once → add the round haul. Miss all 3 darts → halve (or quarter) own total. Highest total after all rounds wins.

**Turn order example (3 players A, B, C):**
```
Round 1: A → B → C → [next round]
Round 2: A → B → C → [next round]
...
```

### Team Mode (2-5 crews of 2 — 3-10 players)

Treasure Divide's team mode is a **doubles format**: crews of 2 players each, up to 5 crews. An odd player forms a single 1-player **solo crew** (see Solo Crew Fairness Rule).

**Turn order within a round (each crew plays through before handing off):**
```
Crew A: A_P1 (3 darts) → A_P2 (3 darts)   [both members, then hand off]
Crew B: B_P1 (3 darts) → B_P2 (3 darts)
Crew C: C_P1 (6 darts — SOLO CREW, single turn)
[ROUND COMPLETE — aggregate + advance]
```

**Score aggregation:** The crew's round gain is the **SUM** of all members' hauls. A teammate who whiffs contributes 0 but does NOT trigger halving for the crew.

**Crew-wide halving:** The crew's shared treasure is halved (or quartered) **only when EVERY dart of EVERY member misses the target that round** (the whole crew comes up empty). If at least one dart from any member hits, the crew is safe.

**Examples (crew of 2, round target 20, Quarter It OFF):**

| P1 haul | P2 haul | Crew outcome |
|--------:|--------:|---|
| T20 = 60 | S20 = 20 | +80 banked (both hit) |
| T20 = 60 | miss all = 0 | +60 banked (P1 hit → crew SAFE; P2's whiff adds 0) |
| miss all = 0 | miss all = 0 | treasure HALVED (whole crew came up empty) |

#### Solo Crew Fairness Rule (6 Darts Per Turn)

A 1-player crew throws **6 darts in a single turn** instead of 3. This matches the combined throw count of a paired crew:
- The solo player throws all 6 darts contiguously — no extra crew-turn announcement between dart 3 and 4
- Crew round haul = sum of all 6 darts (same SUM aggregation as a paired crew)
- Crew is halved/quartered **only when all 6 darts miss the target** — same threshold as a paired crew's whole-crew whiff
- Active Player Panel renders 6 dart indicator slots (instead of 3) while the solo crew player has the turn
- A "Solo Crew: 6 darts" badge appears in the badge row so the table knows this is the extended turn
- Skip Turn at any dart index (0–5) forfeits remaining darts; if zero darts hit, crew-wide halving applies

#### Team Assignment

- **Random (default):** Players are shuffled and dealt into auto-derived crews using `randomDistribution(N)`. No manual selection needed.
- **Manual:** User assigns each player to a crew via the per-player team-assign trailing icon. Team Count dropdown (2/3/4/5, default 2) appears in the Game Mode box. SET SAIL stays disabled until every configured crew has ≥1 player and no crew exceeds 2 players.

#### Random Team Distribution Table

| Selected players | Crew count | Sizes |
|---:|---:|---|
| 3 | 2 | [2, 1] |
| 4 | 2 | [2, 2] |
| 5 | 3 | [2, 2, 1] |
| 6 | 3 | [2, 2, 2] |
| 7 | 4 | [2, 2, 2, 1] |
| 8 | 4 | [2, 2, 2, 2] |
| 9 | 5 | [2, 2, 2, 2, 1] |
| 10 | 5 | [2, 2, 2, 2, 2] |

The lone odd-player solo crew is always last after the shuffle.

## Win Conditions

### Solo Mode

Highest total gold after all rounds wins. Tiebreaker 1: fewer times halved. Tiebreaker 2: first player in selection order.

### Team Mode

Crew with the highest combined treasure after all rounds wins. Tiebreaker 1: crew halved fewer times. Tiebreaker 2: crew with the higher single best-round haul. Tiebreaker 3: first crew in crew order.

**Player stats on team win:** Every player on the winning crew gets `won: true` recorded in their stats (Target Tag pattern). Losing-crew players get `won: false`.

## Edge Cases and Special Rules

- **Score of 0 halved:** stays 0 (floor of 0/2 = 0)
- **Score of 1 halved:** becomes 0 (floor of 1/2 = 0)
- **Multiple halvings accumulate correctly:** each round that whiffs applies floor division independently
- **Skip Turn with no hits:** counts as "miss all" — halving applies if this was the final dart opportunity
- **Edit Score can change halving outcome:** editing a dart to become a hit (or removing the only hit) re-evaluates whether halving fires for that round

## Strategy Tips

- **Protect high scores:** once you've accumulated a lot of gold, being halved is devastating. Don't aim too aggressively at difficult targets if you have a high score to protect.
- **Any Double / Any Triple rounds:** aim for the high-value doubles/triples (T20 = 60 on a Triple round is the maximum single-dart score).
- **Quarter It ON:** the stakes are much higher — losing 75% of your treasure in one bad round can be game-ending.
- **Team mode:** encourage your partner to aim at the target rather than the highest score, since even a single hit prevents crew halving.
