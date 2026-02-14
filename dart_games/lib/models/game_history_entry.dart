import 'package:uuid/uuid.dart';

/// Represents a single game win entry in a player's history.
/// Tracks the game name, timestamp, duration, and gameplay statistics.
class GameHistoryEntry {
  final String id;
  final String gameName;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, dynamic>? metadata;
  final int? dartThrows;     // Number of darts thrown by this player
  final int? turns;           // Number of turns taken by this player
  final int? playerCount;     // Total number of players in the game

  GameHistoryEntry({
    required this.id,
    required this.gameName,
    required this.timestamp,
    required this.duration,
    this.metadata,
    this.dartThrows,
    this.turns,
    this.playerCount,
  });

  /// Factory constructor to create a new game history entry.
  factory GameHistoryEntry.create({
    required String gameName,
    required Duration duration,
    Map<String, dynamic>? metadata,
    int? dartThrows,
    int? turns,
    int? playerCount,
  }) {
    return GameHistoryEntry(
      id: const Uuid().v4(),
      gameName: gameName,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: metadata,
      dartThrows: dartThrows,
      turns: turns,
      playerCount: playerCount,
    );
  }

  /// Convert to JSON for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameName': gameName,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'metadata': metadata,
      'dartThrows': dartThrows,
      'turns': turns,
      'playerCount': playerCount,
    };
  }

  /// Create from JSON storage.
  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) {
    return GameHistoryEntry(
      id: json['id'] as String,
      gameName: json['gameName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int),
      metadata: json['metadata'] as Map<String, dynamic>?,
      dartThrows: json['dartThrows'] as int?,
      turns: json['turns'] as int?,
      playerCount: json['playerCount'] as int?,
    );
  }
}
