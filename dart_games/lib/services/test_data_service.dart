import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/game_history_entry.dart';
import 'embedded_test_audio.dart';

/// Service to generate test data for development and testing purposes
class TestDataService {
  static const _uuid = Uuid();

  /// Generate a set of test players with varied stats and history
  static List<Player> generateTestPlayers() {
    final now = DateTime.now();

    return [
      // Player 1: High performer
      Player(
        id: _uuid.v4(),
        name: 'Sarah "Bullseye" Chen',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 120)),
        gamesPlayed: 47,
        gamesWon: 23,
        gameHistory: _generateGameHistory(
          gamesWon: 23,
          lastPlayedDaysAgo: 0,
        ),
      ),

      // Player 2: Experienced player
      Player(
        id: _uuid.v4(),
        name: 'Marcus "The Hammer" Rodriguez',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 90)),
        gamesPlayed: 38,
        gamesWon: 15,
        gameHistory: _generateGameHistory(
          gamesWon: 15,
          lastPlayedDaysAgo: 1,
        ),
      ),

      // Player 3: Newcomer with potential
      Player(
        id: _uuid.v4(),
        name: 'Emma "Quick Draw" Wilson',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 30)),
        gamesPlayed: 12,
        gamesWon: 6,
        gameHistory: _generateGameHistory(
          gamesWon: 6,
          lastPlayedDaysAgo: 0,
        ),
      ),

      // Player 4: Casual player
      Player(
        id: _uuid.v4(),
        name: 'Jake "Steady" Thompson',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 75)),
        gamesPlayed: 25,
        gamesWon: 8,
        gameHistory: _generateGameHistory(
          gamesWon: 8,
          lastPlayedDaysAgo: 2,
        ),
      ),

      // Player 5: Veteran
      Player(
        id: _uuid.v4(),
        name: 'Alex "Precision" Patel',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 150)),
        gamesPlayed: 62,
        gamesWon: 31,
        gameHistory: _generateGameHistory(
          gamesWon: 31,
          lastPlayedDaysAgo: 1,
        ),
      ),

      // Player 6: Learning the ropes
      Player(
        id: _uuid.v4(),
        name: 'Jordan "Rising Star" Kim',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 20)),
        gamesPlayed: 8,
        gamesWon: 2,
        gameHistory: _generateGameHistory(
          gamesWon: 2,
          lastPlayedDaysAgo: 3,
        ),
      ),

      // Player 7: Consistent performer
      Player(
        id: _uuid.v4(),
        name: 'Taylor "Ace" Martinez',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 100)),
        gamesPlayed: 41,
        gamesWon: 20,
        gameHistory: _generateGameHistory(
          gamesWon: 20,
          lastPlayedDaysAgo: 0,
        ),
      ),

      // Player 8: Fun competitor
      Player(
        id: _uuid.v4(),
        name: 'Riley "Lucky Shot" O\'Brien',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 60)),
        gamesPlayed: 19,
        gamesWon: 7,
        gameHistory: _generateGameHistory(
          gamesWon: 7,
          lastPlayedDaysAgo: 4,
        ),
      ),

      // Player 9: Strategic player
      Player(
        id: _uuid.v4(),
        name: 'Sam "Sniper" Anderson',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 85)),
        gamesPlayed: 33,
        gamesWon: 18,
        gameHistory: _generateGameHistory(
          gamesWon: 18,
          lastPlayedDaysAgo: 1,
        ),
      ),

      // Player 10: Enthusiastic newcomer
      Player(
        id: _uuid.v4(),
        name: 'Casey "Wild Card" Davis',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 15)),
        gamesPlayed: 6,
        gamesWon: 1,
        gameHistory: _generateGameHistory(
          gamesWon: 1,
          lastPlayedDaysAgo: 5,
        ),
      ),

      // Player 11: Competitive veteran
      Player(
        id: _uuid.v4(),
        name: 'Morgan "Deadeye" Foster',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 140)),
        gamesPlayed: 58,
        gamesWon: 29,
        gameHistory: _generateGameHistory(
          gamesWon: 29,
          lastPlayedDaysAgo: 0,
        ),
      ),

      // Player 12: Steady improver
      Player(
        id: _uuid.v4(),
        name: 'Quinn "The Wall" Murphy',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 70)),
        gamesPlayed: 28,
        gamesWon: 11,
        gameHistory: _generateGameHistory(
          gamesWon: 11,
          lastPlayedDaysAgo: 2,
        ),
      ),

      // Player 13: Clutch performer
      Player(
        id: _uuid.v4(),
        name: 'Avery "Ice Cold" Brooks',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 95)),
        gamesPlayed: 36,
        gamesWon: 19,
        gameHistory: _generateGameHistory(
          gamesWon: 19,
          lastPlayedDaysAgo: 1,
        ),
      ),

      // Player 14: Weekend warrior
      Player(
        id: _uuid.v4(),
        name: 'Jamie "Thunder" Sullivan',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 50)),
        gamesPlayed: 16,
        gamesWon: 5,
        gameHistory: _generateGameHistory(
          gamesWon: 5,
          lastPlayedDaysAgo: 6,
        ),
      ),

      // Player 15: Rising talent
      Player(
        id: _uuid.v4(),
        name: 'Reese "Lightning" Chang',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 40)),
        gamesPlayed: 14,
        gamesWon: 8,
        gameHistory: _generateGameHistory(
          gamesWon: 8,
          lastPlayedDaysAgo: 3,
        ),
      ),

      // Player 16: Calm competitor
      Player(
        id: _uuid.v4(),
        name: 'Dakota "Zen Master" Lee',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 110)),
        gamesPlayed: 45,
        gamesWon: 22,
        gameHistory: _generateGameHistory(
          gamesWon: 22,
          lastPlayedDaysAgo: 2,
        ),
      ),

      // Player 17: Aggressive player
      Player(
        id: _uuid.v4(),
        name: 'Phoenix "Blitz" Carter',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 65)),
        gamesPlayed: 22,
        gamesWon: 9,
        gameHistory: _generateGameHistory(
          gamesWon: 9,
          lastPlayedDaysAgo: 4,
        ),
      ),

      // Player 18: Technical player
      Player(
        id: _uuid.v4(),
        name: 'Blake "Calculator" Singh',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 80)),
        gamesPlayed: 31,
        gamesWon: 16,
        gameHistory: _generateGameHistory(
          gamesWon: 16,
          lastPlayedDaysAgo: 1,
        ),
      ),

      // Player 19: Comeback specialist
      Player(
        id: _uuid.v4(),
        name: 'Skyler "Phoenix" Nguyen',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 55)),
        gamesPlayed: 18,
        gamesWon: 7,
        gameHistory: _generateGameHistory(
          gamesWon: 7,
          lastPlayedDaysAgo: 3,
        ),
      ),

      // Player 20: Reliable performer
      Player(
        id: _uuid.v4(),
        name: 'Rowan "Steady Hand" Garcia',
        photoPath: null,
        createdAt: now.subtract(const Duration(days: 105)),
        gamesPlayed: 43,
        gamesWon: 21,
        gameHistory: _generateGameHistory(
          gamesWon: 21,
          lastPlayedDaysAgo: 1,
        ),
      ),
    ];
  }

  /// Generate game history for a player (only wins are tracked)
  static List<GameHistoryEntry> _generateGameHistory({
    required int gamesWon,
    required int lastPlayedDaysAgo,
  }) {
    final history = <GameHistoryEntry>[];
    final now = DateTime.now();
    final games = ['Carnival Derby', 'Target Tag'];

    for (int i = 0; i < gamesWon; i++) {
      final daysAgo = lastPlayedDaysAgo + (i * 0.5).round();
      final timestamp = now.subtract(Duration(days: daysAgo));

      // Vary game durations
      final baseDuration = games[i % games.length] == 'Carnival Derby'
          ? const Duration(minutes: 8, seconds: 30)
          : const Duration(minutes: 12, seconds: 15);

      final variance = Duration(
        minutes: (i % 5) - 2,
        seconds: (i % 60) - 30,
      );

      history.add(GameHistoryEntry(
        id: _uuid.v4(),
        gameName: games[i % games.length],
        timestamp: timestamp,
        duration: baseDuration + variance,
      ));
    }

    return history.reversed.toList(); // Most recent first
  }

  /// Get test victory music file paths for loading
  static List<Map<String, String>> getTestVictoryMusicPaths() {
    return [
      {
        'name': 'Epic Victory Theme',
        'path': r'C:\Users\shuels\Downloads\TestData-VictoryMusic-01.mp3',
      },
      {
        'name': 'Celebration Fanfare',
        'path': r'C:\Users\shuels\Downloads\TestData-VictoryMusic-02.mp3',
      },
    ];
  }

  /// Get embedded test audio data URLs (actual user-created MP3 files)
  static List<Map<String, String>> getTestVictoryMusicDataUrls() {
    // These are the actual test MP3 files embedded as base64 data URLs
    return [
      {
        'name': 'Epic Victory Theme',
        'dataUrl': EmbeddedTestAudio.getMusicDataUrl1(),
      },
      {
        'name': 'Celebration Fanfare',
        'dataUrl': EmbeddedTestAudio.getMusicDataUrl2(),
      },
    ];
  }

  /// Clear all test data warning message
  static String getClearDataWarning() {
    return 'This will delete ALL players and their game history. '
           'This action cannot be undone. Are you sure?';
  }

  /// Clear all data warning message (includes music)
  static String getClearAllDataWarning() {
    return 'This will delete ALL players, their game history, AND all victory music files. '
           'This action cannot be undone. Are you sure?';
  }
}
