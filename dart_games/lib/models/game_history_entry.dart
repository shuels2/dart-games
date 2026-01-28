import 'package:uuid/uuid.dart';

/// Represents a single game win entry in a player's history.
/// Tracks the game name, timestamp, and duration of the win.
class GameHistoryEntry {
  final String id;
  final String gameName;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, dynamic>? metadata;

  GameHistoryEntry({
    required this.id,
    required this.gameName,
    required this.timestamp,
    required this.duration,
    this.metadata,
  });

  /// Factory constructor to create a new game history entry.
  factory GameHistoryEntry.create({
    required String gameName,
    required Duration duration,
    Map<String, dynamic>? metadata,
  }) {
    return GameHistoryEntry(
      id: const Uuid().v4(),
      gameName: gameName,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: metadata,
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
    );
  }
}
