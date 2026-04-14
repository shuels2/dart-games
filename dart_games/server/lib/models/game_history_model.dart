import 'dart:convert';

class ServerGameHistoryEntry {
  final String id;
  final String playerId;
  final String gameName;
  final String timestamp;
  final int durationMs;
  final Map<String, dynamic>? metadata;
  final int? dartThrows;
  final int? turns;
  final int? playerCount;

  ServerGameHistoryEntry({
    required this.id,
    required this.playerId,
    required this.gameName,
    required this.timestamp,
    required this.durationMs,
    this.metadata,
    this.dartThrows,
    this.turns,
    this.playerCount,
  });

  factory ServerGameHistoryEntry.fromDbRow(Map<String, dynamic> row) {
    final metadataRaw = row['metadata'];
    Map<String, dynamic>? parsedMetadata;
    if (metadataRaw is String && metadataRaw.isNotEmpty) {
      parsedMetadata = jsonDecode(metadataRaw) as Map<String, dynamic>;
    }

    return ServerGameHistoryEntry(
      id: row['id'] as String,
      playerId: row['player_id'] as String,
      gameName: row['game_name'] as String,
      timestamp: row['timestamp'] as String,
      durationMs: row['duration_ms'] as int,
      metadata: parsedMetadata,
      dartThrows: row['dart_throws'] as int?,
      turns: row['turns'] as int?,
      playerCount: row['player_count'] as int?,
    );
  }

  factory ServerGameHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ServerGameHistoryEntry(
      id: json['id'] as String,
      playerId: json['playerId'] as String,
      gameName: json['gameName'] as String,
      timestamp: json['timestamp'] as String,
      durationMs: json['durationMs'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
      dartThrows: json['dartThrows'] as int?,
      turns: json['turns'] as int?,
      playerCount: json['playerCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'gameName': gameName,
      'timestamp': timestamp,
      'durationMs': durationMs,
      'metadata': metadata,
      'dartThrows': dartThrows,
      'turns': turns,
      'playerCount': playerCount,
    };
  }
}
