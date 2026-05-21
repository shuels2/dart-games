# Tiki Golf - Game Rules

## Objective

Be the player (Solo) or team (Team mode) with the **lowest total stroke count** across all 9 holes. Like real golf, lower is better. Sink the dartboard target number on your first dart for a birdie (1 stroke); take more darts to mean more strokes. Miss every dart? That's a Splash — the worst possible score for the hole.

## Setup

- **Players:** Solo mode: 2-4 individual players. Team mode: 3-16 players split into 2-4 teams of 1-4 players each.
- **Starting Conditions:** At game start, two random shuffles occur and are locked for the duration:
  1. `holeTargets` — 9 distinct numbers picked at random from 1-20 and assigned one per hole. Each hole gets a unique target number.
  2. `holeImagePaths` — The 9 hole-theme images (Volcano, Waterfall, Tiki Statue, Palm Tree, Lagoon, Shipwreck, Bamboo Temple, Coral Reef, Sunset Pier) are shuffled into the 9 hole slots. The displayed hole name follows the assigned image, not a fixed order.
- **Configuration Options:** Max Darts (3/4/5/6, default 3), Game Mode (Solo/Team), Team Assignment (Random/Manual), Mulligan (ON/OFF, default OFF)

## How to Play

### Turn Structure

1. **Hole announced** — The hole number, its randomly-assigned target number, and its randomly-assigned themed image are displayed. Announcement: "Hole {X}: Aim for number {N}!" with Tiki Chime.
2. **Player throws darts** — The active player throws up to Max Darts darts at the hole's target number. The dartboard emulator shows N slots (where N = Max Darts).
3. **Turn ends on first hit OR all darts exhausted OR Skip Turn**:
   - **(a) Target hit** — Dart N (1 ≤ N ≤ Max Darts) hits the hole's number → stroke count = N → turn ends immediately. Remaining darts are NOT thrown.
   - **(b) All darts missed** — All Max Darts thrown without hitting target → stroke count = Max Darts + 1 (Splash) → turn ends.
   - **(c) Skip Turn** — Player taps SKIP TURN at any point → remaining darts treated as misses → Splash recorded → turn ends.
4. **Remove darts prompt** — `RemoveDartsModal` fires ONLY when `currentTurnEnded == true` (turn-end condition met) OR `hasWinner == true`. Mid-turn (dart 2 of 5 with no hit and more darts remaining) the modal does NOT pop. This is different from every other game in the codebase.
5. **Mulligan check (optional)** — If Mulligan is ON AND the turn ended as a Splash AND the player has not yet used their mulligan this game: the `RemoveDartsModal` renders with two buttons: **USE MULLIGAN** (Lagoon Blue) and **NEXT PLAYER** (Hibiscus Pink). Tapping USE MULLIGAN re-starts the turn with full Max Darts; tapping NEXT PLAYER records the Splash as final.
6. **Player advances** — After takeout completes (or mulligan declines), the next player in rotation takes their turn.

### Scoring

Stroke counts are the scores. A player's hole score is the number of the dart that hit the target. Lower is better.

| Strokes | Golf Term | When it happens |
|--------:|-----------|-----------------|
| **1** | Birdie | Hit target on dart 1 |
| **2** | Par | Hit target on dart 2 |
| **3** | Bogey | Hit target on dart 3 |
| **4** | Double Bogey | Hit target on dart 4 (only when Max Darts ≥ 4) — or missed all when Max Darts = 3 |
| **5** | Triple Bogey | Hit target on dart 5 (Max Darts ≥ 5) — or missed all when Max Darts = 4 |
| **6** | Quadruple Bogey | Hit target on dart 6 (Max Darts = 6) — or missed all when Max Darts = 5 |
| **7** | Quintuple Bogey ("Splash!") | Missed all 6 darts (Max Darts = 6 only) |

**Par is always 2 strokes** regardless of the Max Darts setting — par is the standard 2-dart benchmark.

**Worst case (Splash) = Max Darts + 1 strokes.** Examples by setting:
- Max Darts 3: worst case 4 strokes (Double Bogey)
- Max Darts 4: worst case 5 strokes (Triple Bogey)
- Max Darts 5: worst case 6 strokes (Quadruple Bogey)
- Max Darts 6: worst case 7 strokes (Quintuple Bogey / Splash)

