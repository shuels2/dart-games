# Reef Royale — Assets

## Asset Location

`assets/games/reef_royale/`

## Asset Summary

| Category | Count | Description |
|----------|-------|-------------|
| Characters | 8 | Sea creature images |
| Corals | 14 | 7 coral types × 2 states (claimed/unclaimed) |
| Icons | 1 | Game icon |
| Images | 1 | Background |
| Sounds | 8 | Native sound effects |
| **Total** | **32** | |

## Characters

8 unique sea creatures, one assigned per player:

| Creature | File |
|----------|------|
| Coral Clownfish | `characters/CoralClownfish.png` |
| Shelly Turtle | `characters/ShellyTurtle.png` |
| Jet Octopus | `characters/JetOctopus.png` |
| Bubbles Seahorse | `characters/BubblesSeahorse.png` |
| Spike Pufferfish | `characters/SpikePufferfish.png` |
| Pearl Jellyfish | `characters/PearlJellyfish.png` |
| Captain Crab | `characters/CaptainCrab.png` |
| Finn Dolphin | `characters/FinnDolphin.png` |

## Corals

7 coral types, each with claimed and unclaimed states:

| Coral | Target | Claimed | Unclaimed |
|-------|--------|---------|-----------|
| Fire Coral | 20 | `corals/FireCoral-Claimed.png` | `corals/FireCoral-Unclaimed.png` |
| Brain Coral | 19 | `corals/BrainCoral-Claimed.png` | `corals/BrainCoral-Unclaimed.png` |
| Fan Coral | 18 | `corals/FanCoral-Claimed.png` | `corals/FanCoral-Unclaimed.png` |
| Staghorn Coral | 17 | `corals/StaghornCoral-Claimed.png` | `corals/StaghornCoral-Unclaimed.png` |
| Mushroom Coral | 16 | `corals/MushroomCoral-Claimed.png` | `corals/MushroomCoral-Unclaimed.png` |
| Tube Coral | 15 | `corals/TubeCoral-Claimed.png` | `corals/TubeCoral-Unclaimed.png` |
| Pearl Oyster | Bull | `corals/PearlOyster-Claimed.png` | `corals/PearlOyster-Unclaimed.png` |

## Icons

| File | Usage |
|------|-------|
| `icons/ReefRoyale-Icon.png` | Game selection menu icon |

## Images

| File | Usage |
|------|-------|
| `images/ReefRoyale-Background.png` | Menu screen background |

## Sounds

| File | Usage | Trim |
|------|-------|------|
| `sounds/ReefRoyale-Bell.mp3` | Turn change | 0–1.0s |
| `sounds/ReefRoyale-BubblePop.mp3` | Single mark | 0–0.25s |
| `sounds/ReefRoyale-Chime.mp3` | Coral bloom (claim) | Full |
| `sounds/ReefRoyale-ChimeScore.mp3` | Pearl scoring | Full |
| `sounds/ReefRoyale-Fanfare.mp3` | Victory | 5.8–8.9s |
| `sounds/ReefRoyale-Lock.mp3` | Reef locked | 11.0–14.25s |
| `sounds/ReefRoyale-RushingWater.mp3` | Buff activation | 0–3.0s |
| `sounds/ReefRoyale-Splash.mp3` | Miss / non-target | Full |

## Asset Usage in Code

```dart
// Character images
Image.asset('assets/games/reef_royale/characters/CoralClownfish.png');

// Coral images (via model helper)
game.getCoralImagePath(target, isClaimed); // returns claimed/unclaimed path

// Sound effects (via announcement helper)
ReefRoyaleSoundEffects.bubblePop // SoundEffectConfig with path and trim
```
