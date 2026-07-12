import 'dart:convert';

import 'game_history_model.dart';

class ServerPlayer {
  final String id;
  final String name;
  final String? photoPath;
  final String createdAt;
  final int gamesPlayed;
  final int gamesWon;
  final List<ServerGameHistoryEntry> gameHistory;

  /// Normalized face landmark coordinates detected by the MediaPipe sidecar.
  ///
  /// Null when no custom avatar has been uploaded, face detection failed,
  /// or the migration CLI has not yet been run for this player.
  ///
  /// Shape (all coords 0..1 relative to image dimensions):
  /// ```json
  /// {
  ///   "boundingBox": {"x": 0.18, "y": 0.12, "width": 0.64, "height": 0.72},
  ///   "leftEye":     {"x": 0.34, "y": 0.40},
  ///   "rightEye":    {"x": 0.66, "y": 0.40},
  ///   "noseTip":     {"x": 0.50, "y": 0.55},
  ///   "mouthCenter": {"x": 0.50, "y": 0.72},
  ///   "confidence":  0.97
  /// }
  /// ```
  final Map<String, dynamic>? faceLandmarks;

  ServerPlayer({
    required this.id,
    required this.name,
    this.photoPath,
    required this.createdAt,
    required this.gamesPlayed,
    required this.gamesWon,
    this.gameHistory = const [],
    this.faceLandmarks,
  });

  factory ServerPlayer.fromDbRow(Map<String, dynamic> row) {
    final faceLandmarksRaw = row['face_landmarks'] as String?;
    return ServerPlayer(
      id: row['id'] as String,
      name: row['name'] as String,
      photoPath: row['photo_path'] as String?,
      createdAt: row['created_at'] as String,
      gamesPlayed: row['games_played'] as int,
      gamesWon: row['games_won'] as int,
      faceLandmarks: faceLandmarksRaw != null
          ? (jsonDecode(faceLandmarksRaw) as Map<String, dynamic>)
          : null,
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
      faceLandmarks: json['faceLandmarks'] as Map<String, dynamic>?,
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
      'faceLandmarks': faceLandmarks,
    };
  }
}
