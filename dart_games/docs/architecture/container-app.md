# Container App Architecture

## Overview

**Dart Games is a container app that provides core infrastructure for multiple games.**

The app architecture consists of two main layers:

1. **Core Container App** (Dart Games)
2. **Individual Games** (e.g., Carnival Derby, Target Tag, Monster Mash)

## Container App Responsibilities

The core container app provides:

### 1. Dartboard Connection Management
- Handles connection to physical Scolia dartboard via API
- Manages dartboard connection state (connected, disconnected, connecting)
- Provides emulator mode for development and testing without physical hardware
- Used by all games for dart input

### 2. Global User/Player System
- Centralized player list shared across all games
- Player profiles with photos and statistics
- Game history tracking with duration
- Cross-game statistics aggregation
- Players created in one game are available in all games

### 3. Centralized Settings
- Announcer system configuration (voice, personality)
- Victory music management
- User management interface
- Admin settings

### 4. Consistent Experience
- Shared design language for container screens
- Consistent navigation patterns
- Unified theme and branding
- Cross-platform compatibility (web, iOS, Android tablets)

## Individual Game Responsibilities

Games built on the container app:

### 1. Implement Game-Specific Logic
- Game rules and mechanics
- Scoring systems
- Win conditions
- Turn management

### 2. Integrate with Shared Systems
- Use dartboard connection for dart input
- Integrate with global user management
- Use announcement queue for audio feedback
- Play victory music on win

### 3. Maintain Unique Identity
- Custom color palettes and themes
- Game-specific visual elements
- Unique sound effects
- Distinct gameplay experience

### 4. Follow Integration Requirements
- Required integrations (see [Game Integration](../development/game-integration.md))
- Widget key requirements for testing
- Asset organization standards
- Cross-platform compatibility

## Project Structure

```
dart_games/
├── lib/
│   ├── main.dart                    # App entry point, theme, navigation
│   ├── models/                      # Data models (Player, GameHistoryEntry, etc.)
│   ├── providers/                   # State management (DartboardProvider, PlayerProvider, etc.)
│   ├── services/                    # Shared services (DartAnnouncerService, VictoryMusicService, etc.)
│   ├── widgets/                     # Reusable widgets (dartboard components, status indicators)
│   └── screens/
│       ├── splash_screen.dart       # Initial loading screen
│       ├── dartboard_setup_screen.dart  # Connect to dartboard or emulator
│       ├── home_screen.dart         # Game selection menu
│       ├── options_screen.dart      # System Settings (announcer, music, users, admin)
│       ├── test_dartboard_screen.dart   # Dartboard emulator (admin tool)
│       └── games/
│           ├── carnival_horse_race/ # Carnival Derby game
│           │   ├── horse_race_menu_screen.dart     # Game setup
│           │   ├── horse_race_game_screen.dart     # Active gameplay
│           │   └── horse_race_results_screen.dart  # Winner announcement
│           ├── target_tag/          # Target Tag game
│           │   ├── target_tag_menu_screen.dart     # Game setup
│           │   ├── target_tag_game_screen.dart     # Active gameplay
│           │   └── target_tag_results_screen.dart  # Winner announcement
│           └── monster_mash/        # Monster Mash game
│               ├── monster_mash_menu_screen.dart   # Game setup
│               ├── monster_mash_game_screen.dart   # Active gameplay
│               └── monster_mash_results_screen.dart # Winner announcement
├── test/                            # Non-UI test suite (505 tests)
├── integration_test/                # UI automation tests (231 tests)
├── assets/                          # Assets organized by game
│   ├── common/                      # Shared assets
│   └── games/                       # Game-specific assets
│       ├── carnival_derby/
│       ├── target_tag/
│       └── monster_mash/
└── docs/                            # Documentation
    ├── architecture/
    ├── development/
    ├── testing/
    ├── deployment/
    ├── critical-rules/
    └── games/
```

## Container Screens

### Splash Screen
**File:** `lib/screens/splash_screen.dart`

**Purpose:** Initial loading screen shown when app starts

**Functionality:**
- Displays app logo
- Loads initial data
- Checks dartboard connection
- Navigates to home screen or dartboard setup

### Dartboard Setup Screen
**File:** `lib/screens/dartboard_setup_screen.dart`

**Purpose:** Connect to physical dartboard or start emulator mode

**Functionality:**
- Scan for available dartboards
- Connect to selected dartboard
- Option to use emulator mode
- Save connection preferences

### Home Screen
**File:** `lib/screens/home_screen.dart`

**Purpose:** Game selection menu

