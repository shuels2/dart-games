# Reef Royale — Announcements

## Announcement Helper

**Class:** `ReefRoyaleAnnouncementHelper` in `lib/services/reef_royale_announcement_helper.dart`

## Announcement Methods

### Game Events
| Method | Priority | Description |
|--------|----------|-------------|
| `announceGameStart()` | victory (5) | Game begins |
| `announceRandomReefs(targets)` | statusChange (4) | Random target numbers chosen |
| `announceTurn(playerName)` | turnTransition (1) | Player turn begins |
| `announceRemoveDarts()` | turnTransition (1) | Remove darts prompt |

### Dart Events (max 2 announcements per dart)
| Method | Priority | Description |
|--------|----------|-------------|
| `announceMark(coralName)` | hitConfirm (2) | Single mark on target |
| `announceDoubleMark(coralName)` | hitConfirm (2) | Double hit on target |
| `announceTripleMark(coralName)` | hitConfirm (2) | Triple hit on target |
| `announceNeighborMark(coralName)` | hitConfirm (2) | Neighbor number hit |
| `announceCoralClaimed(coralName)` | statusChange (4) | Coral blooms (claimed) |
| `announceReefLocked(coralName)` | statusChange (4) | All players claimed — locked |
| `announcePearlsScored(amount)` | hitConfirm (2) | Pearls scored (standard) |
| `announceCursedPearls(amount, recipientName)` | hitConfirm (2) | Pearls given to opponent (Cursed Tide) |
| `announceMiss()` | hitConfirm (2) | Non-target or miss |

### Buff Events
| Method | Priority | Description |
|--------|----------|-------------|
| `announceBuff(buff)` | statusChange (4) | Buff activated for round |

### Win Events
| Method | Priority | Description |
|--------|----------|-------------|
| `announceNearVictory(playerName)` | statusChange (4) | Player has 6/7 corals |
| `announceWinner(playerName)` | victory (5) | Game winner declared |

## Sound Effects

**Class:** `ReefRoyaleSoundEffects` in `lib/services/reef_royale_sound_effects.dart`

| Sound | Asset | Timing | Usage |
|-------|-------|--------|-------|
| Bubble Pop | `ReefRoyale-BubblePop.mp3` | 0–0.25s | Single mark |
| Double Bubble | `ReefRoyale-BubblePop.mp3` | 0–0.65s | Double/triple mark |
| Coral Bloom | `ReefRoyale-Chime.mp3` | Full | Coral claimed |
| Pearl Chime | `ReefRoyale-ChimeScore.mp3` | Full | Pearls scored |
| Splash | `ReefRoyale-Splash.mp3` | Full | Miss |
| Current Whoosh | `ReefRoyale-RushingWater.mp3` | 0–3.0s | Buff activation |
| Victory Fanfare | `ReefRoyale-Fanfare.mp3` | 5.8–8.9s | Game winner |
| Turn Bell | `ReefRoyale-Bell.mp3` | 0–1.0s | Turn change |
| Reef Lock | `ReefRoyale-Lock.mp3` | 11.0–14.25s | Target locked |

## Priority Levels

1. **turnTransition (1)** — Turn changes, remove darts
2. **hitConfirm (2)** — Dart hit results, pearl scoring
3. **shieldStatus (3)** — (Reserved)
4. **statusChange (4)** — Coral claims, locks, buffs, near victory
5. **victory (5)** — Game start, winner

Higher priority announcements interrupt lower priority ones. Max 2 announcements per dart throw.
