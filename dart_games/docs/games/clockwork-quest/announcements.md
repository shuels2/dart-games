# Clockwork Quest - Announcements

## Overview

Clockwork Quest uses the global `GameAnnouncementQueueService` to provide audio feedback throughout gameplay. All announcements follow the MAX 2 announcements per event rule.

## Announcement Priority

When multiple events occur simultaneously, announcements are triggered in this order:
1. Victory
2. Lap Complete
3. Gear Advancement (double/triple > single)
4. Miss

## Announcement Events

### 1. Game Start
**Trigger:** Game begins
**Text:** "Wind the gears! The quest begins!"
**Type:** `statusChange`
**Sound:** `gearSpin`

### 2. Player Turn
**Trigger:** New player's turn begins
**Text:** "[Player Name], your turn to tinker!"
**Type:** `turnTransition`
**Sound:** `turnBell`

### 3. Single Gear Activated
**Trigger:** Player hits current target (single advance)
**Text:** "Gear [N] turns! Onward!"
**Type:** `hitConfirm`
**Sound:** `gearClick`

### 4. Double Advance
**Trigger:** Player hits current target with double (D/T Count ON)
**Text:** "[Player Name] hits a double! Two gears turn!"
**Type:** `hitConfirm`
**Sound:** `gearSpin`

### 5. Triple Advance
**Trigger:** Player hits current target with triple (D/T Count ON)
**Text:** "[Player Name] hits a triple! Three gears turn!"
**Type:** `hitConfirm`
**Sound:** `gearSpin`

### 6. Miss
**Trigger:** Dart doesn't match current target
**Text:** "Steam vents! That's not the right gear!"
**Type:** `hitConfirm`
**Sound:** `steamHiss`

### 7. Bullseye Target Reached
**Trigger:** Player reaches gear 21 (bullseye mode)
**Text:** "One final gear! Hit the bullseye to crown the clock!"
**Type:** `statusChange`
**Sound:** `gearClick`

### 8. Bullseye Hit
**Trigger:** Player successfully hits bullseye
**Text:** "The crown gear turns! Magnificent!"
**Type:** `hitConfirm`
**Sound:** `clockChime`

### 9. Halfway Milestone
**Trigger:** Player reaches gear 10
**Text:** "[Player Name] is halfway! The clock is ticking!"
**Type:** `statusChange`
**Sound:** `gearSpin`

### 10. Near Victory
**Trigger:** Player reaches gear 18 or higher
**Text:** "[Player Name] is almost there! Just [N] gears left!"
**Type:** `statusChange`
**Sound:** `gearSpin`

### 11. Lap Complete
**Trigger:** Player completes all gears and starts new lap
**Text:** "Lap complete! Wind it again!"
**Type:** `statusChange`
**Sound:** `clockChime`

### 12. Speed Mode Time Expiry
**Trigger:** Turn timer expires in speed mode
**Text:** "Time's up! The gears wait for no one!"
**Type:** `statusChange`
**Sound:** `tickTock`

### 13. Victory
**Trigger:** Player completes final lap
**Text:** "All gears turn! [Winner Name] wins the Clockwork Crown!"
**Type:** `victory`
**Sound:** `victoryFanfare`

### 14. Remove Darts
**Trigger:** End of turn (3 darts thrown or speed mode 2 darts)
**Text:** "[Player Name], remove your darts!"
**Type:** `turnEnd`
**Sound:** None

## Sound Effects

All sound effects are defined in `lib/services/clockwork_quest_sound_effects.dart` and stored in `assets/games/clockwork_quest/sounds/`.

| Sound Effect | File | Usage |
|--------------|------|-------|
| `turnBell` | `turn_bell.mp3` | Player turn transitions |
| `clockChime` | `clock_chime.mp3` | Bullseye hit, lap complete |
| `victoryFanfare` | `victory_fanfare.mp3` | Game won |
| `gearClick` | `gear_click.mp3` | Single gear activation |
| `gearSpin` | `gear_spin.mp3` | Game start, double/triple, milestones |
| `steamHiss` | `steam_hiss.mp3` | Misses |
| `tickTock` | `tick_tock.mp3` | Speed mode time expiry |

## Sound Effect Characteristics

**Turn Bell:** Light metallic bell chime, warm and inviting
**Clock Chime:** Deep, resonant clocktower chime with brass reverb
**Victory Fanfare:** Triumphant brass fanfare with mechanical flourishes
**Gear Click:** Single crisp mechanical click, like a gear engaging
**Gear Spin:** Sustained mechanical whirring with brass undertones
**Steam Hiss:** Short pressurized steam release, not harsh
**Tick Tock:** Classic clockwork ticking, accelerating slightly

## Announcement Implementation

**File:** `lib/services/clockwork_quest_announcement_helper.dart`

### Key Methods

```dart
class ClockworkQuestAnnouncementHelper {
  final GameAnnouncementQueueService _queueService;

  // Game lifecycle
  void announceGameStart()
  void announcePlayerTurn(Player player)
  void announceRemoveDarts(Player player)

  // Dart hits
  void announceGearActivated(int gearNumber)
  void announceDoubleAdvance(Player player)
  void announceTripleAdvance(Player player)
  void announceMiss()

  // Bullseye mode
  void announceBullseyeTarget()
  void announceBullseyeHit()

  // Milestones
  void announceHalfway(Player player)
  void announceNearVictory(Player player, int gearsLeft)
  void announceLapComplete()

  // Special events
  void announceTimeExpiry()
  void announceVictory(Player winner)
}
```

## Integration with Provider

The `ClockworkQuestProvider` calls announcement methods at appropriate times:

**processDart():**
- Announces double/triple advance if D/T Count is ON
- Announces single gear activation otherwise
- Announces bullseye hit if gear 21
- Announces halfway/near victory milestones
- Announces lap complete on circuit completion
- Announces victory on game won

**newTurn():**
- Announces player turn at start of turn
- Announces remove darts at end of turn

**skipTurn():**
- Announces player turn for next player

## MAX 2 Announcements Rule

When multiple announcements could trigger (e.g., triple advance to gear 18):
1. Priority announcement: Triple Advance
2. Secondary announcement: Near Victory (if applicable)
3. All others suppressed

Example:
```dart
// Player hits T16 when on gear 16 (advances to 19)
announceTripleAdvance(player);  // Priority 1
announceNearVictory(player, 2); // Priority 2 (18+)
// Gear 17, 18, 19 individual activations: suppressed
```