**Functionality:**
- Display available games as cards
- Show dartboard connection status
- Navigate to System Settings
- Navigate to selected game

### Options Screen (System Settings)
**File:** `lib/screens/options_screen.dart`

**Purpose:** Configure global settings

**Sections:**
- **Announcer Settings:** Voice engine, personality, enabled/disabled
- **Victory Music:** Add/remove music files, test playback
- **User Management:** Add/edit/delete players, view stats
- **Admin Settings:** Dartboard emulator, debug options

### Test Dartboard Screen (Admin Tool)
**File:** `lib/screens/test_dartboard_screen.dart`

**Purpose:** Test and debug dartboard functionality

**Functionality:**
- Interactive dartboard emulator
- Click segments to simulate throws
- View dart events in real-time
- Test dartboard accuracy

## Navigation Flow

```
Splash Screen
    ↓
Home Screen (Game Selection)
    ├── → Carnival Derby Menu → Game → Results → Back to Home
    ├── → Target Tag Menu → Game → Results → Back to Home
    ├── → Monster Mash Menu → Game → Results → Back to Home
    ├── → Options Screen (System Settings) → Back to Home
    └── → Dartboard Setup (if not connected) → Back to Home
```

## Data Flow

### Player Data Flow
```
User creates player
    ↓
PlayerProvider.savePlayer()
    ↓
Server API (persistence)
    ↓
Available in all games
    ↓
Games update player stats
    ↓
PlayerProvider.updatePlayerStats()
    ↓
Server API (persistence)
```

### Game Flow
```
Select game from Home Screen
    ↓
Game Menu (configure settings, select players)
    ↓
Start Game
    ↓
Game Screen (gameplay loop)
    ├── Process dart throws
    ├── Update game state
    ├── Announce events
    └── Check win condition
    ↓
Results Screen (show winner, play victory music)
    ├── Update player stats (all players)
    ├── Option to play again
    └── Option to change settings
```

### Dartboard Data Flow
```
Physical Dartboard or Emulator
    ↓
DartboardProvider (dart events)
    ↓
Game Provider (process throw)
    ↓
Update game state
    ↓
Trigger announcements
    ↓
Update UI
```

## Dependency Management

### Container Dependencies
```dart
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0           # State management
  http: ^0.13.0              # Dartboard API
  audioplayers: ^5.0.0       # Victory music, sound effects
  google_fonts: ^6.0.0       # Typography
  image_picker: ^1.0.0       # Player photos
  file_picker: ^8.0.0        # Victory music upload
  # ... other shared dependencies
```

### Game-Specific Dependencies
Games can add their own dependencies but should prefer using container-provided services.

## State Management

### Provider Architecture
- **Container-level providers:** Shared across all games
  - `DartboardProvider` - Dartboard connection
  - `PlayerProvider` - User management
- **Game-level providers:** Specific to each game
  - `HorseRaceProvider` - Carnival Derby game state
  - `TargetTagProvider` - Target Tag game state
  - `MonsterMashProvider` - Monster Mash game state

### State Persistence
- **Server API (SQLite):** Settings, player data, game history
- **In-memory:** Active game state (not persisted)

## Benefits of Container Architecture

### Code Reuse
- Shared services used by all games
- Consistent user management
- Unified dartboard integration
- Common UI components

### Consistency
- Same player list across games
- Unified settings
- Consistent announcer experience
- Cross-game statistics

### Scalability
- Easy to add new games
- Games inherit container infrastructure
- Minimal setup for new games
- Clear separation of concerns

### Maintainability
- Fix bugs in one place (container)
- Update shared systems once
- Clear ownership boundaries
- Easier testing (shared components tested once)

## Adding a New Game

To add a new game to the container:

1. **Create game directory** in `lib/screens/games/[game_name]/`
2. **Implement screens** (menu, game, results)
3. **Create game provider** in `lib/providers/[game_name]_provider.dart`
4. **Define game model** in `lib/models/[game_name]_game.dart`
5. **Integrate with container systems** (see [Game Integration](../development/game-integration.md))
6. **Add game card** to `home_screen.dart`
7. **Create tests** following existing patterns
8. **Add documentation** in `docs/games/[game_name]/`

See [Adding New Games](../development/adding-games.md) for detailed guide.

## Reference Implementations

- **Carnival Derby:** Complete example of game integration
- **Target Tag:** Complete example with team mode and complex mechanics
- **Monster Mash:** Complete example with health system, buffs, and custom stone buttons

## Related Documentation

- [Shared Systems](shared-systems.md) - Details on all shared services
- [Design System](design-system.md) - Container app design language
- [Game Integration](../development/game-integration.md) - Required integrations for new games
