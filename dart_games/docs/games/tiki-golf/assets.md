# Tiki Golf - Asset Inventory

## Asset Location
**Base Path:** `assets/games/tiki_golf/`

## Asset Summary
- **Icons:** 1 file (TikiGolf-Icon.png)
- **Background:** 1 file (TikiGolf-Background.png)
- **Pieces:** 10 files (9 hole themes + 1 trophy)
- **Teams:** 6 files (team crests)
- **Sounds:** 8 files
- **Total Assets:** 26 files (18 image/icon/piece/crest + 8 sounds)

## Icons

**Location:** `assets/games/tiki_golf/icons/`

### TikiGolf-Icon.png
- **Format:** PNG
- **Usage:** Home screen game card. Note: The icon has "Tiki Golf" text baked into the image. The home card also renders its standard title label below the icon — duplicate text was explicitly accepted by the user. Do NOT add a config flag to suppress the title for this game.
- **Description:** A cartoon tiki statue with glowing orange eyes and a wide carved smile leaning against a mini-golf putter. A golf ball sits at the base near a small palm tree with hibiscus flowers framing the scene. Lilo & Stitch tropical cartoon style.

## Images

**Location:** `assets/games/tiki_golf/images/`

### TikiGolf-Background.png
- **Format:** PNG
- **Usage:** Full-screen background on all three screens (menu, game, results). Rendered with `BoxFit.cover`. A Palm Green overlay (`#2D6A4F` at 0.60 opacity) is layered on top to maintain UI readability.
- **Description:** A fully illustrated tropical mini-golf scene: sunny island paradise with a mini-golf green in the foreground, crystal-clear turquoise lagoon behind it, palm trees on both sides, and a volcanic mountain in the far background. Bright blue sky with puffy white clouds. Small tiki torches line the edges of the green.

## Hole Theme Images (9 files)

**Location:** `assets/games/tiki_golf/pieces/`

These 9 images are shuffled into the 9 hole slots at game start. The displayed hole name follows the assigned image.

### Volcano.png
- **Hole Theme:** Volcano Hole
- **Description:** A mini-golf hole built into a small cartoon volcano with lava flowing down the sides. Smoke puffs from the top. The putting green wraps around the volcano base. Lilo & Stitch tropical cartoon style.

### Waterfall.png
- **Hole Theme:** Waterfall Hole
- **Description:** A mini-golf hole with a cascading waterfall flowing over rocks into a small pool. The putting green crosses a stone bridge over the water. Rainbow mist sparkles. Lilo & Stitch tropical cartoon style.

### TikiStatue.png
- **Hole Theme:** Tiki Statue Hole
- **Description:** A mini-golf hole where the ball goes through the mouth of a large carved tiki statue with glowing orange eyes and a wide grin. Tropical flowers at the base. Lilo & Stitch tropical cartoon style.

### PalmTree.png
- **Hole Theme:** Palm Tree Hole
- **Description:** A mini-golf hole winding between two tall palm trees with coconuts. A small sand trap on one side. The green curves around the palm tree trunks. Lilo & Stitch tropical cartoon style.

### Lagoon.png
- **Hole Theme:** Lagoon Hole
- **Description:** A mini-golf hole built on a small island in a crystal-clear lagoon. A wooden bridge connects to the mainland. Tropical fish visible in the water. Lilo & Stitch tropical cartoon style.

### Shipwreck.png
- **Hole Theme:** Shipwreck Hole
- **Description:** A mini-golf hole built into a colorful old pirate ship half-buried in sand. The ball goes through holes in the hull. A parrot flag on the mast. Lilo & Stitch tropical cartoon style.

### BambooTemple.png
- **Hole Theme:** Bamboo Temple Hole
- **Description:** A mini-golf hole built into a small bamboo temple with a pagoda roof. Paper lanterns hanging. The green leads up stone steps to the hole. Lilo & Stitch tropical cartoon style.

### CoralReef.png
- **Hole Theme:** Coral Reef Hole
- **Description:** A mini-golf hole themed as an underwater scene with colorful coral formations framing the green. The hole is inside a giant clam shell. Small sea stars and shells scattered around. Lilo & Stitch tropical cartoon style.

### SunsetPier.png
- **Hole Theme:** Sunset Pier Hole
- **Description:** A mini-golf hole built on a wooden pier extending over the ocean at sunset. Tiki torches line both sides. The hole is at the end of the pier with a beautiful orange-pink sky behind. Lilo & Stitch tropical cartoon style.

### GoldenTiki.png
- **Location:** `assets/games/tiki_golf/pieces/`
- **Usage:** Displayed on the results screen for the Solo mode winner (Golden Tiki Champion). Also shown as a small trophy icon next to the winner's name.
- **Description:** A golden tiki trophy statue with a carved smiling face, wearing a small golden lei. The trophy sits on a wooden pedestal with "CHAMPION" carved into it. Sparkle effects around the statue. Lilo & Stitch tropical cartoon style.

## Team Crests (6 files)

**Location:** `assets/games/tiki_golf/teams/`

At game start, 4 of these 6 crests are randomly selected and assigned to teams 1-N. The selection varies each game, ensuring visual variety. Each crest is a flat circular design suitable for small sizes (player panel, 32×32) and large sizes (team banner, 120×120).

