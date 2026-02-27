class DartboardConnectionProfile {
  final String name;
  final String serialNumber;
  final String apiKey;
  final DateTime lastUsed;

  DartboardConnectionProfile({
    required this.name,
    required this.serialNumber,
    required this.apiKey,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'serialNumber': serialNumber,
      'apiKey': apiKey,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory DartboardConnectionProfile.fromJson(Map<String, dynamic> json) {
    return DartboardConnectionProfile(
      name: json['name'] as String,
      serialNumber: json['serialNumber'] as String,
      apiKey: json['apiKey'] as String,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }
}
