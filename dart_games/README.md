# Dart Games

A Flutter-based container app for interactive dartboard games powered by the Scolia 2 dartboard system.

> **⚠️ Important:** This app requires a **Scolia 2 dartboard** and a valid **Scolia API key** to function. You must contact [Scolia](https://scolia.com) to obtain an API key before using this application.

## Overview

Dart Games is a cross-platform (web and tablet) application that provides a framework for building interactive dartboard games. The app handles dartboard connectivity, user management, and common game features, allowing developers to focus on creating unique game experiences.

### Current Games

- **Carnival Derby** - A horse race-style game where players advance by scoring points with darts

## Features

### Core Infrastructure

- **Dartboard Integration** - Seamless connection to Scolia 2 physical dartboards via API
- **Emulator Mode** - Test games without physical hardware using the built-in dartboard emulator
- **Global User Management** - Shared player profiles, statistics, and game history across all games
- **Voice Announcer** - Customizable text-to-speech announcements with multiple voice engines and personalities
- **Victory Music** - Custom victory music management with random selection
- **Responsive Design** - Works on web browsers (Chrome, Safari, Firefox, Edge) and tablets (iOS, Android)

### Shared Services

All games in the Dart Games ecosystem integrate with these shared systems:

#### 1. Dartboard Provider (`DartboardProvider`)
- Manages connection to physical Scolia dartboard or emulator
- Real-time dart throw detection
- Status tracking (connected, disconnected, connecting)

```dart
// Access dartboard provider
final dartboardProvider = context.read<DartboardProvider>();

// Listen to dart throws
dartboardProvider.apiService?.dartThrowStream.listen((event) {
  final score = event['score'];
  final multiplier = event['multiplier'];
  // Handle dart throw
});
```

#### 2. Player Provider (`PlayerProvider`)
- Global player list shared across all games
- Player profiles with photos and statistics
- Game history tracking with duration

```dart
// Access player provider
final playerProvider = context.read<PlayerProvider>();

// Get all players
final players = playerProvider.allPlayers;

// Add new player
await playerProvider.savePlayer(Player(
  id: generateId(),
  name: 'Player Name',
  photoPath: photoPath,
));

// Update player stats when game ends
await playerProvider.updatePlayerStats(
  playerId,
  won: true,
  gameName: 'Your Game Name',
  gameDuration: gameDuration,
);
```

#### 3. Announcer Service (`DartAnnouncerService`)
- Text-to-speech for game events
- Multiple voice engines (Browser Voices, ResponsiveVoice)
- Customizable personalities (Professional, Excited, Calm, Funny, Drill Sergeant)

```dart
// Create announcer instance
final announcer = DartAnnouncerService();

// Load settings
await _loadAnnouncerSettings();

// Announce game events
announcer.speak('Player turn');
announcer.speak('Bullseye! 50 points!');
```

#### 4. Victory Music Service (`VictoryMusicService`)
- Custom music file management
- Random selection from user's music library
- Cross-platform support (web data URLs, native file paths)

```dart
// Access victory music service
final musicService = VictoryMusicService();

// Check if custom music is available
if (await musicService.hasCustomMusic()) {
  final musicSource = await musicService.getRandomMusicSource();
  // Play music using appropriate player
}
```

## Architecture

### Container App Structure

Dart Games uses a container app architecture:

```
dart_games/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   ├── providers/                   # State management
│   ├── services/                    # Shared services
│   ├── widgets/                     # Reusable widgets
│   └── screens/
│       ├── splash_screen.dart       # Initial loading
│       ├── dartboard_setup_screen.dart
│       ├── home_screen.dart         # Game selection
│       ├── options_screen.dart      # System settings
│       └── games/
│           └── carnival_horse_race/ # Individual game
├── test/                            # Test suite (139 tests)
└── assets/                          # Images, fonts, etc.
```

### Design Philosophy

- **Core Container App** - Provides infrastructure (dartboard, users, settings)
- **Individual Games** - Built on top of container, each with unique visual identity
- **Shared Systems** - Games integrate with global user management, announcer, and victory music
- **Consistent Experience** - Unified UX patterns across all games

## Adding a New Game

To add a new game to Dart Games:

### 1. Create Game Screens

Create a new directory in `lib/screens/games/[game_name]/` with:
- Menu/setup screen
- Active gameplay screen
- Results/victory screen

### 2. Design Unique Visual Identity

Each game should have its own:
- Custom color palette
- Custom typography
- Unique UI elements and animations
- Theme consistency within the game

### 3. Integrate with Global Systems

**Required integrations:**

```dart
// Import shared systems
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/services/dart_announcer_service.dart';
import 'package:dart_games/services/victory_music_service.dart';

// Use global user list
final playerProvider = context.read<PlayerProvider>();
final availablePlayers = playerProvider.allPlayers;

// Track game start time
final startTime = DateTime.now();

// On game completion, update stats for all players
final gameDuration = DateTime.now().difference(startTime);
for (final playerId in game.playerIds) {
  final isWinner = playerId == game.winnerId;
  await playerProvider.updatePlayerStats(
    playerId,
    won: isWinner,
    gameName: 'Your Game Name',
    gameDuration: isWinner ? gameDuration : null,
  );
}

// Play victory music
final musicService = VictoryMusicService();
if (await musicService.hasCustomMusic()) {
  final musicSource = await musicService.getRandomMusicSource();
  // Play music
}
```

### 4. Add Game Card to Home Screen

Update `lib/screens/home_screen.dart` to include navigation to your game.

### 5. Create Tests

Follow existing patterns in `test/screens/games/` to create integration tests.

### 6. Update Documentation

Update `CLAUDE.md` with new test counts and game-specific notes.

## Development

### Prerequisites

- Flutter SDK
- Scolia 2 dartboard (for production use)
- Scolia API key (required)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/shuels2/dart-games.git
cd dart_games

# Install dependencies
flutter pub get

# Run tests (all 139 tests must pass)
flutter test

# Launch in Chrome (web)
flutter run -d chrome

# Launch on tablet
flutter run
```

### Testing Requirements

**All 139 tests must pass before any build or deployment.**

```bash
flutter test
```

Test coverage includes:
- Model serialization (36 tests)
- Provider functionality (30 tests)
- Service integration (42 tests)
- Game integration (8 tests)
- Dartboard accuracy (23 tests)

### Cross-Platform Compatibility

All features must work on:
- Web browsers (Chrome, Safari, Firefox, Edge)
- iOS tablets (iPad)
- Android tablets

Use platform-specific code only when necessary with proper conditional imports.

## Game Integration Requirements

Every game in Dart Games **must** integrate with:

1. **Global User Management** - Use `PlayerProvider` for player list and stats
2. **Announcer System** - Use `DartAnnouncerService` for voice announcements
3. **User Win Tracking** - Call `updatePlayerStats()` when games complete
4. **Game Timer** - Track duration from start to completion
5. **Victory Music** - Use `VictoryMusicService` for victory celebrations

See the [CLAUDE.md](CLAUDE.md) file for detailed integration requirements.

## Settings

### System Settings (Options Screen)

- **Announcer** - Configure voice engine, personality, and enabled state
- **Victory Music** - Upload and manage custom victory music files
- **User Management** - Create, edit, and delete player profiles
- **Admin** - Access dartboard emulator and system tools

### Dartboard Setup

The app supports two modes:
1. **Physical Dartboard** - Connect to Scolia 2 via API (requires API key)
2. **Emulator Mode** - Test games without hardware

## Contributing

We welcome contributions! Please follow these guidelines:

1. **Run all tests** before submitting changes (`flutter test`)
2. **Maintain cross-platform compatibility** (web and tablet)
3. **Follow integration requirements** when adding games
4. **Update documentation** for new features
5. **Do not modify the dartboard emulator** without explicit approval

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines.

## License

[Add your license information here]

## Contact

For Scolia API key inquiries, visit [https://scolia.com](https://scolia.com)

## Acknowledgments

Built with Flutter and powered by the Scolia 2 dartboard system.
