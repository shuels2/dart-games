# Monster Mash - Game Rules

## Objective
Be the last monster standing by managing your health, healing with your target number, and attacking opponents!

Monster Mash is an HP-based elimination game where each player is assigned a random classic monster and a target number (1-20). Hit your own target to heal, hit opponents' targets to deal damage, and survive to the end. Optional bonus buffs and speed play add strategic depth.

## Setup
- **Players:** 2-8 players
- **Starting Conditions:** All players start at configurable max HP (10-50, default 20)
- **Configuration Options:**
  - **Health Points:** 10-50 max HP (slider, default: 20)
  - **Bonus Buffs:** Optional buff system (on/off toggle)
  - **Speed Play:** Optional round limit mode (on/off toggle)
  - **Round Limit:** 3-20 rounds when Speed Play enabled (slider, default: 10)

## How to Play

### Turn Structure
1. **Turn Start** - Current player's name is announced
2. **Throw Darts** - Player throws up to 3 darts on the dartboard
3. **Process Hits** - Each dart heals, damages opponents, or has no effect
4. **Status Updates** - Announcements for health warnings, eliminations, special events
5. **Turn End** - After 3 darts (or skip), remove darts prompt
6. **Repeat** - Continue until win condition met

### Dart Outcomes

| Dart Hit | Result | Effect |
|----------|--------|--------|
| Own target (single) | Heal | +1 HP |
| Own target (double) | Heal | +2 HP |
| Own target (triple) | Heal | +3 HP |
| Bullseye (50) | Full Heal | Restore to max HP |
| Outer Bull (25) | Heal | +5 HP |
| Opponent's target (single) | Damage | -1 HP to opponent |
| Opponent's target (double) | Damage | -2 HP to opponent |
| Opponent's target (triple) | Damage | -3 HP to opponent |
| Eliminated player's target | No effect | Nothing happens |
| Unassigned number | No effect | Nothing happens |
| Miss | No effect | Nothing happens |

### Elimination
- When a player's HP reaches 0, they are **eliminated**
- Eliminated players are removed from the turn order
- Their target number becomes inactive (hitting it has no effect)

## Bonus Buffs

When enabled, buffs have a ~33% chance to activate at the start of each round. Only one buff is active at a time, and it applies to all players during that round.

### Blood Moon
- **Effect:** Attack damage is doubled
- **Display:** Red shield with "+2x" on damage indicator
- **Impact:** Single hits deal 2 damage, doubles deal 4, triples deal 6

### Ancient Bandages
- **Effect:** All healing is fixed at +5 HP regardless of multiplier
- **Display:** Green shield with "+5" on heal indicator
- **Impact:** Single/double/triple all heal for 5 HP

### Shadow Walk
- **Effect:** All attacks deal 0 damage
- **Display:** Purple shield with "0" on damage indicator
- **Impact:** Defensive round - no player can be damaged or eliminated

### Laboratory Spark
- **Effect:** Bullseye also zaps all opponents for -10 HP
- **Display:** Yellow shield with "10" on damage indicator
- **Impact:** Bullseye heals fully AND damages every opponent by 10

## Speed Play

When enabled, the game has a round limit. When the limit is reached:

1. **Single Winner:** Player with highest HP wins
2. **Tiebreak:** If HP is tied, player with most total damage dealt wins
3. **True Tie:** If both HP and damage are tied, multiple winners are declared

## Special Mechanics

### Hat Trick
- Triggered when all 3 darts in a turn hit the same opponent's target
- Special announcement: "MONSTROUS! Triple strike on [name]!"
- Special sound effect plays

### Clutch Heal
- Triggered when a player heals while below 10 HP
- Special announcement: "[name] rises from near death!"
- Special sound effect plays

### Skip Turn
- Press "Skip Turn" button to skip remaining darts
- Remaining dart slots filled with skip markers
- Turn advances to remove darts phase

### Edit Score
- Press "Edit Score" button during turn
- Adjust all 3 dart scores using ring/number picker
- Game state recalculates from turn start snapshot
- Can undo eliminations if edited darts no longer cause them

## Win Conditions

### Standard Mode (No Speed Play)
- **Last monster standing wins**
- Game ends when only 1 non-eliminated player remains

### Speed Play Mode
- **Round limit reached** - Highest HP wins
- **Last monster standing** - If all but one eliminated before round limit
- **Tiebreak:** HP first, then total damage dealt
- **Multiple winners possible** if both HP and damage are tied

## Edge Cases and Special Rules
- **Healing at max HP:** Excess healing has no effect (HP capped at max)
- **Bullseye during Lab Spark:** Full heal self AND -10 to all opponents
- **Shadow Walk + attacks:** Attacks still register as dart hits but deal 0 damage
- **Blood Moon + healing:** Blood Moon only affects damage, not healing
- **Ancient Bandages + bullseye:** Bullseye still heals to full (not capped at +5)
- **Edit Score after elimination:** Can revive players if edited darts undo lethal damage
- **Monster assignment:** 8 monsters randomly assigned, max 8 players
- **Target numbers:** Unique per player, randomly assigned from 1-20
