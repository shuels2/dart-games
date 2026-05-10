# Gladiator Arena - Asset Inventory

## Asset Location
**Base Path:** `assets/games/gladiator_arena/`

## Asset Summary

- **Icons:** 1 file
- **Images (background):** 1 file
- **Character Images:** 8 files
- **Sounds:** 8 files
- **Total Assets:** 18 files

## Icons

**Location:** `assets/games/gladiator_arena/icons/`

### GladiatorArena-Icon.png
- **Format:** PNG (with transparency / solid white background trimmed in-app)
- **Usage:** Home screen game selection card thumbnail
- **Description:** Golden laurel wreath surrounding a small Roman colosseum arena silhouette, with tiny gladiator animal silhouettes inside. Sun-drenched marble and vibrant green-gold laurel. Disney/Pixar Hercules animation style, family-friendly.
- **Source:** AI-generated (Gemini) per spec Section 3A

## Images

**Location:** `assets/games/gladiator_arena/images/`

### GladiatorArena-Background.png
- **Format:** PNG
- **Usage:** Full-screen background on all three screens (menu, game, results); rendered as BoxFit.cover with a translucent dark overlay on top for UI readability
- **Description:** Interior of a grand Roman colosseum — marble columns on the left and right edges, tiered seating with colorful banners in the upper sections, sun-drenched sandy arena floor in the center. Warm golden sunlight from above. Vivid blue sky with white clouds. Golden eagle statues atop some columns. Grand, celebratory, family-friendly. No characters in the scene. Widescreen format.
- **Source:** AI-generated (Gemini) per spec Section 3B
- **Note:** If the generated image is a fully illustrated scene with dense detail (rather than a soft texture/wash), a translucent overlay (`Colors.black.withOpacity(0.65)`) is applied in every screen to ensure UI readability.

## Characters

**Location:** `assets/games/gladiator_arena/characters/`

All 8 characters are randomly assigned to players at game start (shuffle without replacement). Each character image features a solid or transparent background, Disney's Hercules animation style — heroic, cute, family-friendly.

### LeoLion.png
- **Format:** PNG (transparent or white bg)
- **Usage:** Assigned to a player; shown as 60×60 on their podium during the game; 270×270 on Results screen if winner
- **Description:** Leo the Lion Warrior — upright lion in golden gladiator chest plate and red cape, holds a small wooden practice sword, confident smile, golden mane flowing heroically. Brave and noble.

### AquilaEagle.png
- **Format:** PNG
- **Usage:** Same as LeoLion
- **Description:** Aquila the Eagle Champion — proud eagle in bronze helmet with red plume, wings slightly spread in a victorious pose, dark brown feathers with golden highlights on chest. Majestic and swift.

### LupusWolf.png
- **Format:** PNG
- **Usage:** Same as LeoLion
- **Description:** Lupus the Wolf Fighter — scrappy wolf in leather arm guards and bronze shoulder pad, lean and agile with a cheeky grin and clever eyes, gray fur with white chest. Cunning and quick.

### UrsusBear.png
- **Format:** PNG
- **Usage:** Same as LeoLion
- **Description:** Ursus the Bear Brawler — big lovable bear in gladiator leather belt and wrist wraps, large but gentle smile, brown fur, round belly, one paw waving. Strong but friendly.

### CorvusRaven.png
- **Format:** PNG
- **Usage:** Same as LeoLion
- **Description:** Corvus the Raven Trickster — clever raven in small purple cloak with silver clasp, one wing on hip in theatrical gesture, dark glossy feathers with purple sheen, mischievous grin. Dramatic and witty.

### TaurusBull.png
- **Format:** PNG
- **Usage:** Same as LeoLion
- **Description:** Taurus the Bull Charger — powerful bull in gladiator metal collar with small studs, arms crossed confidently, large curved horns, determined but friendly expression, dark brown hide with lighter snout. Powerful and dependable.

### SerpensSnake.png
- **Format:** PNG
- **Usage:** Same as LeoLion
- **Description:** Serpens the Snake Striker — sleek cobra coiled upright with small golden headband like a crown, emerald green with golden diamond patterns, wide hood slightly spread, big expressive non-scary eyes, confident smirk. Swift and stylish.

