import 'package:uuid/uuid.dart';

class SavedGameMetadata {
  final String id;
  final String gameType;
  final DateTime savedAt;
  final List<String> playerNames;
  final String progressInfo;
  final String gameModeName;
  final String leadingPlayerName;
  final String leadingPlayerScore;
  final Map<String, dynamic> gameState;
  final bool waitingForTakeout;

  SavedGameMetadata({
    required this.id,
    required this.gameType,
    required this.savedAt,
    required this.playerNames,
    required this.progressInfo,
    required this.gameModeName,
    required this.leadingPlayerName,
    required this.leadingPlayerScore,
    required this.gameState,
    this.waitingForTakeout = false,
  });

  factory SavedGameMetadata.create({
    required String gameType,
    required List<String> playerNames,
    required String progressInfo,
    required String gameModeName,
    required String leadingPlayerName,
    required String leadingPlayerScore,
    required Map<String, dynamic> gameState,
    bool waitingForTakeout = false,
  }) {
    return SavedGameMetadata(
      id: const Uuid().v4(),
      gameType: gameType,
      savedAt: DateTime.now(),
      playerNames: playerNames,
      progressInfo: progressInfo,
      gameModeName: gameModeName,
      leadingPlayerName: leadingPlayerName,
      leadingPlayerScore: leadingPlayerScore,
      gameState: gameState,
      waitingForTakeout: waitingForTakeout,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType,
      'savedAt': savedAt.toIso8601String(),
      'playerNames': playerNames,
      'progressInfo': progressInfo,
      'gameModeName': gameModeName,
      'leadingPlayerName': leadingPlayerName,
      'leadingPlayerScore': leadingPlayerScore,
      'gameState': gameState,
      'waitingForTakeout': waitingForTakeout,
    };
  }

  factory SavedGameMetadata.fromJson(Map<String, dynamic> json) {
    return SavedGameMetadata(
      id: json['id'],
      gameType: json['gameType'],
      savedAt: DateTime.parse(json['savedAt']),
      playerNames: List<String>.from(json['playerNames']),
      progressInfo: json['progressInfo'],
      gameModeName: json['gameModeName'],
      leadingPlayerName: json['leadingPlayerName'],
      leadingPlayerScore: json['leadingPlayerScore'],
      gameState: Map<String, dynamic>.from(json['gameState']),
      waitingForTakeout: json['waitingForTakeout'] ?? false,
    );
  }
}
