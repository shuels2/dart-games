class VictoryMusicFile {
  final String id;
  final String name;
  final String source;
  final DateTime addedDate;

  VictoryMusicFile({
    required this.id,
    required this.name,
    required this.source,
    required this.addedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source': source,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory VictoryMusicFile.fromJson(Map<String, dynamic> json) {
    return VictoryMusicFile(
      id: json['id'] as String,
      name: json['name'] as String,
      source: json['source'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
    );
  }
}