### FalcoFalcon.png
- **Format:** PNG
- **Usage:** Same as LeoLion
- **Description:** Falco the Falcon Scout — swift falcon in small bronze leg guards and leather chest strap, wings folded behind like a cape, one talon forward in a ready stance, slate gray and white feathers with orange-yellow beak, sharp but friendly eyes. Fast and alert.

## Sounds

**Location:** `assets/games/gladiator_arena/sounds/`

### GladiatorArena-SwordClash.mp3
- **Trim:** Full file
- **Usage:** Small hit announcements (1–19 pts), good hit announcements (20–39 pts), outer bull hit, double-range announcement
- **Description:** Metallic clang of sword clash — used for successful scoring hits, conveying impact and combat energy

### GladiatorArena-CrowdCheer.mp3
- **Trim:** Full file
- **Usage:** Great hit announcements (40+ pts), triple hit announcements, inner bull (Bullseye) hit
- **Description:** Arena crowd cheering — enthusiastic crowd response to impressive throws

### GladiatorArena-CrowdGasp.mp3
- **Trim:** 0s to 1.5s
- **Usage:** Knockoff announcements, overshoot bust, non-double bust
- **Description:** Arena crowd gasp — the dramatic crowd reaction to a shocking moment (elimination reset or failed finish attempt)

### GladiatorArena-ShieldBlock.mp3
- **Trim:** Full file
- **Usage:** Shield Block announcement (knockoff blocked during Shield Round), Shield Round start announcement
- **Description:** Heavy thud/clang of shield deflecting a blow — conveys protection and safety

### GladiatorArena-TrumpetFanfare.mp3
- **Trim:** Full file
- **Usage:** Game start announcement, near victory announcement, victory announcements (both Double Finish variants)
- **Description:** Roman trumpet fanfare — regal and triumphant, used for significant game events and celebrations

### GladiatorArena-TurnBell.mp3
- **Trim:** 0s to 4.0s
- **Usage:** Player turn announcement (start of each turn), Speed Play timer expired announcement
- **Description:** Bell/gong sound marking turn transitions — the arena bell that signals the next gladiator steps into the spotlight

### GladiatorArena-MissThud.mp3
- **Trim:** Full file
- **Usage:** Miss announcement (dart scores 0)
- **Description:** Soft thud/dust puff sound — the anticlimactic landing of a dart in sand, used for missed throws

### GladiatorArena-TimerTick.mp3
- **Trim:** 0s to 2.0s
- **Usage:** Speed Play timer warning (at 5 seconds remaining)
- **Description:** Ticking sound indicating urgency — plays once when the Speed Play timer drops to 5 seconds, prompting the player to hurry

## Asset Usage in Code

### Loading Characters
```dart
// Character images are referenced by name stored in the model
Image.asset('assets/games/gladiator_arena/characters/${player.characterName}.png')
```

### Loading Background
```dart
decoration: BoxDecoration(
  image: DecorationImage(
    image: const AssetImage('assets/games/gladiator_arena/images/GladiatorArena-Background.png'),
    fit: BoxFit.cover,
  ),
)
```

### Loading Icon (Home Screen)
```dart
Image.asset('assets/games/gladiator_arena/icons/GladiatorArena-Icon.png')
```

## pubspec.yaml Declaration

```yaml
assets:
  # ... other game assets ...

  # Gladiator Arena assets
  - assets/games/gladiator_arena/
```

The directory-level declaration (`gladiator_arena/`) covers all subdirectories: `icons/`, `images/`, `characters/`, `sounds/`.

## Character Assignment

Characters are randomly shuffled and assigned to players at game start (not at player selection time). The shuffle uses Dart's `List.shuffle()` on the full list of 8 character names, then assigns one to each player in order. This ensures no two players get the same character and that assignments are unpredictable each game.

Character name constants:
```dart
static const List<String> characters = [
  'LeoLion',
  'AquilaEagle',
  'LupusWolf',
  'UrsusBear',
  'CorvusRaven',
  'TaurusBull',
  'SerpensSnake',
  'FalcoFalcon',
];
```
