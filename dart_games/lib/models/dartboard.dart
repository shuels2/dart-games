class Dartboard {
  final String serialNumber;
  final String name;
  final bool isHomeSbc;

  Dartboard({
    required this.serialNumber,
    required this.name,
    this.isHomeSbc = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'name': name,
      'isHomeSbc': isHomeSbc,
    };
  }

  factory Dartboard.fromJson(Map<String, dynamic> json) {
    return Dartboard(
      serialNumber: json['serialNumber'] as String,
      name: json['name'] as String,
      isHomeSbc: json['isHomeSbc'] as bool? ?? false,
    );
  }

  Dartboard copyWith({
    String? serialNumber,
    String? name,
    bool? isHomeSbc,
  }) {
    return Dartboard(
      serialNumber: serialNumber ?? this.serialNumber,
      name: name ?? this.name,
      isHomeSbc: isHomeSbc ?? this.isHomeSbc,
    );
  }
}
