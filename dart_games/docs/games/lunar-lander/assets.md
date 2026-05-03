# Lunar Lander - Asset Inventory

## Asset Location
**Base Path:** `assets/games/lunar_lander/`

## Asset Summary
- **Icons:** 1 file
- **Images:** 1 file
- **Characters:** 8 files
- **Sounds:** 8 files
- **Total Assets:** 18 files

**Note:** All asset files use PascalCase naming (renamed during Phase 1 asset setup). The originals in `C:\Users\steve\Downloads\LunarLander\` used snake_case; the project copies are PascalCase.

## Icons

**Location:** `assets/games/lunar_lander/icons/`

### LunarLander-Icon.png
- **Size:** 512x512px
- **Format:** PNG (transparent background)
- **Usage:** Game selection card on home screen
- **Description:** Cute rounded cartoon rocket descending toward a friendly cartoon moon surface, retro NASA poster style. Warm-toned moon with gentle craters, stars in background.
- **Source:** `C:\Users\steve\Downloads\LunarLander\icon.png`

## Images

**Location:** `assets/games/lunar_lander/images/`

### LunarLander-Background.png
- **Size:** 1920x1080px
- **Format:** PNG
- **Usage:** Full-screen game background on Menu, Game, and Results screens (with dark overlay)
- **Description:** Wide retro space scene. Deep space with moon surface at bottom third (warm cream/gold craters). Earth visible as small blue marble in upper-left. Stars fill the sky with faint Milky Way band. Warm, inviting, adventurous feel. No characters or rockets.
- **Source:** `C:\Users\steve\Downloads\LunarLander\background.png`

## Characters

**Location:** `assets/games/lunar_lander/characters/`

All 8 characters are astronaut animals in retro spacesuits with fishbowl helmets. PNG format with transparent backgrounds. Displayed as native images WITHOUT circle clipping.

### SpaceDog.png
- **Size:** 256x256px
- **Format:** PNG (transparent background)
- **Description:** Golden retriever in white+orange retro spacesuit, fishbowl helmet, one paw raised in a wave, tail wagging
- **Source:** `C:\Users\steve\Downloads\LunarLander\Characters\space_dog.png`
- **Enum Value:** `LunarLanderCharacter.spaceDog`

### MoonCat.png
- **Size:** 256x256px
- **Format:** PNG (transparent background)
- **Description:** Gray cat in white+blue retro spacesuit, fishbowl helmet, ears pressing against glass, holding small flag
- **Source:** `C:\Users\steve\Downloads\LunarLander\Characters\moon_cat.png`
- **Enum Value:** `LunarLanderCharacter.moonCat`

### RocketPenguin.png
- **Size:** 256x256px
- **Format:** PNG (transparent background)
- **Description:** Penguin in white+red retro spacesuit, flippers out of suit sleeves, proud pose with flippers on hips
- **Source:** `C:\Users\steve\Downloads\LunarLander\Characters\rocket_penguin.png`
- **Enum Value:** `LunarLanderCharacter.rocketPenguin`

### OrbitOwl.png
- **Size:** 256x256px
- **Format:** PNG (transparent background)
- **Description:** Owl in white+purple retro spacesuit, huge wise eyes filling the visor, small tufted ears pressing against helmet glass
- **Source:** `C:\Users\steve\Downloads\LunarLander\Characters\orbit_owl.png`
- **Enum Value:** `LunarLanderCharacter.orbitOwl`

### NebulaFox.png
- **Size:** 256x256px
- **Format:** PNG (transparent background)
- **Description:** Fox in white+orange retro spacesuit, bushy tail visible through special suit window, one paw giving thumbs up
- **Source:** `C:\Users\steve\Downloads\LunarLander\Characters\nebula_fox.png`
- **Enum Value:** `LunarLanderCharacter.nebulaFox`

### CometRabbit.png
- **Size:** 256x256px
- **Format:** PNG (transparent background)
- **Description:** Rabbit in white+green retro spacesuit, long ears flopping inside the glass, mid-hop pose with feet slightly off ground
- **Source:** `C:\Users\steve\Downloads\LunarLander\Characters\comet_rabbit.png`
- **Enum Value:** `LunarLanderCharacter.cometRabbit`

### AstroBear.png
- **Size:** 256x256px
- **Format:** PNG (transparent background)
- **Description:** Bear in white+gold retro spacesuit (slightly bulkier), small round ears, warm friendly smile, holding small telescope
- **Source:** `C:\Users\steve\Downloads\LunarLander\Characters\astro_bear.png`
- **Enum Value:** `LunarLanderCharacter.astroBear`

### StarfishHamster.png
- **Size:** 256x256px
- **Format:** PNG (transparent background)
- **Description:** Hamster in white+yellow retro spacesuit (slightly oversized), helmet looks too big, tiny paws barely reaching sleeve ends, cheeks stuffed with space snacks, adorable wide-eyed expression
- **Source:** `C:\Users\steve\Downloads\LunarLander\Characters\starfish_hamster.png`
- **Enum Value:** `LunarLanderCharacter.starfishHamster`

## Sounds

**Location:** `assets/games/lunar_lander/sounds/`

All sound files are MP3 format. Trim values are applied by `LunarLanderSoundEffects` via `SoundEffectConfig.startSeconds` and `endSeconds`.

### LunarLander-ThrusterBurn.mp3
- **Format:** MP3
- **Trim:** Start 0.5s, end 3.0s
- **Usage:** Standard descent (1-39 scored), big descent (40+ scored), climbing back announcements
- **Description:** Rocket thrust/burn sound for scoring hits
- **Source:** `C:\Users\steve\Downloads\LunarLander\Sounds\rocket_thrust.mp3`

### LunarLander-CrashLanding.mp3
- **Format:** MP3
- **Trim:** Full file
- **Usage:** Crash landing (bust with Hard Landing ON) and negative altitude (overshoot with Hard Landing OFF) announcements
- **Description:** Explosion/crash sound for bust or overshoot conditions
- **Source:** `C:\Users\steve\Downloads\LunarLander\Sounds\explosion.mp3`

### LunarLander-RadioBeep.mp3
- **Format:** MP3
- **Trim:** Full file
- **Usage:** Player turn announcement (each new player's turn)
- **Description:** Communication beep for turn change
- **Source:** `C:\Users\steve\Downloads\LunarLander\Sounds\ping.mp3`

### LunarLander-Touchdown.mp3
- **Format:** MP3
- **Trim:** Full file
- **Usage:** Touchdown/victory announcement (plays together with VictoryFanfare)
- **Description:** Soft landing thud + celebration for winning
- **Source:** `C:\Users\steve\Downloads\LunarLander\Sounds\landing_thud.mp3`

### LunarLander-MissionControl.mp3
- **Format:** MP3
- **Trim:** Start 0s, end 1.25s
- **Usage:** Game start announcement
- **Description:** "Houston" style mission control chatter for game start
- **Source:** `C:\Users\steve\Downloads\LunarLander\Sounds\houston_problem.mp3`

### LunarLander-WarningAlarm.mp3
- **Format:** MP3
- **Trim:** Full file
- **Usage:** Near landing announcement (altitude <= 20, still above 0)
- **Description:** Alert klaxon for near-zero altitude
- **Source:** `C:\Users\steve\Downloads\LunarLander\Sounds\alarm.mp3`

### LunarLander-DriftSound.mp3
- **Format:** MP3
- **Trim:** Start 1.0s, end 4.0s
- **Usage:** Miss announcement (dart scores 0)
- **Description:** Gentle whoosh for missed throws (drifting in orbit)
- **Source:** `C:\Users\steve\Downloads\LunarLander\Sounds\whoosh.mp3`

### LunarLander-VictoryFanfare.mp3
- **Format:** MP3
- **Trim:** Start 0.5s, end 8.0s
- **Usage:** Victory announcement (plays together with Touchdown sound)
- **Description:** Triumphant space fanfare for winner
- **Source:** `C:\Users\steve\Downloads\LunarLander\Sounds\space_victory.mp3`

## Asset Usage in Code

### Loading Icons
```dart
Image.asset('assets/games/lunar_lander/icons/LunarLander-Icon.png')
```

### Loading Background
```dart
decoration: BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/games/lunar_lander/images/LunarLander-Background.png'),
    fit: BoxFit.cover,
  ),
)
```

### Loading Character Images
```dart
// Characters displayed as native images (no circle clipping)
Image.asset(
  'assets/games/lunar_lander/characters/${character.imageName}',
  width: 80,
  height: 80,
)
```

Where `character.imageName` returns the filename from `LunarLanderCharacter` enum (e.g., `'SpaceDog.png'`).

### Loading Sounds
```dart
// In LunarLanderSoundEffects
class LunarLanderSoundEffects {
  static const String _basePath = 'assets/games/lunar_lander/sounds/';

  static const SoundEffectConfig thrusterBurn = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-ThrusterBurn.mp3',
    startSeconds: 0.5,
    endSeconds: 3.0,
  );
  // ... other sounds
}
```

## pubspec.yaml Declaration

```yaml
assets:
  # Lunar Lander assets
  - assets/games/lunar_lander/
  - assets/games/lunar_lander/icons/
  - assets/games/lunar_lander/images/
  - assets/games/lunar_lander/characters/
  - assets/games/lunar_lander/sounds/
```

**Note:** Both the top-level directory and each subdirectory are declared to ensure Flutter's asset bundler picks up all files.
