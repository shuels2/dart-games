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

  /// True when this save was created (or overwritten) by the
  /// auto-save-on-pause mechanism rather than by an explicit user
  /// save action. Used by the resume modal to prefix the date line
  /// with "AUTOSAVE — " so the user can distinguish.
  ///
  /// Per product rule: when an auto-save overwrites a row that was
  /// originally a user save (via the resumed `existingId` path),
  /// this flag flips to true. The latest-touch wins for labelling.
  final bool isAutoSave;

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
    this.isAutoSave = false,
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
    bool isAutoSave = false,
    String? existingId,
  }) {
    return SavedGameMetadata(
      id: existingId ?? const Uuid().v4(),
      gameType: gameType,
      savedAt: DateTime.now(),
      playerNames: playerNames,
      progressInfo: progressInfo,
      gameModeName: gameModeName,
      leadingPlayerName: leadingPlayerName,
      leadingPlayerScore: leadingPlayerScore,
      gameState: gameState,
      waitingForTakeout: waitingForTakeout,
      isAutoSave: isAutoSave,
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
      'isAutoSave': isAutoSave,
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
      isAutoSave: json['isAutoSave'] ?? false,
    );
  }
}
