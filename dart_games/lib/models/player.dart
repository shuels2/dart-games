import 'package:uuid/uuid.dart';

class Player {
  final String id;
  final String name;
  final String? photoPath;
  final DateTime createdAt;
  int gamesPlayed;
  int gamesWon;

  Player({
    required this.id,
    required this.name,
    this.photoPath,
    required this.createdAt,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
  });

  // Factory constructor to create a new player with generated ID
  factory Player.create({
    required String name,
    String? photoPath,
  }) {
    return Player(
      id: const Uuid().v4(),
      name: name,
      photoPath: photoPath,
      createdAt: DateTime.now(),
      gamesPlayed: 0,
      gamesWon: 0,
    );
  }

  // Convert Player to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
    };
  }

  // Create Player from JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      photoPath: json['photoPath'],
      createdAt: DateTime.parse(json['createdAt']),
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
    );
  }

  // Create a copy of this player with updated fields
  Player copyWith({
    String? id,
    String? name,
    String? photoPath,
    DateTime? createdAt,
    int? gamesPlayed,
    int? gamesWon,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