### Sharks.png
- **Team Color:** Lagoon Blue `#00B4D8`
- **Description:** A cartoon shark head facing forward with a friendly toothy grin, against a Lagoon Blue circular field with a Sand White rope-style border.

### SeaTurtles.png
- **Team Color:** Palm Green `#2D6A4F`
- **Description:** A cartoon sea turtle facing forward with a relaxed smile, against a Palm Green circular field with a Sand White rope-style border.

### Hibiscus.png
- **Team Color:** Hibiscus Pink `#FF69B4`
- **Description:** A stylized hibiscus flower facing forward with five rounded petals and a yellow stamen, against a Hibiscus Pink circular field with a Sand White rope-style border.

### Volcanoes.png
- **Team Color:** Tropical Orange `#FF8C42`
- **Description:** A small smiling cartoon volcano with lava flowing down the sides and a puff of smoke, against a Tropical Orange circular field with a Sand White rope-style border.

### Coconuts.png
- **Team Color:** Tiki Brown `#8B5E3C`
- **Description:** Two stacked cartoon coconuts with cute faces, palm fronds behind, against a Tiki Brown circular field with a Sand White rope-style border.

### Parrots.png
- **Team Color:** Sky Blue `#87CEEB`
- **Description:** A colorful tropical parrot head facing forward with rainbow feathers (green, blue, red, yellow) and a small beach hat, against a Sky Blue circular field with a Sand White rope-style border.

## Sounds

**Location:** `assets/games/tiki_golf/sounds/`

### TikiGolf-Putt.mp3
- **Trim:** 0s–0.2s
- **Format:** MP3
- **Usage:** Bogey announcement (target hit on dart 3+)
- **Description:** Short golf putt sound — the satisfying click of a putter striking a ball.

### TikiGolf-BallDrop.mp3
- **Trim:** 0s–1.6s
- **Format:** MP3
- **Usage:** Par announcement (target hit on dart 2)
- **Description:** Ball dropping into the hole — the distinctive hollow "plonk" of a golf ball dropping into the cup.

### TikiGolf-Clap.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Birdie announcement (target hit on dart 1)
- **Description:** Polite golf clap — appreciative applause from a gallery of spectators.

### TikiGolf-Ukulele.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Game start, player turn, and near win announcements
- **Description:** Quick ukulele strum — a bright, cheerful tropical chord strummed once. Evokes the breezy island atmosphere.

### TikiGolf-Splash.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Splash announcement (all darts miss) and individual miss (non-last dart)
- **Description:** Water splash — the comedic sound of a ball landing in the water hazard.

### TikiGolf-TikiChime.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** New hole, almost there, mulligan reminder, and hole complete announcements
- **Description:** Tropical wind chime — the delicate, melodic ring of bamboo or shell chimes in a tropical breeze.

### TikiGolf-VictoryFanfare.mp3
- **Trim:** 7.0s–11.0s
- **Format:** MP3
- **Usage:** Victory announcement (winner display on results screen)
- **Description:** Tropical celebration fanfare — an upbeat Hawaiian-style horn melody celebrating the Golden Tiki Champion. Trimmed to the 4-second climax section (7.0s–11.0s).

### TikiGolf-Mulligan.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Mulligan used announcement
- **Description:** Comedic "do-over" sound — a silly, cartoon-style comedic sound effect (e.g., slide whistle or boing) that captures the light-hearted nature of getting a second chance.

## Asset Usage in Code

### Loading Icons
```dart
Image.asset('assets/games/tiki_golf/icons/TikiGolf-Icon.png')
```

### Loading Background
```dart
// All screens: background + Palm Green overlay stack
Positioned.fill(
  child: Image.asset(
    'assets/games/tiki_golf/images/TikiGolf-Background.png',
    fit: BoxFit.cover,
  ),
),
Positioned.fill(
  child: Container(
    color: const Color(0xFF2D6A4F).withOpacity(0.60),
  ),
),
```

### Loading Hole Theme Images (randomized slot)
```dart
// game.holeImagePaths[currentHole - 1] returns the randomly-assigned path
Image.asset(
  game.holeImagePaths[game.currentHole - 1],
  width: 120,
  height: 120,
  fit: BoxFit.contain,
)
```

### Loading Team Crests
```dart
// teamCrestPaths[teamIndex] returns path for team's randomly-assigned crest
Image.asset(
  game.teamCrestPaths[teamIndex],
  width: 64,
  height: 64,
)
```

### Loading Sounds
```dart
class TikiGolfSoundEffects {
  static const String _basePath = 'assets/games/tiki_golf/sounds/';

  static const SoundEffectConfig putt = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Putt.mp3',
    startSeconds: 0.0,
    endSeconds: 0.2,
  );
  // ... (see announcements.md for full list)
}
```

## pubspec.yaml Declaration

```yaml
assets:
  # ... other game assets ...

  # Tiki Golf assets
  - assets/games/tiki_golf/
```

The directory-level declaration includes all files within all subdirectories (`icons/`, `images/`, `pieces/`, `teams/`, `sounds/`).
