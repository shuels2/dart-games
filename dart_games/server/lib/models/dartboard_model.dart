class ServerDartboard {
  final String? name;
  final String? serialNumber;
  final String? apiKey;
  final bool useEmulator;

  ServerDartboard({
    this.name,
    this.serialNumber,
    this.apiKey,
    required this.useEmulator,
  });

  factory ServerDartboard.fromDbRow(Map<String, dynamic> row) {
    return ServerDartboard(
      name: row['name'] as String?,
      serialNumber: row['serial_number'] as String?,
      apiKey: row['api_key'] as String?,
      useEmulator: (row['use_emulator'] as int) == 1,
    );
  }

  factory ServerDartboard.fromJson(Map<String, dynamic> json) {
    return ServerDartboard(
      name: json['name'] as String?,
      serialNumber: json['serialNumber'] as String?,
      apiKey: json['apiKey'] as String?,
      useEmulator: json['useEmulator'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'serialNumber': serialNumber,
      'apiKey': apiKey,
      'useEmulator': useEmulator,
    };
  }
}

class ServerDartboardProfile {
  final String serialNumber;
  final String name;
  final String apiKey;
  final String lastUsed;

  ServerDartboardProfile({
    required this.serialNumber,
    required this.name,
    required this.apiKey,
    required this.lastUsed,
  });

  factory ServerDartboardProfile.fromDbRow(Map<String, dynamic> row) {
    return ServerDartboardProfile(
      serialNumber: row['serial_number'] as String,
      name: row['name'] as String,
      apiKey: row['api_key'] as String,
      lastUsed: row['last_used'] as String,
    );
  }

  factory ServerDartboardProfile.fromJson(Map<String, dynamic> json) {
    return ServerDartboardProfile(
      serialNumber: json['serialNumber'] as String,
      name: json['name'] as String,
      apiKey: json['apiKey'] as String,
      lastUsed: json['lastUsed'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'name': name,
      'apiKey': apiKey,
      'lastUsed': lastUsed,
    };
  }
}