### Per-Game Randomization

**Two things shuffle at each new game:**

1. **Target numbers** — 9 distinct numbers drawn at random from 1-20 (no duplicates) are assigned to holes 1-9. Hole 1 might target 14 this game and 7 next game. The "New Hole" announcement reads the actual random target: "Hole 3: Aim for number 14!"

2. **Hole images** — The 9 hole-theme images are shuffled into the 9 hole positions. The themed hole name displayed in the top bar follows the shuffled image assignment. Hole 3 might be the Sunset Pier image this game and the Shipwreck image next game.

Both shuffles are stored in the game model (`List<int> holeTargets`, `List<String> holeImagePaths`) and locked for the game's duration. Save/resume restores the same shuffles, so a resumed game plays the same course.

## Game Modes

### Solo Mode (2-4 players)

Every player plays every hole. Players take turns in selection order. After all players complete a hole, the next hole begins. Running totals are shown per player. The player with the lowest total stroke count after 9 holes wins.

**Turn order (Solo, 3 players A, B, C):**
```
Hole 1: A → B → C → [next hole]
Hole 2: A → B → C → [next hole]
...
Hole 9: A → B → C → [game over]
```

### Team Mode (3-16 players, 2-4 teams)

Every player on every team plays every hole (real golf format). **Within a hole, each team plays through its full roster before handing off to the next team.**

**Within-hole turn order (4 teams A, B, C, D with rosters of varying sizes):**
```
Team A:  A_P1 → A_P2 → A_P3 → A_P4    (all team A players in roster order)
Team B:  B_P1 → B_P2 → B_P3 → B_P4    (all team B players)
Team C:  C_P1 → C_P2 → C_P3 → C_P4    (all team C players)
Team D:  D_P1 → D_P2 → D_P3 → D_P4    (all team D players)
HOLE COMPLETE — advance to next hole, reset within-hole counters
```

**Best-ball scoring:** Each team's hole score = MIN of all its players' scores on that hole. The team total across 9 holes = sum of each hole's best score. Other players' scores are recorded for stats but don't add to the team total.

**Team assignment options:**
- **Random** — Players are shuffled and dealt into auto-derived team count/sizes. The Team Count dropdown is hidden; team count is computed from the selected player count using the distribution table below.
- **Manual** — Player selects team per player via trailing icon on each player tile. Team Count dropdown (2/3/4, default 4) appears in the Game Mode box.

**Random team distribution table (authoritative):**

| Players | Teams | Sizes |
|--------:|------:|-------|
| 3 | 2 | [2, 1] |
| 4 | 2 | [2, 2] |
| 5 | 3 | [2, 2, 1] |
| 6 | 3 | [2, 2, 2] |
| 7 | 4 | [2, 2, 2, 1] |
| 8 | 2 | [4, 4] |
| 9 | 3 | [3, 3, 3] |
| 10 | 3 | [4, 3, 3] |
| 11 | 3 | [4, 4, 3] |
| 12 | 4 | [3, 3, 3, 3] |
| 13 | 4 | [4, 3, 3, 3] |
| 14 | 4 | [4, 4, 3, 3] |
| 15 | 4 | [4, 4, 4, 3] |
| 16 | 4 | [4, 4, 4, 4] |

Note: N=8 is a special case — a naive pair-fill would give [2,2,2,2] (4 teams), but the spec specifies [4,4] (2 teams). N=12 is also a special case: the spec gives 4 teams of 3, not 3 teams of 4. The implementation hard-codes these rules.

**Team logos:** At game start, 4 logos are randomly picked from the 6 available crests (Sharks, Sea Turtles, Hibiscus, Volcanoes, Coconuts, Parrots) and assigned to teams 1-N.

## Win Conditions

### Solo Mode
1. Players with the **lowest total stroke count** after 9 holes win
2. **Ties stand:** if multiple players finish on the same lowest total, all of them are tied champions. The results screen shows every tied player and every tied player receives a Win in their stats.
3. `winnerIds` lists every tied player in turn order; `winnerId` is the first tied player (legacy single-winner reference).
4. Birdie / bogey counts are shown on the scorecard for context but do **not** break ties.

