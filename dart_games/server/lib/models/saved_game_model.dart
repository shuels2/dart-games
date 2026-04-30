import 'dart:convert';

class ServerSavedGame {
  final String id;
  final String gameType;
  final String savedAt;
  final List<String> playerNames;
  final String progressInfo;
  final String gameModeName;
  final String leadingPlayerName;
  final String leadingPlayerScore;
  final Map<String, dynamic> gameState;
  final bool waitingForTakeout;

  ServerSavedGame({
    required this.id,
    required this.gameType,
    required this.savedAt,
    required this.playerNames,
    required this.progressInfo,
    required this.gameModeName,
    required this.leadingPlayerName,
    required this.leadingPlayerScore,
    required this.gameState,
    required this.waitingForTakeout,
  });

  factory ServerSavedGame.fromDbRow(Map<String, dynamic> row) {
    final playerNamesRaw = row['player_names'] as String;
    final playerNames =
        (jsonDecode(playerNamesRaw) as List<dynamic>).cast<String>();

    final gameStateRaw = row['game_state'] as String;
    final gameState = jsonDecode(gameStateRaw) as Map<String, dynamic>;

    return ServerSavedGame(
      id: row['id'] as String,
      gameType: row['game_type'] as String,
      savedAt: row['saved_at'] as String,
      playerNames: playerNames,
      progressInfo: row['progress_info'] as String,
      gameModeName: row['game_mode_name'] as String,
      leadingPlayerName: row['leading_player_name'] as String,
      leadingPlayerScore: row['leading_player_score'] as String,
      gameState: gameState,
      waitingForTakeout: (row['waiting_for_takeout'] as int) == 1,
    );
  }

  factory ServerSavedGame.fromJson(Map<String, dynamic> json) {
    return ServerSavedGame(
      id: json['id'] as String,
      gameType: json['gameType'] as String,
      savedAt: json['savedAt'] as String,
      playerNames: (json['playerNames'] as List<dynamic>).cast<String>(),
      progressInfo: json['progressInfo'] as String,
      gameModeName: json['gameModeName'] as String,
      leadingPlayerName: json['leadingPlayerName'] as String,
      leadingPlayerScore: json['leadingPlayerScore'] as String,
      gameState: json['gameState'] as Map<String, dynamic>,
      waitingForTakeout: json['waitingForTakeout'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType,
      'savedAt': savedAt,
      'playerNames': playerNames,
      'progressInfo': progressInfo,
      'gameModeName': gameModeName,
      'leadingPlayerName': leadingPlayerName,
      'leadingPlayerScore': leadingPlayerScore,
      'gameState': gameState,
      'waitingForTakeout': waitingForTakeout,
    };
  }
}
