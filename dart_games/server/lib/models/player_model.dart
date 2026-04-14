import 'game_history_model.dart';

class ServerPlayer {
  final String id;
  final String name;
  final String? photoPath;
  final String createdAt;
  final int gamesPlayed;
  final int gamesWon;
  final List<ServerGameHistoryEntry> gameHistory;

  ServerPlayer({
    required this.id,
    required this.name,
    this.photoPath,
    required this.createdAt,
    required this.gamesPlayed,
    required this.gamesWon,
    this.gameHistory = const [],
  });

  factory ServerPlayer.fromDbRow(Map<String, dynamic> row) {
    return ServerPlayer(
      id: row['id'] as String,
      name: row['name'] as String,
      photoPath: row['photo_path'] as String?,
      createdAt: row['created_at'] as String,
      gamesPlayed: row['games_played'] as int,
      gamesWon: row['games_won'] as int,
    );
  }

  factory ServerPlayer.fromJson(Map<String, dynamic> json) {
    return ServerPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      photoPath: json['photoPath'] as String?,
      createdAt: json['createdAt'] as String,
      gamesPlayed: json['gamesPlayed'] as int,
      gamesWon: json['gamesWon'] as int,
      gameHistory: (json['gameHistory'] as List<dynamic>?)
              ?.map((e) =>
                  ServerGameHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoPath': photoPath,
      'createdAt': createdAt,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'gameHistory': gameHistory.map((e) => e.toJson()).toList(),
    };
  }
}