### Team Mode
1. Teams with the **lowest combined team total** (sum of best-ball hole scores) after 9 holes win
2. **Ties stand:** if multiple teams finish on the same lowest team total, all of them are tied champions. The results screen shows every tied team's crest, and every player on every tied team receives a Win.
3. `winnerTeamIds` lists every tied team in turn order; `winnerTeamId` is the first tied team (legacy single-winner reference).
4. Team-birdie / team-bogey counts are shown for context but do **not** break ties.

## Special Mechanics

### Mulligan

When Mulligan is ON, each player has one free re-throw per game (per-player resource, not per-team). It is available only when that player's hole result was a Splash (maximum stroke count for the current Max Darts setting).

**Mulligan activation flow:**
1. Player takes all Max Darts without hitting target → Splash → `currentTurnEnded = true`
2. Provider checks: Mulligan setting ON AND `playerMulliganAvailable[playerId] == true` AND score == Splash threshold
3. `RemoveDartsModal` renders with two buttons: USE MULLIGAN (Lagoon Blue, tiki mask icon) and NEXT PLAYER (Hibiscus Pink)
4. **USE MULLIGAN** → `useMulligan(playerId)`: clears the hole score, marks mulligan as used, resets `dartsThrown[playerId] = 0`, clears `currentTurnEnded` → player throws another full round of Max Darts
5. **NEXT PLAYER** → `confirmTurnEnd(playerId)`: Splash recorded as final → advance to next player
6. Mulligan is used at most once per player per game. In Team mode, each player on a team has their own individual mulligan.

**In-game UI (when Mulligan ON):** A tiki mask button labeled "Mulligan" with "1x" badge appears in the Dart Row above the scorecard. The button is disabled (50% opacity) at game start; it becomes enabled only after a Splash AND mulligan still available. After use, the button disappears.

### Skip Turn

SKIP TURN button always appears on the game screen. Tapping it at any point during a player's turn treats all remaining darts as misses and records a Splash for the hole. This counts as a Mulligan-eligible result if Mulligan is ON and the player hasn't used theirs.

### Per-Player Turn-End Detection

`shouldPromptTakeout = currentTurnEnded || hasWinner`

The provider's `currentTurnEnded` flag toggles to `true` on any of three turn-end conditions (target hit, all darts missed, Skip Turn) and resets to `false` after `confirmTurnEnd` completes. Mid-turn (e.g., dart 2 of 5 with no hit and more darts remaining), the flag stays `false` and the Remove Darts modal does NOT appear.

## Edge Cases and Special Rules

- **Solo mode cap:** 4 players maximum. The `TeamPlayerListPanel` header shows `(N/4 selected)` in Solo mode.
- **Team mode minimum:** 3 players. Team Count = 2 with 3 players gives [2,1] — the smallest valid "real teams" configuration with at least one true team of ≥2.
- **Empty teams:** If a player count + team count combination would leave a team empty, the TEE OFF button stays disabled.
- **Mulligan + Team mode:** Each player on a team has their own individual mulligan. Multiple players on the same team can each use their mulligan on the same hole if they all splashed.
- **Save/resume preserves shuffles:** The `holeTargets` and `holeImagePaths` arrays are serialized to JSON; a resumed game restores the exact same course layout.
- **`totalTurns` increment:** `totalTurns[playerId]` increments exactly once per turn at the moment dart 1 is thrown (`if (game.dartsThrown[playerId] == 1) { ... }`). The variable Max Darts setting does NOT alter this rule.
- **Hole names from images:** The displayed hole name follows the shuffled `holeImagePaths` assignment, not a fixed hole-name list. If hole 3's image is the Sunset Pier image, the displayed name is "Sunset Pier."

## Strategy Tips

- **Save your mulligan** for a hole where all your teammates also splashed — on other holes a teammate's birdie covers for you.
- **More Max Darts = more chances but slower play.** Max Darts 3 is fast and tense; Max Darts 6 is forgiving and longer.
- **In Team mode,** watch whether your team already has a birdie before using your mulligan — if a teammate hit the target on dart 1, your Splash doesn't matter to the team score anyway.
