class ServerVictoryMusic {
  final String id;
  final String fileName;
  final String filePath;
  final bool isCurrent;
  final String createdAt;

  ServerVictoryMusic({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.isCurrent,
    required this.createdAt,
  });

  factory ServerVictoryMusic.fromDbRow(Map<String, dynamic> row) {
    return ServerVictoryMusic(
      id: row['id'] as String,
      fileName: row['file_name'] as String,
      filePath: row['file_path'] as String,
      isCurrent: (row['is_current'] as int) == 1,
      createdAt: row['created_at'] as String,
    );
  }

  factory ServerVictoryMusic.fromJson(Map<String, dynamic> json) {
    return ServerVictoryMusic(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      isCurrent: json['isCurrent'] as bool,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'isCurrent': isCurrent,
      'createdAt': createdAt,
    };
  }
}
